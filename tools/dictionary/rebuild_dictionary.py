#!/usr/bin/env python3
"""Sapiora/Lexiora dictionary JSON pipeline.

Regenerates the curated dictionary packs under `assets/dictionary/` from raw,
licensed sources. This is the "own JSON pipeline" that keeps every word's
meaning correct and complete without months of manual typing:

  WordNet 3.1 (Princeton)          -> English definitions, part of speech,
                                      synonyms, antonyms, example sentences.
                                      Senses are ordered by SemCor frequency
                                      (the `cntlist` file), so the COMMON
                                      meaning of each word wins over rare or
                                      technical senses.
  kaikki.org Urdu Wiktionary dump  -> Urdu meanings, picked common-sense-first
                                      (the first/primary English gloss of each
                                      Urdu sense), fixing the old rare-sense
                                      mis-pairings (e.g. abacus -> جنت).
  kaikki.org English Wiktionary dump (2nd Urdu source)
                                   -> the reverse direction: each ENGLISH
                                      headword's curated Urdu translations
                                      (the `translations` section, lang=Urdu).
                                      Adds common words Wiktionary translates
                                      into Urdu that the Urdu dump glosses
                                      missed (academy, airplane, birthday,
                                      bread, buy, ...). Pre-filtered to lines
                                      containing "lang": "Urdu" (see README).
  wordset.jsonl.gz (Wordset, CC BY-SA)
                                   -> fallback definitions and example
                                      sentences for words WordNet lacks.
  Existing curated packs           -> preserved and layered on top (hand-tuned
                                      Urdu, exam data). The `zz_` corrections
                                      pack still wins the final merge.

Outputs (regenerated in place):
  assets/dictionary/000_wordnet_enrichment.json  -- full entry (definition +
      synonyms + antonyms + example) for every word the curated packs don't
      cover. Replaces the old skeleton pack that had no definitions at all.
  assets/dictionary/urdu_wiktionary_pack.json   -- every English headword with
      a usable Urdu meaning: common-sense Urdu first, full English body.

Because the app seeder merges every pack by lowercase headword (later
alphabetical path wins), `urdu_wiktionary_pack.json` (u) overrides the
enrichment pack (0) for its words, and `zz_curated_corrections.json` (z)
overrides both for the hand-fixed words. Drop the pack in, rebuild, and the
app re-seeds automatically (seed version is a content signature).

Inputs expected on disk (see tools/dictionary/README.md for download links):
  WN_DICT    (default /tmp/wn/dict)   -- WordNet 3.1 `dict/` directory
  KAIKKI_UR  (default /tmp/urdu_wikt.jsonl) -- kaikki.org Urdu dump (JSONL)
  EN_WIKT_URD (default /tmp/eng_wikt_urd)
                                     -- directory of pre-filtered JSONL lines
                                        (entries that contain "lang": "Urdu")
                                        from the kaikki.org English by-pos
                                        dumps (noun/verb/adj/adv)
  OLD_URDU_PACK (default the committed snapshot at
                                        tools/dictionary/snapshots/urdu_wiktionary_pack.v21.8.json,
                                        the pre-pipeline pack users had already
                                        seen) -- a snapshot of the PREVIOUS
                                        urdu_wiktionary_pack.json. Its Urdu
                                        lists are used only as a fallback for
                                        words the new sources don't cover, so
                                        words users have already seen keep
                                        their meaning. Do NOT point this at the
                                        current working-tree output file:
                                        that would freeze stale entries (e.g.
                                        have -> گلا بیٹھنا) into every future
                                        build. See tools/dictionary/README.md.
  PROJECT    (default repo root)      -- where assets/ lives

Run from the repo root:
  python3 tools/dictionary/rebuild_dictionary.py
"""
from __future__ import annotations

import gzip
import json
import os
import re
import sys
import unicodedata
from collections import defaultdict

ROOT = os.environ.get('PROJECT', os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
WN_DICT = os.environ.get('WN_DICT', '/tmp/wn/dict')
KAIKKI_UR = os.environ.get('KAIKKI_UR', '/tmp/urdu_wikt.jsonl')
EN_WIKT_URD = os.environ.get('EN_WIKT_URD', '/tmp/eng_wikt_urd')
# Default: the committed pre-pipeline snapshot (see the docstring). Override
# with OLD_URDU_PACK to point at any other previous pack.
_SNAPSHOT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                         'snapshots', 'urdu_wiktionary_pack.v21.8.json')
OLD_URDU_PACK = os.environ.get('OLD_URDU_PACK') or _SNAPSHOT
ASSET_DIR = os.path.join(ROOT, 'assets', 'dictionary')

POS_LETTER = {'n': 'noun', 'v': 'verb', 'a': 'adjective', 'r': 'adverb'}
POS_NUM = {'n': 1, 'v': 2, 'a': 3, 'r': 4}

# ── tiny helpers ─────────────────────────────────────────────────────────────

def norm(w: str) -> str:
    """Lowercase + strip diacritics (matches lib/modules/... base_forms)."""
    return ''.join(
        c for c in unicodedata.normalize('NFD', w.lower())
        if unicodedata.category(c) != 'Mn'
    )

def has_alpha(w: str) -> bool:
    return any(c.isalpha() for c in w)

URDU_RE = re.compile(r'[\u0600-\u06FF]')

# Combining marks that carry vowel/sound diacritics (zabar/zer/pesh, shadda,
# superscript alef, ...). The Wiktionary translations write them out
# (لُغَت); the app's packs use plain Urdu script (لغت), so we strip them
# on intake so entries stay consistent and searchable.
URDU_DIACRITICS = dict.fromkeys(
    list(range(0x064B, 0x0660)) + [0x0670], None)

def plain_urdu(s: str) -> str:
    return s.translate(URDU_DIACRITICS).strip()

# Example sentences clearly unsuitable for a learner dictionary.
BAD_EXAMPLE = re.compile(
    r'\b(heroin|cocaine|cannabis|marijuana|morphine|opium|methamphetamine|'
    r'fuck|shit|bitch|whore|slut|rape|porn(ography)?|naked|semen|ejaculat|'
    r'masturbat|condom|suicide|murder|corpse|orgasm|prostitute|sex\b|'
    r'bomb\b)\b',
    re.IGNORECASE,
)

def good_example(candidates) -> str | None:
    for ex in candidates:
        if not ex or not isinstance(ex, str):
            continue
        ex = ex.strip()
        if len(ex.split()) < 3:
            continue
        if BAD_EXAMPLE.search(ex):
            continue
        if ex[0].islower():  # WordNet examples usually start lowercase; keep them
            ex = ex[0].upper() + ex[1:]
        return ex[:160]
    return None

# ── 1) WordNet 3.1: synsets + SemCor frequency ──────────────────────────────

def parse_wn() -> dict:
    """Return {norm(lemma): [synset records sorted by frequency desc]}.

    Each record: {'p': pos letter, 'g': definition (no examples),
                  'm': members, 'a': antonyms, 'e': example sentences,
                  'cnt': SemCor count}
    """
    data = {}  # (pos_letter, offset) -> record
    # cntlist: sense-key -> (count, rank). Keys are like "cat%1:05:00::"
    # (nouns/verbs/adverbs) or "bright%5:00:00:light:06" (satellite adjectives,
    # where the 4th field is a gloss disambiguator word and the 5th a marker).
    cnt = {}   # sense key -> (count, rank)

    # ── cntlist: per-lemma-sense SemCor counts ──
    try:
        with open(os.path.join(WN_DICT, 'cntlist'), encoding='utf-8') as f:
            for line in f:
                parts = line.split()
                if len(parts) < 2:
                    continue
                try:
                    count = int(parts[0])
                except ValueError:
                    continue
                rank = 0
                if len(parts) > 2:
                    try:
                        rank = int(parts[2])
                    except ValueError:
                        rank = 0
                cnt[parts[1]] = (count, rank)
    except FileNotFoundError:
        print('  !! cntlist not found; falling back to index order (no cross-POS frequency)')
        cnt = {}

    # ── data files ──
    for pos_letter, fn in (('n', 'data.noun'), ('v', 'data.verb'),
                           ('a', 'data.adj'), ('r', 'data.adv')):
        with open(os.path.join(WN_DICT, fn), encoding='utf-8') as f:
            for line in f:
                if line.startswith(' '):
                    continue
                parts = line.split('| ')
                head = parts[0].split()
                if len(head) < 5:
                    continue
                try:
                    offset = int(head[0])
                    lex_filenum = int(head[1])
                except ValueError:
                    continue
                w_cnt = int(head[3], 16)
                idx = 4
                lemmas = []  # (lemma_norm, lex_id)
                for _ in range(w_cnt):
                    if idx + 1 >= len(head):
                        break
                    lemmas.append((norm(head[idx]), int(head[idx + 1], 16)))
                    idx += 2
                # pointer count (decimal or hex)
                p_cnt = None
                for base in (10, 16):
                    try:
                        c = int(head[idx], base)
                    except ValueError:
                        continue
                    if idx + 1 + 4 * c <= len(head):
                        p_cnt = c
                        break
                if p_cnt is None:
                    continue
                idx += 1
                ptrs = [head[idx + 4 * i: idx + 4 * i + 4] for i in range(p_cnt)]
                gloss = parts[1].strip() if len(parts) > 1 else ''
                examples = re.findall(r'"([^"]+)"', gloss)
                definition = re.split(r'\s*;\s*"', gloss)[0].strip()
                antonyms = []
                for p in ptrs:
                    if p[0] == '!':
                        try:
                            t_off = int(p[1])
                            t_hex = int(p[3][-2:], 16)
                        except ValueError:
                            continue
                        antonyms.append((t_off, t_hex))
                rec = {
                    'p': pos_letter,
                    'offset': offset,
                    'lex_filenum': lex_filenum,
                    'lemmas': lemmas,
                    'g': definition,
                    'e': examples,
                    'ant': antonyms,
                }
                data[(pos_letter, offset)] = rec

    # resolve antonym targets -> member lemma names
    for (pos_letter, offset), rec in data.items():
        resolved = []
        for t_off, t_hex in rec['ant']:
            target = data.get((pos_letter, t_off))
            if not target:
                continue
            if 0 <= t_hex < len(target['lemmas']):
                resolved.append(target['lemmas'][t_hex][0])
            elif target['lemmas']:
                resolved.append(target['lemmas'][0][0])
        rec['a'] = resolved
        rec['m'] = [lm for lm, _ in rec['lemmas']]

    # ── per-lemma sense counts ──
    # The count for (lemma, synset) is that LEMMA's own SemCor count (its key),
    # not the last synset member's — WordNet lists members in decreasing
    # frequency, so a naive "last one wins" made common senses look rare
    # (e.g. cat -> "to vomit" instead of "feline mammal"). Satellite adjectives
    # (cntlist key "lemma%5:lf:lid:word:marker") are matched by checking that
    # the disambiguator word appears in the synset gloss.
    def sense_count(lemma_norm: str, pos_letter: str, lex_filenum: int,
                    lex_id: int, gloss_lower: str) -> tuple:
        key = f"{lemma_norm}%{POS_NUM[pos_letter]}:{lex_filenum:02d}:{lex_id:02d}::"
        hit = cnt.get(key)
        if hit is not None:
            return hit
        if pos_letter == 'a':
            best = (0, 0)
            prefix = f'{lemma_norm}%5:'
            for ckey, (c, r) in cnt.items():
                if not ckey.startswith(prefix):
                    continue
                fields = ckey.split(':')
                if len(fields) >= 5 and fields[3] and fields[3] in gloss_lower:
                    if (c, -r) > (best[0], -best[1]):
                        best = (c, r)
            return best
        return (0, 0)

    by_lemma = defaultdict(list)
    for (pos_letter, offset), rec in data.items():
        gloss_lower = rec['g'].lower()
        for lemma_norm, lex_id in rec['lemmas']:
            c, r = sense_count(lemma_norm, pos_letter, rec['lex_filenum'],
                               lex_id, gloss_lower)
            by_lemma[lemma_norm].append((rec, c, r))

    out = {}
    for lemma_norm, recs in by_lemma.items():
        # de-dupe identical synsets, sort by frequency desc (rank asc as a
        # tie-break), then offset asc
        seen = set()
        uniq = []
        for r, c, rank in recs:
            k = (r['p'], r['offset'])
            if k in seen:
                continue
            seen.add(k)
            uniq.append((r, c, rank))
        uniq.sort(key=lambda t: (-t[1], t[2], t[0]['offset']))
        out[lemma_norm] = [{
            'p': r['p'],
            'g': r['g'],
            'm': r['m'],
            'a': r['a'],
            'e': r['e'],
            'cnt': c,
        } for r, c, _ in uniq]
    return out

# ── 2) wordset base (fallback definitions/examples) ─────────────────────────

def load_wordset() -> tuple[dict, dict]:
    """(word_lower -> [meanings], word_lower -> best example)"""
    meanings = defaultdict(list)
    examples = {}
    with gzip.open(os.path.join(ASSET_DIR, 'wordset.jsonl.gz'), 'rt', encoding='utf-8') as f:
        for line in f:
            e = json.loads(line)
            w = e['w'].lower()
            m = (e.get('m') or '').strip()
            p = (e.get('p') or '').strip()
            if m:
                meanings[w].append((p, m))
            ex = (e.get('e') or '').strip()
            if ex and len(ex) > len(examples.get(w, '')):
                examples[w] = ex
    return dict(meanings), examples

# ── 3a) kaikki English dump: English headword -> Urdu translations ──────────

def load_eng_wikt_urdu() -> dict:
    """Second Urdu source: English Wiktionary `translations` (lang=Urdu).

    Reads pre-filtered JSONL lines (any entry that contains a Urdu
    translation) from every *_urd.jsonl in EN_WIKT_URD and returns
    {english_lower: [plain-urdu words, first-seen order]}.
    """
    out = defaultdict(list)
    if not os.path.isdir(EN_WIKT_URD):
        print(f'  !! EN_WIKT_URD {EN_WIKT_URD!r} missing — second Urdu source skipped')
        return dict(out)
    n = 0
    for fn in sorted(os.listdir(EN_WIKT_URD)):
        if not fn.endswith('.jsonl'):
            continue
        with open(os.path.join(EN_WIKT_URD, fn), encoding='utf-8') as f:
            for line in f:
                try:
                    o = json.loads(line)
                except json.JSONDecodeError:
                    continue
                w = (o.get('word') or '').strip().lower()
                if not w or len(w.split()) > 2:
                    continue
                # Drop vulgar/sensitive English headwords entirely (e.g. arse,
                # condom, crap, fuck, slut, vagina) — the kaikki path filters
                # these per-sense; the English-dump path must too, or pairs
                # like `crap -> فارغ` and `sex -> میتھن` leak into the pack.
                if VULGAR_RE.search(w):
                    continue
                seen = set(out.get(w, ()))
                for t in o.get('translations') or []:
                    if not isinstance(t, dict):
                        continue
                    if (t.get('lang') or '') != 'Urdu' and (t.get('code') or '') != 'urd':
                        continue
                    uw = plain_urdu((t.get('word') or '').strip())
                    if not uw or len(uw.split()) > 4:
                        continue
                    if not URDU_RE.search(uw) or re.search(r'[A-Za-z]', uw):
                        continue  # not Urdu script, or Latin leakage
                    if bad_urdu_word(uw):
                        continue
                    if uw not in seen:
                        seen.add(uw)
                        out[w].append(uw)
                        n += 1
    print(f'  eng-wikt urdu: {len(out)} headwords, {n} Urdu translations')
    return dict(out)

# ── 3b) kaikki Urdu dump: English -> common-first Urdu ──────────────────────

# Sense glosses/links that indicate content unsuitable for a learner
# dictionary (vulgar/offensive). The whole sense is dropped so the Urdu word
# never reaches the pack through that sense.
VULGAR_RE = re.compile(
    r'\b(asshole|butthole|anus|anal\b|fart|shit|piss|fuck|dick|cock|pussy|'
    r'cunt|bastard|bitch|whore|slut|porn(ography)?|masturbat\w*|semen|'
    r'ejaculat\w*|orgasm|prostitute|condom|nipple|penis|vagina|testicle|'
    r'scrotum|turd|crap|wank|handjob|blowjob|sodom|incest|bestial|naked|'
    r'rape|sex\b|arse|ass\b|copulat\w*|coitus|intercourse)\b',
    re.IGNORECASE,
)

# Urdu vulgar words (token-exact — substring matches would wrongly kill
# innocent words like چودہ "fourteen" or پادری "clergyman").
VULGAR_URDU = frozenset(
    ('گانڈ', 'پاد', 'ٹٹی', 'چوتیا', 'چوتی', 'بھوسڑ', 'گانڈو', 'چوت',
     'چود', 'چودنا', 'چودنے', 'لنڈ', 'پھوڑ', 'پھدی'))

def bad_urdu_word(u: str) -> bool:
    """True when a candidate Urdu meaning should never be shipped."""
    if re.search(r'\d', u):
        return True
    if any(t in VULGAR_URDU for t in u.split()):
        return True
    return False

# Wiktionary topic/category tags that leak into the `links` of a sense
# (e.g. {{topic|automotive}}) and must never be treated as translations.
TOPIC_TAGS = {
    'automotive', 'anatomy', 'astronomy', 'aviation', 'biology', 'botany',
    'chemistry', 'computing', 'economics', 'education', 'engineering',
    'geography', 'geology', 'grammar', 'history', 'horticulture', 'law',
    'linguistics', 'literature', 'logic', 'mathematics', 'medicine',
    'military', 'music', 'mythology', 'philosophy', 'phonetics', 'physics',
    'politics', 'psychology', 'religion', 'semantics', 'sociology',
    'sports', 'technology', 'transport', 'zoology', 'chemistry', 'physics',
}

def load_kaikki_urdu() -> dict:
    """Return {english_lower: [urdu words, primary-first]}.

    English is extracted from the sense **glosses** (the real meaning), not the
    `links` — the first link of a sense is often a {{topic|...}} tag (e.g.
    "automotive" for windscreen, "semantics" for antonym), which is what
    produced wrong pairs like `automotive → شیشہ` in the old pack. Links are
    used only when the gloss is not English. Senses whose gloss/links contain
    vulgar content are dropped entirely.
    """
    eng2urdu = defaultdict(list)  # english -> (is_primary, sense_rank, urdu)
    with open(KAIKKI_UR, encoding='utf-8') as f:
        for line in f:
            try:
                o = json.loads(line)
            except json.JSONDecodeError:
                continue
            w = (o.get('word') or '').strip()
            if not w or not URDU_RE.search(w):
                continue
            if bad_urdu_word(w):
                continue
            senses = o.get('senses') or []
            for rank, sn in enumerate(senses):
                if not isinstance(sn, dict):
                    continue
                glosses = sn.get('glosses') or sn.get('raw_glosses') or []
                links = sn.get('links') or []
                hay = ' '.join(str(g) for g in glosses) + ' ' + \
                    ' '.join(str(l[0]) for l in links if isinstance(l, list) and l)
                if VULGAR_RE.search(hay):
                    continue  # drop the whole sense
                # 1) English glosses first (split on ; , and parentheses)
                english = None
                for g in glosses:
                    gs = str(g).strip()
                    if not gs or URDU_RE.search(gs):
                        continue
                    for part in re.split(r'[;,(]', gs):
                        part = part.strip()
                        # strip the infinitive marker so "to accept" becomes
                        # "accept" ("to have a hoarse voice" stays multiword
                        # and is filtered out by the headword rules)
                        if part.lower().startswith('to '):
                            part = part[3:].strip()
                        if part and has_alpha(part) and not URDU_RE.search(part) \
                                and norm(part) not in TOPIC_TAGS:
                            english = part
                            break
                    if english:
                        break
                # 2) fall back to links only when no English gloss
                if english is None:
                    for link in links:
                        if not isinstance(link, list) or not link:
                            continue
                        ew = str(link[0]).strip()
                        ref = str(link[1]) if len(link) > 1 else ''
                        if has_alpha(ew) and norm(ew) not in TOPIC_TAGS \
                                and (ref.endswith('#English') or ref == ew):
                            english = ew
                            break
                if not english:
                    continue
                key = norm(english)
                if len(key) < 2 or any(ch.isdigit() for ch in key):
                    continue
                is_primary = rank == 0
                eng2urdu[key].append((is_primary, rank, w))
    out = {}
    for eng, cands in eng2urdu.items():
        # primary candidates first (sorted by sense rank), then others
        prim = sorted([c for c in cands if c[0]], key=lambda c: c[1])
        rest = sorted([c for c in cands if not c[0]], key=lambda c: c[1])
        seen = set()
        ordered = []
        for isp, rank, u in prim + rest:
            if u in seen:
                continue
            seen.add(u)
            ordered.append(u)
        out[eng] = ordered
    return out

# ── 4) entry building ────────────────────────────────────────────────────────

def build_body(lemma_norm: str, syn_by_lemma: dict, wordset_meanings: dict,
               wordset_examples: dict, display: str) -> dict | None:
    """A full DictionaryEntry body for a word from its most frequent synset."""
    recs = syn_by_lemma.get(lemma_norm)
    if not recs:
        # no WordNet data: fall back to wordset meaning + example
        ms = wordset_meanings.get(lemma_norm)
        if not ms:
            return None
        entry = {'word': display, 'partOfSpeech': ms[0][0] or None}
        entry['englishDefinition'] = ms[0][1]
        ex = good_example([wordset_examples.get(lemma_norm)])
        if ex:
            entry['usage'] = {'context': 'Usage', 'english': ex, 'urdu': ''}
        return entry if entry.get('englishDefinition') else None

    syn = recs[0]  # most frequent (common) sense
    entry = {'word': display, 'partOfSpeech': POS_LETTER.get(syn['p'], None)}
    entry['englishDefinition'] = syn['g'] or None
    # NO machine-generated synonyms/antonyms: WordNet synset members are too
    # noisy for a learner dictionary (avoid -> face up, complain -> quetch),
    # and v0.21.8 removed them all. Only the hand-curated packs
    # (exam_words.json, zz_*) carry synonyms now. Example sentences stay.
    ex = good_example(list(syn['e']) + [wordset_examples.get(lemma_norm)])
    if ex:
        entry['usage'] = {'context': 'Usage', 'english': ex, 'urdu': ''}
    if not entry.get('englishDefinition'):
        # wordnet gloss can be empty; fall back to wordset meaning
        ms = wordset_meanings.get(lemma_norm)
        if ms:
            entry['englishDefinition'] = ms[0][1]
    if not entry.get('englishDefinition') and not entry.get('usage'):
        return None
    return entry

# ── 5) main ──────────────────────────────────────────────────────────────────

def main() -> None:
    print('Parsing WordNet 3.1 from', WN_DICT)
    syn_by_lemma = parse_wn()
    print(f'  {len(syn_by_lemma)} lemmas')

    wordset_meanings, wordset_examples = load_wordset()
    print(f'  wordset: {len(wordset_meanings)} headwords')

    # existing curated packs (read-only here; regenerated below). The richer
    # hand-curated packs own their headwords outright; the PREVIOUS urdu pack
    # is consulted only through the OLD_URDU_PACK snapshot (see the docstring
    # for why the working-tree output must never be read back as input).
    rich_norms = set()  # headwords owned by the richer hand-curated packs
    for fn in ('common_words.json', 'common_words_2.json', 'exam_words.json',
               'exam_extras.json', 'zz_curated_corrections.json'):
        path = os.path.join(ASSET_DIR, fn)
        if not os.path.exists(path):
            continue
        for e in json.load(open(path, encoding='utf-8')):
            rich_norms.add(norm(e.get('word', '')))
    old_urdu = {}  # norm(word) -> previous urdu_wiktionary_pack entry (fallback)
    if OLD_URDU_PACK:
        if os.path.exists(OLD_URDU_PACK):
            for e in json.load(open(OLD_URDU_PACK, encoding='utf-8')):
                old_urdu[norm(e.get('word', ''))] = e
            print(f'  old-urdu fallback: {len(old_urdu)} snapshot entries')
        else:
            print(f'  !! OLD_URDU_PACK {OLD_URDU_PACK!r} not found; fallback disabled')

    # ── urdu_wiktionary_pack.json (built first so the enrichment pack below
    #    knows which headwords it covers) ──
    kaikki = load_kaikki_urdu()
    print(f'\nkaikki urdu: {len(kaikki)} English headwords with Urdu')
    eng_wikt = load_eng_wikt_urdu()

    def is_good_headword(eng: str) -> bool:
        """Drop suffix fragments and definitional phrase glosses (e.g. "-ed",
        "a code of laws") that are not real learner headwords."""
        if not eng or not has_alpha(eng) or len(eng) < 2:
            return False
        if eng.startswith('-') or eng.endswith('-'):
            return False
        if '(' in eng or ')' in eng:
            return False
        if any(ch.isdigit() for ch in eng):
            return False
        words = eng.split()
        if len(words) > 2:
            return False
        if len(words) == 2 and words[0] in ('a', 'an', 'the'):
            return False
        if words[0] in ('a', 'an', 'the') and len(words[0]) <= 3:
            return False
        return True

    all_eng = set(old_urdu) | set(kaikki.keys()) | set(eng_wikt.keys())
    all_eng = {e for e in all_eng if is_good_headword(e)}
    urdu_entries = []
    for eng in sorted(all_eng):
        if eng in rich_norms:
            continue  # richer hand-curated pack already owns this headword
        if VULGAR_RE.search(eng):
            continue  # never ship vulgar/sensitive headwords (any source)
        u_list = []
        seen = set()
        old_e = old_urdu.get(eng)
        # Gloss-first kaikki extraction wins: it drops the {{topic|...}} link
        # mis-pairs (automotive, semantics, ...) the old link-first pack
        # inherited. eng-wikt (curated per-English-word) is next, then the old
        # pack's Urdu as a fallback for words the new extraction filters out.
        for u in kaikki.get(eng, []):
            if bad_urdu_word(u):
                continue
            up = plain_urdu(u)
            if up not in seen:
                seen.add(up)
                u_list.append(u)
            if len(u_list) >= 4:
                break
        if len(u_list) < 4:
            for u in eng_wikt.get(eng, []):
                if bad_urdu_word(u):
                    continue
                up = plain_urdu(u)
                if up not in seen:
                    seen.add(up)
                    u_list.append(u)
                if len(u_list) >= 4:
                    break
        if len(u_list) < 4:
            for u in (old_e.get('urduMeanings') or []) if old_e else []:
                if bad_urdu_word(u):
                    continue
                up = plain_urdu(u)
                if up not in seen:
                    seen.add(up)
                    u_list.append(u)
                if len(u_list) >= 4:
                    break
        if not u_list:
            continue
        body = build_body(eng, syn_by_lemma, wordset_meanings,
                          wordset_examples, old_e.get('word', eng) if old_e else eng)
        if body is None:
            # No English body at all: keep only when the base dictionary
            # (wordset) can still supply the definition — otherwise the entry
            # would show as "no information" in the app.
            if eng not in wordset_meanings:
                continue
            body = {'word': old_e.get('word', eng) if old_e else eng}
        else:
            # preserve a curated kaikki English definition when WordNet
            # produced nothing usable for this word
            if not body.get('englishDefinition') and old_e and old_e.get('englishDefinition'):
                body['englishDefinition'] = old_e['englishDefinition']
            # keep the old kaikki usage sentence as a fallback when the
            # common-sense WordNet synset had no example
            if not body.get('usage') and old_e and old_e.get('usage'):
                body['usage'] = old_e['usage']
        body['urduMeanings'] = u_list
        if old_e and old_e.get('otherMeanings') and not body.get('otherMeanings'):
            body['otherMeanings'] = old_e['otherMeanings']
        urdu_entries.append(body)

    out_path2 = os.path.join(ASSET_DIR, 'urdu_wiktionary_pack.json')
    with open(out_path2, 'w', encoding='utf-8') as f:
        json.dump(urdu_entries, f, ensure_ascii=False, separators=(',', ':'))
        f.write('\n')
    print(f'[urdu_wiktionary_pack.json] {len(urdu_entries)} entries, '
          f'{os.path.getsize(out_path2) / 1e6:.1f} MB')
    urdu_out_norms = {norm(e.get('word', '')) for e in urdu_entries}

    # ── 000_wordnet_enrichment.json ──
    old = json.load(open(os.path.join(ASSET_DIR, '000_wordnet_enrichment.json'), encoding='utf-8'))
    old_display = {norm(e.get('word', '')): e['word'] for e in old}
    universe = set(old_display) | set(wordset_meanings.keys())
    # drop junk lemmas (no letters / too short / suffix fragments like "-ed")
    universe = {w for w in universe
                if has_alpha(w) and len(w) >= 2 and not w.startswith('-')}

    entries = {}
    excluded = rich_norms | urdu_out_norms
    for lemma_norm in sorted(universe):
        if lemma_norm in excluded:
            continue  # a curated pack already covers it
        display = old_display.get(lemma_norm, lemma_norm)
        body = build_body(lemma_norm, syn_by_lemma, wordset_meanings,
                          wordset_examples, display)
        if body:
            # keyed by display word (case-insensitive) like the app seeder
            entries[display.lower()] = body

    out_path = os.path.join(ASSET_DIR, '000_wordnet_enrichment.json')
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(list(entries.values()), f, ensure_ascii=False, separators=(',', ':'))
        f.write('\n')
    size_mb = os.path.getsize(out_path) / 1e6
    n_def = sum(1 for e in entries.values() if e.get('englishDefinition'))
    n_syn = sum(1 for e in entries.values() if e.get('synonyms'))
    n_ant = sum(1 for e in entries.values() if e.get('antonyms'))
    n_use = sum(1 for e in entries.values() if e.get('usage'))
    print(f'\n[000_wordnet_enrichment.json] {len(entries)} entries, {size_mb:.1f} MB')
    print(f'  def={n_def} ({100 * n_def / max(len(entries), 1):.0f}%) '
          f'syn={n_syn} ant={n_ant} usage={n_use}')

    # ── summary ──
    print('\nDone. Rebuilt both packs in place — the app re-seeds on next launch.')

if __name__ == '__main__':
    main()

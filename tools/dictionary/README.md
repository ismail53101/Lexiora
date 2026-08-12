# Dictionary JSON pipeline (Sapiora)

This directory contains the reproducible pipeline that generates the
dictionary data shipped in `assets/dictionary/`. It answers the question
"how do I keep every word's meaning correct without writing 100,000
definitions by hand?" — the data comes from licensed raw sources, and the
scripts pick the **common** sense of each word programmatically.

## What it generates

| Output | What changed vs. the old packs |
|---|---|
| `assets/dictionary/000_wordnet_enrichment.json` | Every word now has an **English definition** (the old pack only carried example sentences), plus **synonyms**, **antonyms** and a **usage example** where WordNet has them. |
| `assets/dictionary/urdu_wiktionary_pack.json` | Urdu coverage expanded from ~4,800 to 5,743 pack headwords (~7,700 in the merged dictionary), from **two** Wiktionary sources, with **common-sense-first** Urdu meanings (the old pack sometimes picked a rare sense, e.g. `abacus → جنت`). |

Both are regenerated **in place**; the app's seeder merges every pack by
lowercase headword (later path wins), so `urdu_wiktionary_pack.json` (u)
overrides the enrichment pack (0) for its words and
`zz_curated_corrections.json` (z) overrides both for the hand-fixed words.
The seed version is a content signature, so the app re-seeds on next launch
automatically after these files change — no Dart changes needed.

## Inputs (all free & open source)

1. **WordNet 3.1** (Princeton) — the `dict/` directory (index.*, data.*,
   cntlist). Download the 3.1 tarball from
   https://wordnet.princeton.edu/download/current-version and extract it.
   License: WordNet license (permissive, see
   `assets/dictionary/DICTIONARY_LICENSE.txt`).
   - `cntlist` provides per-sense SemCor frequency counts. The pipeline uses
     them to order each word's senses and picks the **most frequent** one —
     that is what fixes `bat → baseball`-type errors (the old code picked by
     gloss-overlap, which drifted to rare/technical senses).
2. **kaikki.org Urdu dump** (`urdu_wikt.jsonl`, JSONL, ~32 MB) —
   https://kaikki.org/dictionary/Urdu/ (CC BY-SA 4.0, © Wiktionary
   contributors). Used for Urdu meanings: each Urdu entry's English **gloss**
   (not its links — the first link is often a `{{topic|...}}` tag like
   "automotive" or "semantics", which produced the old mis-pairs) maps
   English → Urdu, common sense first.
3. **kaikki.org English dump — the second Urdu source** (CC BY-SA 4.0). The
   reverse direction: each **English** headword's curated Urdu `translations`.
   It adds common words the Urdu dump's glosses miss (240 pack words get
   their Urdu from this source alone: `bench`, `brake`, `biology`,
   `chemistry`, `chicken`, ...) and independently confirms existing ones.
   Vulgar/sensitive English headwords are dropped before pairing, exactly
   like the Urdu-dump path. Only the noun/verb/adjective/adverb `by-pos`
   files are needed. The pipeline reads a small pre-filtered extract
   (`EN_WIKT_URD`, default `/tmp/eng_wikt_urd/*.jsonl`) — lines containing
   `"lang": "Urdu"` — to avoid re-streaming ~2.7 GB of JSON per build.
   Regenerate the extract with:

   ```bash
   mkdir -p /tmp/eng_wikt_urd
   for pos in noun verb adj adv; do
     URL="https://kaikki.org/dictionary/English/pos-$pos/kaikki.org-dictionary-English-by-pos-$pos.jsonl"
     curl -sL "$URL" | grep -a '"lang": "Urdu"' > /tmp/eng_wikt_urd/${pos}_urd.jsonl
   done
   ```
4. **`OLD_URDU_PACK`** (default: the committed snapshot at
   `tools/dictionary/snapshots/urdu_wiktionary_pack.v21.8.json` — the
   pre-pipeline pack users had already seen). Its Urdu lists are used **only as
   a fallback** for words the new sources don't cover (currently 26 words:
   astronomy, biology, botany, chemistry, geography, linguistics, music,
   mythology, physics, politics, rooster, ...). Never point this at the
   current working-tree output file — reading your own output back as input
   would freeze stale entries (e.g. `have → گلا بیٹھنا`) into every future
   build. To use a different previous pack, `export OLD_URDU_PACK=/path/...`.
5. **`assets/dictionary/wordset.jsonl.gz`** (already in the repo) — fallback
   definitions and example sentences for words WordNet lacks.

## How to run

```bash
# point at your raw data (defaults shown). OLD_URDU_PACK already defaults to
# the committed snapshot, so a plain run is reproducible out of the box:
export WN_DICT=/path/to/wordnet-3.1/dict
export KAIKKI_UR=/path/to/urdu_wikt.jsonl
export EN_WIKT_URD=/tmp/eng_wikt_urd

python3 tools/dictionary/rebuild_dictionary.py

# then validate the output (counts, duplicates, Urdu script, junk headwords)
python3 tools/dictionary/audit_packs.py
```

The script prints coverage statistics after each pack. It never touches the
other packs (`common_words*.json`, `exam_words.json`, `exam_extras.json`,
`zz_curated_corrections.json` — those stay hand-curated and win the merge).
`audit_packs.py` re-checks every pack afterwards: duplicate headwords inside
and across packs, empty definitions, Latin/digit leakage in Urdu meanings,
and leftover machine-generated synonyms/antonyms.

## Adding more words later

- **More Urdu**: drop a bigger/cleaner English→Urdu dictionary into the same
  JSONL format and re-run — the pipeline merges and keeps existing entries.- **Hand fixes**: add entries to `zz_curated_corrections.json` (it wins the
   merge) — no regeneration needed. Recent additions: `courtesan → طوائف`,
   `lesbianism → ہم جنس پرستی`, `oblique → ترچھا` (fixes wrong fallback-only
   pairs inherited from the pre-pipeline pack).
- **New curated lists**: drop a new `*.json` pack into `assets/dictionary/`
  and rebuild the app; the seeder picks it up automatically.

## Quality rules enforced by the pipeline

- **Common-sense-first WordNet definitions.** Senses are ordered by each
  lemma's own SemCor count (`cntlist`), not the last member's count — the
  naive "last member wins" made common senses look rare (`cat → to vomit`).
  Satellite-adjective keys (`bright%5:00:00:light:06`) are matched by their
  gloss disambiguator word. Words where SemCor contradicts learner intuition
  (`bank → sloping land`, `sheik → dandy`) are hand-pinned in the `zz_` pack.
- **Gloss-first Urdu extraction.** English comes from each Urdu sense's gloss
  (never the links, which leak `{{topic|...}}` tags), with a leading infinitive
  "to " stripped so `to accept → accept`. Multi-word phrase glosses are
  filtered out as headwords.
- **Offensive content is dropped.** Senses whose gloss/links contain vulgar
  content are removed entirely, and Urdu words with digits or vulgar tokens
  (token-exact, so `چودہ` "fourteen" survives) never ship. The English-dump
  loader applies the same vulgarity filter to its **English headwords**
  (arse, ass, anal, condom, crap, fuck, sex, slut, vagina, ...), and the stem
  tokens (`copulat`, `masturbat`, `ejaculat`) are matched as prefixes so
  copulate/copulation, masturbate/masturbation and ejaculate/ejaculation are
  all blocked (a trailing word boundary after the stem used to let them
  through).
- Urdu meanings are validated as Urdu script (no Latin leakage).
- Example sentences filter out unsuitable content and fragments < 3 words.
- Synonyms/antonyms come only from the selected common-sense synset (no
  cross-sense mixing, which is what made old auto-synonyms look wrong).
- Headword junk is dropped (suffix fragments like `-ed` / `step-`, parentheses,
  digits, definitional phrase glosses like "a code of laws").
- Entries with no English body are kept only when the base Wordset dictionary
  can still supply the definition — the app never shows a word with nothing.
- The previous output is never read back as an input (see `OLD_URDU_PACK`), so
  the pipeline is reproducible: same raw sources → same packs, every run.

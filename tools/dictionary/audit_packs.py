#!/usr/bin/env python3
"""One-off quality/duplicate audit for the Sapiora dictionary packs.

Reads every pack in assets/dictionary/*.json and reports:
  - per-pack entry counts and coverage (definition / Urdu / usage),
    including any leftover machine-generated synonyms/antonyms
  - duplicate headwords within each pack and across packs (merge order
    is alphabetical by filename; the last pack wins a collision)
  - Urdu script validation (no Latin leakage, no digits, no empty Urdu),
    empty English definitions, junk headwords
  - spot-check of words the second Urdu source (kaikki English dump) adds

Run from the repo root:
  python3 tools/dictionary/audit_packs.py
"""
from __future__ import annotations

import json
import os
import re
import sys
import unicodedata
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DICT = os.path.join(ROOT, 'assets', 'dictionary')

URDU_RE = re.compile(r'[\u0600-\u06FF]')


def norm(w: str) -> str:
    """Lowercase + strip diacritics (matches the rebuild pipeline)."""
    return ''.join(
        c for c in unicodedata.normalize('NFD', w.lower())
        if unicodedata.category(c) != 'Mn'
    )


def load(path):
    with open(path, encoding='utf-8') as f:
        return json.load(f)


def main() -> int:
    files = sorted(f for f in os.listdir(DICT) if f.endswith('.json'))
    if not files:
        print('no packs found under', DICT)
        return 1
    packs = {}
    all_words = {}
    for fn in files:
        data = load(os.path.join(DICT, fn))
        packs[fn] = data
        words = {norm(e.get('word', '')) for e in data if isinstance(e, dict)}
        all_words[fn] = words
        print(f'\n=== {fn} ===')
        print(f'  entries: {len(data)}')
        if data and isinstance(data[0], dict):
            with_def = sum(1 for e in data if e.get('englishDefinition'))
            with_urdu = sum(1 for e in data if e.get('urduMeanings'))
            with_syn = sum(1 for e in data if e.get('synonyms'))
            with_ant = sum(1 for e in data if e.get('antonyms'))
            with_usage = sum(1 for e in data if e.get('usage'))
            print(f'  def={with_def} urdu={with_urdu} '
                  f'synonyms={with_syn} antonyms={with_ant} usage={with_usage}')
            seen = Counter(norm(e.get('word', '')) for e in data if isinstance(e, dict))
            dups = {w: c for w, c in seen.items() if c > 1}
            if dups:
                print(f'  !! DUPLICATE headwords: {len(dups)}')
                for w, c in list(dups.items())[:15]:
                    print(f'      {w!r} x{c}')
            else:
                print('  duplicates: none')
            empty_def = [e.get('word') for e in data if isinstance(e, dict)
                         and not (e.get('englishDefinition') or '').strip()]
            empty_urdu = [e.get('word') for e in data if isinstance(e, dict)
                          and (e.get('englishDefinition') or '').strip()
                          and not e.get('urduMeanings')]
            if empty_def:
                print(f'  !! no englishDefinition: {len(empty_def)} '
                      f'e.g. {empty_def[:10]}')
            if empty_urdu:
                print(f'  !! def but no urduMeanings: {len(empty_urdu)} '
                      f'e.g. {empty_urdu[:10]}')
            bad_urdu = []
            for e in data:
                if not isinstance(e, dict):
                    continue
                for u in (e.get('urduMeanings') or []):
                    if not URDU_RE.search(u):
                        bad_urdu.append((e.get('word'), u, 'no-urdu-script'))
                    elif re.search(r'[A-Za-z]', u):
                        bad_urdu.append((e.get('word'), u, 'latin-leak'))
                    elif re.search(r'\d', u):
                        bad_urdu.append((e.get('word'), u, 'digit'))
            if bad_urdu:
                print(f'  !! bad Urdu meanings: {len(bad_urdu)}')
                for w, u, why in bad_urdu[:15]:
                    print(f'      {w!r}: {u!r} ({why})')
            else:
                print('  Urdu meanings: all Urdu script, no Latin/digits')
            junk = [e.get('word', '') for e in data if isinstance(e, dict)
                    and re.search(r'[()]|\d', e.get('word', ''))
                    or (isinstance(e, dict)
                        and (e.get('word', '').startswith('-')
                             or e.get('word', '').endswith('-')))]
            if junk:
                print(f'  !! junk headwords: {len(junk)} e.g. {junk[:10]}')
            else:
                print('  junk headwords: none')

    print('\n=== cross-pack headword overlap (merge order: later filename wins) ===')
    for fn in sorted(all_words):
        print(f'  {fn}: {len(all_words[fn])} unique headwords')
    for i, fn in enumerate(sorted(all_words)):
        for fn2 in sorted(all_words):
            if fn2 <= fn:
                continue
            overlap = all_words[fn] & all_words[fn2]
            if overlap:
                print(f'  overlap {fn} ∩ {fn2}: {len(overlap)} '
                      f'e.g. {sorted(overlap)[:8]}')

    print('\n=== second Urdu source spot-check ===')
    for w in ['academy', 'airplane', 'birthday', 'bread', 'buy', 'airport',
              'teacher', 'market', 'windscreen', 'automotive', 'semantics',
              'abacus', 'bank', 'have', 'angel', 'breakfast', 'scared', 'fez',
              'bug', 'oyster', 'hearts', 'window', 'school']:
        found = [fn for fn, words in all_words.items() if norm(w) in words]
        status = 'in: ' + ', '.join(found) if found else '!! MISSING EVERYWHERE'
        print(f'  {w:15s} {status}')
    return 0


if __name__ == '__main__':
    sys.exit(main())

from __future__ import annotations

import json
import re
from pathlib import Path

RAW = Path('/home/ubuntu/gre3500_raw.txt')
OUT = Path('/home/ubuntu/gre_words_extracted.json')

# Barron's pages use a two-column table: a headword starts at column zero and
# continuation lines are indented. Keep only the first token on headword lines.
HEADWORD = re.compile(r"^([A-Za-z][A-Za-z'().,/-]*)(?:\s+|$)")
HEADER = re.compile(r"^(Barron GRE word list|GRE word list|\f|$)", re.I)

words: list[str] = []
seen: set[str] = set()
for raw in RAW.read_text(encoding='utf-8', errors='replace').splitlines():
    line = raw.rstrip('\n\r')
    if not line or line.startswith(' ') or line.startswith('\t'):
        continue
    line = line.replace('\f', '').strip()
    if not line or HEADER.match(line):
        continue
    match = HEADWORD.match(line)
    if not match:
        continue
    token = match.group(1).strip('.,')
    # Exclude headings or malformed artifacts; retain parenthetical variants as
    # the source's actual headword token for later normalization.
    if len(token) < 2 or token.lower() in {'a', 'i'}:
        continue
    key = token.lower()
    if key not in seen:
        seen.add(key)
        words.append(token)

OUT.write_text(json.dumps(words, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'extracted={len(words)}')
print('first=', words[:20])
print('last=', words[-20:])

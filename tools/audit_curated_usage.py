import json
import re
from pathlib import Path

path = Path('assets/dictionary/zz_curated_corrections.json')
data = json.loads(path.read_text(encoding='utf-8'))

def tokens(text):
    return set(re.findall(r"[a-z]+", text.lower()))

suffixes = ('s', 'es', 'ed', 'ing', 'er', 'or', 'ly', 'tion', 'ment', 'ness', 'able', 'al', 'ive')

bad = []
for record in data:
    word = str(record.get('word', '')).strip().lower()
    usage = record.get('usage')
    if not word or not isinstance(usage, dict):
        continue
    english = str(usage.get('english', '')).strip()
    ts = tokens(english)
    valid = word in ts
    if not valid:
        for token in ts:
            if token.startswith(word) or word.startswith(token):
                valid = True
                break
        if not valid:
            for suffix in suffixes:
                if word.endswith(suffix) and word[:-len(suffix)] in ts:
                    valid = True
                    break
    if not valid:
        bad.append((word, english))

print(f'total records: {len(data)}')
print(f'usage records: {sum(isinstance(r.get("usage"), dict) for r in data)}')
print(f'potential mismatches: {len(bad)}')
for word, english in bad:
    print(f'{word}\t{english}')

for record in data:
    if str(record.get('word', '')).lower() in {'elevate', 'elevated', 'elevator', 'elevation'}:
        print('ELEVATE-FAMILY:', json.dumps(record, ensure_ascii=False))

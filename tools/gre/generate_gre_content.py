from __future__ import annotations

import concurrent.futures
import json
import re
import time
from pathlib import Path

from openai import OpenAI

ROOT = Path('/home/ubuntu/Lexiora')
WORDS_PATH = Path('/home/ubuntu/gre_words_extracted.json')
RAW_PATH = Path('/home/ubuntu/gre3500_raw.txt')
EXISTING_PATH = ROOT / 'assets/vocabulary/gre_high_frequency.json'
OUT_VOCAB = ROOT / 'assets/vocabulary/gre_high_frequency.json'
OUT_DICT = ROOT / 'assets/dictionary/gre_high_frequency.json'
MODEL = 'gpt-5-mini'
BATCH_SIZE = 16
MAX_WORKERS = 3
CHECKPOINT = ROOT / 'tools/gre/gre_content_checkpoint.json'


def parse_source_definitions() -> dict[str, str]:
    definitions: dict[str, str] = {}
    current: str | None = None
    chunks: list[str] = []
    for raw in RAW_PATH.read_text(encoding='utf-8', errors='replace').splitlines():
        line = raw.replace('\f', '').rstrip()
        if not line:
            continue
        if line.startswith(' ') or line.startswith('\t'):
            if current:
                chunks.append(line.strip())
            continue
        m = re.match(r"^([A-Za-z][A-Za-z'().,/-]*)(?:\s+|$)(.*)$", line.strip())
        if not m:
            continue
        if current:
            definitions[current] = ' '.join(chunks).strip()
        current = m.group(1).strip('.,')
        chunks = [m.group(2).strip()] if m.group(2).strip() else []
    if current:
        definitions[current] = ' '.join(chunks).strip()
    return {k.lower(): v for k, v in definitions.items()}


def schema() -> dict:
    return {
        'type': 'json_schema',
        'json_schema': {
            'name': 'gre_entries',
            'strict': True,
            'schema': {
                'type': 'object',
                'properties': {
                    'entries': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'word': {'type': 'string'},
                                'urdu': {'type': 'string'},
                                'english': {'type': 'string'},
                                'synonyms': {'type': 'array', 'items': {'type': 'string'}},
                                'antonyms': {'type': 'array', 'items': {'type': 'string'}},
                                'pos': {'type': 'string'},
                                'example': {'type': 'string'},
                            },
                            'required': ['word', 'urdu', 'english', 'synonyms', 'antonyms', 'pos', 'example'],
                            'additionalProperties': False,
                        },
                    }
                },
                'required': ['entries'],
                'additionalProperties': False,
            },
        },
    }


def request_batch(batch: list[dict]) -> list[dict]:
    client = OpenAI(timeout=90.0, max_retries=1)
    prompt = (
        'Create high-quality competitive-exam vocabulary entries for every requested word. '
        'Return exactly one object per input word, in the same order. Use concise original wording; '
        'the PDF snippets are context only and must not be copied verbatim. '
        'Urdu must be a natural concise meaning in Urdu script. English must be one clear definition. '
        'Give 2-4 relevant synonyms and 1-3 meaningful antonyms (use an empty array only when no genuine antonym exists). '
        'Use one primary part of speech such as noun, verb, adjective, adverb, or phrase. '
        'Example must be a natural, exam-oriented English sentence containing the exact headword where practical. '
        'For fields supplied as existing data, preserve them exactly and only fill missing fields.\n\n'
        + json.dumps(batch, ensure_ascii=False)
    )
    for attempt in range(5):
        try:
            response = client.chat.completions.create(
                model=MODEL,
                messages=[
                    {'role': 'system', 'content': 'You are a precise bilingual GRE vocabulary editor. Output only valid JSON matching the schema.'},
                    {'role': 'user', 'content': prompt},
                ],
                response_format=schema(),
                max_completion_tokens=12000,
            )
            payload = json.loads(response.choices[0].message.content)
            entries = payload.get('entries', [])
            if len(entries) != len(batch):
                raise ValueError(f'expected {len(batch)} entries, received {len(entries)}')
            return entries
        except Exception:
            if attempt == 4:
                raise
            time.sleep(2 ** attempt)
    raise RuntimeError('unreachable')


def clean_entry(raw: dict, requested: dict) -> dict:
    word = requested['word']
    def val(key: str) -> str:
        existing = str(requested.get(key, '') or '').strip()
        generated = str(raw.get(key, '') or '').strip()
        return existing or generated
    synonyms = requested.get('synonyms') or raw.get('synonyms') or []
    antonyms = requested.get('antonyms') or raw.get('antonyms') or []
    return {
        'word': word,
        'urdu': val('urdu'),
        'english': val('english'),
        'synonyms': [str(x).strip() for x in synonyms if str(x).strip()],
        'antonyms': [str(x).strip() for x in antonyms if str(x).strip()],
        'pos': val('pos') or 'unknown',
        'example': val('example'),
    }


def main() -> None:
    words = json.loads(WORDS_PATH.read_text(encoding='utf-8'))
    source = parse_source_definitions()
    existing_doc = json.loads(EXISTING_PATH.read_text(encoding='utf-8'))
    existing_by_key = {x['word'].lower(): x for x in existing_doc.get('words', [])}

    requested: list[dict] = []
    for word in words:
        old = existing_by_key.get(word.lower(), {})
        requested.append({
            'word': old.get('word', word),
            'urdu': old.get('urdu', ''),
            'english': old.get('meaning', ''),
            'pos': old.get('pos', ''),
            'source_definition': source.get(word.lower(), '')[:500],
        })

    batches = [requested[i:i + BATCH_SIZE] for i in range(0, len(requested), BATCH_SIZE)]
    completed: dict[str, list[dict]] = {}
    if CHECKPOINT.exists():
        try:
            completed = json.loads(CHECKPOINT.read_text(encoding='utf-8'))
            completed = {str(k): v for k, v in completed.items()}
        except Exception:
            completed = {}
    pending = [(i, batch) for i, batch in enumerate(batches) if str(i) not in completed]
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        future_map = {pool.submit(request_batch, batch): i for i, batch in pending}
        for future in concurrent.futures.as_completed(future_map):
            i = future_map[future]
            completed[str(i)] = future.result()
            CHECKPOINT.write_text(json.dumps(completed, ensure_ascii=False), encoding='utf-8')
            print(f'batch {i + 1}/{len(batches)} complete', flush=True)
    generated: list[dict] = []
    for i in range(len(batches)):
        generated.extend(completed[str(i)])

    merged: list[dict] = []
    seen: set[str] = set()
    for req, gen in zip(requested, generated):
        entry = clean_entry(gen, req)
        key = entry['word'].strip().lower()
        if key in seen:
            continue
        seen.add(key)
        merged.append(entry)

    # The vocabulary pack keeps its established list identity/layout and adds
    # the six requested fields without deleting IPA or existing metadata.
    vocab_words = []
    for entry in merged:
        old = existing_by_key.get(entry['word'].lower(), {})
        vocab_words.append({
            'word': entry['word'],
            'ipa': old.get('ipa'),
            'urdu': entry['urdu'],
            'meaning': entry['english'],
            'pos': entry['pos'],
            'synonyms': entry['synonyms'],
            'antonyms': entry['antonyms'],
            'example': entry['example'],
        })
    vocab_doc = {
        'list': existing_doc['list'],
        'words': vocab_words,
    }
    OUT_VOCAB.write_text(json.dumps(vocab_doc, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    # Exam dictionary packs are already supported by the app and preserve the
    # full rich content in the Main Dictionary without a second list.
    dict_entries = []
    for entry in merged:
        dict_entries.append({
            'word': entry['word'],
            'urduMeanings': [entry['urdu']],
            'englishDefinition': entry['english'],
            'partOfSpeech': entry['pos'],
            'synonyms': entry['synonyms'],
            'antonyms': entry['antonyms'],
            'usage': {
                'context': 'GRE / competitive examinations',
                'english': entry['example'],
                'urdu': '',
            },
        })
    OUT_DICT.write_text(json.dumps(dict_entries, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'final entries={len(merged)} existing={len(existing_by_key)}')
    if CHECKPOINT.exists():
        CHECKPOINT.unlink()


if __name__ == '__main__':
    main()

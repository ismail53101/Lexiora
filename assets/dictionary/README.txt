Lexiora offline dictionary data
================================

Source : Wordset Dictionary (https://github.com/wordset/wordset-dictionary)
License: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
         Portions derived from Princeton WordNet 3.0 (WordNet License).

Format : wordset.jsonl.gz — gzip-compressed JSON Lines. One entry (word sense)
         per line: {"w":<word>,"p":<part of speech>,"m":<meaning>,"e":<example?>}

This data is redistributed under CC BY-SA 4.0. See DICTIONARY_LICENSE.txt for the
full license text. The Lexiora application code is MIT-licensed; this bundled
data set retains its own CC BY-SA 4.0 license and attribution requirements.

Curated pack: urdu_wiktionary_pack.json
  English → Urdu word dictionary derived from the kaikki.org Urdu Wiktionary
  dump (https://kaikki.org/dictionary/Urdu/): English glosses paired with their
  Urdu headwords, part of speech, a Wordset English definition and (where
  available) a usage example with English + Urdu text. License: CC BY-SA 4.0
  (© Wiktionary contributors). Auto-discovered by the exam-pack seeder; entries
  are only words not already covered by any existing curated pack, so no
  existing entry is overridden.

Enrichment pack: 000_wordnet_enrichment.json
  WordNet 3.1 (https://wordnet.princeton.edu) synonyms, antonyms and example
  sentences for ~80,000 dictionary words. Derived from the official WordNet
  data files (WordNet License — permissive, redistribution permitted). One
  entry per headword: {"word","partOfSpeech","synonyms","antonyms","usage"}.
  The "000_" prefix makes the exam-pack seeder merge it FIRST, so the curated
  packs always win for words they already cover. Together with the base-form
  fallback in examData() this gives nearly every dictionary word its own
  Synonyms & Antonyms and Usage (example sentence) sections; the Urdu
  translation of an auto-derived example sentence is fetched by the hybrid
  translator and cached for offline reuse.

Curated packs: exam_words.json, common_words.json, common_words_2.json
  Hand-curated exam / high-frequency word packs (CSS & BPSC oriented). They are
  enriched with WordNet synonyms, antonyms and an example sentence wherever the
  field was previously empty; hand-written Urdu meanings, usage sentences and
  exam notes are never overwritten.

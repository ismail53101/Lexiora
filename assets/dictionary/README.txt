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
  WordNet 3.1 (https://wordnet.princeton.edu) example sentences for ~110k
  dictionary words (WordNet License — permissive, redistribution permitted).
  One entry per headword: {"word","partOfSpeech","usage"} — an exam-friendly
  example sentence (best sense matched against the word's dictionary meaning;
  inappropriate content filtered). The "000_" prefix makes the exam-pack
  seeder merge it FIRST, so the curated packs always win for words they
  already cover. Together with the base-form + de-accent fallback in
  examData(), nearly every dictionary word shows a Usage (example sentence)
  section; the Urdu translation of the sentence is fetched by the hybrid
  translator and cached for offline reuse.

  Synonyms & Antonyms are NOT auto-generated: WordNet synset members are too
  noisy for a learner dictionary (e.g. "avoid" → "face up"), so only
  hand-curated synonyms/antonyms (exam_words.json, exam_extras.json) are
  shown, and the Synonyms & Antonyms section hides for every other word.

Curated packs: exam_words.json, common_words.json, common_words_2.json
  Hand-curated exam / high-frequency word packs (CSS & BPSC oriented).
  exam_words.json carries hand-written synonyms/antonyms/usage/idioms/exam
  notes; common_words* carry simple English + Urdu meanings and a WordNet
  example sentence where available. Hand-written Urdu meanings, usage
  sentences and exam notes are never overwritten.

Sapiora offline translation data
================================

This bundle combines two free/open sources:

1) FreeDict (https://freedict.org / https://github.com/freedict/fd-dictionaries)
   English → French (eng-fra), Portuguese (eng-por), Hindi (eng-hin),
   Arabic (eng-ara).
   License: GNU General Public License (GPL) — see TRANSLATIONS_LICENSE.txt.

2) Wiktionary via kaikki.org (English + Urdu Wiktionary data)
   English → Urdu (ur) — expanded with academic/newspaper/exam vocabulary,
   mined from English-Wiktionary translation tables and Urdu-Wiktionary glosses.
   License: Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0),
   https://creativecommons.org/licenses/by-sa/4.0/  (© Wiktionary contributors).

Extra pack: urdu_wiktionary_extra.json
   Urdu → English (l="en") rows derived from the kaikki.org Urdu Wiktionary
   dump (https://kaikki.org/dictionary/Urdu/) — Urdu headwords with their
   English glosses — plus new English → Urdu (l="ur") rows not covered by the
   base set. Same CC BY-SA 4.0 license as source (2) above. Merged after the
   base gz by the seeder; base rows always win on a (lang, word) collision.

Extra pack: curated_reader_fixes.json
   Hand-curated English → Urdu (l="ur") rows for reader pop-up words that the
   online fallback mistranslated (e.g. "insulated" → موصل = conductor,
   "communiqué" → بات چیت, "underlining" → a transliteration) or that showed
   no English definition. They are merged the same way as the Wiktionary extra
   pack, and the app's curated override layer serves the matching English
   meanings offline. Simple, exam-appropriate translations only.

Format : translations.jsonl.gz — gzip-compressed JSON Lines. One entry per line:
         {"l":<2-letter target language>,"w":<english headword, lowercase>,"t":<translation(s)>}

Each source is redistributed under its own license (above). The Sapiora
application code is MIT-licensed and independent of this bundled data.

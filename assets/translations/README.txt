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

Format : translations.jsonl.gz — gzip-compressed JSON Lines. One entry per line:
         {"l":<2-letter target language>,"w":<english headword, lowercase>,"t":<translation(s)>}

Each source is redistributed under its own license (above). The Sapiora
application code is MIT-licensed and independent of this bundled data.

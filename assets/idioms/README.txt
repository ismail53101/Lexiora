Sapiora idioms & proverbs data
==============================

Source : "Urdu Idioms with English Translation" — Ehtisham1328 on Hugging Face
         https://huggingface.co/datasets/Ehtisham1328/urdu-idioms-with-english-translation
License: Apache License 2.0 — see LICENSE.txt.

Format : idioms.json — JSON array of entries:
         {"id": <int>, "urdu": "<Urdu idiom/proverb in Urdu script>",
          "english": "<English translation/meaning>"}

Notes:
  * This is a SEPARATE data structure from the normal vocabulary and dictionary
    packs. It is NOT merged into any vocabulary list or dictionary table, and is
    NOT auto-discovered by any seeder. It is bundled as a standalone asset so a
    future idioms/proverbs feature can consume it directly.
  * Duplicates were removed (case-insensitive on the Urdu text); every entry was
    validated to contain Urdu script and a non-empty English translation.
  * The Sapiora application code is MIT-licensed and independent of this bundled
    data; the data retains its own Apache-2.0 license and attribution above.

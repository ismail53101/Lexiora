# STANDS4 API integration findings

Verified documentation:

- Definitions API: https://www.definitions.net/definitions_api.php
- Synonyms API: https://www.synonyms.com/synonyms_api.php

Endpoints:

- `https://www.stands4.com/services/v2/defs.php`
- `https://www.stands4.com/services/v2/syno.php`

Required parameters: `uid`, `tokenid`, `word`; optional `format=json`.

Definitions response fields: `results.result.term`, `definition`, `partofspeech`, `example`.

Synonyms response fields: `results.result.term`, `definition`, `partofspeech`, `synonyms` (comma-delimited), and `antonyms` (comma-delimited).

The documented free quota is up to 100 queries per day per API service. Lexiora calls STANDS4 only for a word missing from the bundled offline dictionary and caches the normalized result in the Worker for 24 hours. Credentials are Worker secrets, never Flutter/APK values.

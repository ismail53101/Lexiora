# Changelog

All notable changes to Sapiora are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.11.0] — 2026-08-08

**Staged Quiz — play the existing 5,243-question banks as a premium level
ladder.** The Quiz tab now opens on two cards — **MCQs** (subject-wise
practice) and **Quiz** (timed stages). Each stage is 10 questions with a 30s
per-question countdown, exam-style scoring at the end, star ratings and a
score ring; passing a stage (≥50%) unlocks the next one, with a paginated
stage map, per-stage best scores and a next-stage flow. No new content: stages
are deterministic slices of the bundled banks, and every attempt still feeds
Analytics, the wrong-answer notebook and Review Answers.

### Added
- **Quiz tab home** with two premium gradient cards (MCQs / Quiz), replacing
  the bare subject list as the tab root. Global search, analytics, bookmarks,
  wrong answers and settings stay in the overflow menu.
- **Staged Quiz ladder** (`Quiz → Quiz → subject`): every 10-question slice of
  a subject's pool as a card — locked (padlock), current (PLAY badge) or
  completed (best-score ring + stars). Paginated so 200+ stage subjects stay
  clean; header shows passed/total with a progress bar.
- **Stage player**: 30s countdown per question (auto-skip on timeout),
  QUIT/NEXT controls, no feedback until the end.
- **Stage results**: animated score ring, 0–3 stars (3★ ≥90%, 2★ ≥70%, 1★
  ≥50%), pass/unlock banner, Review answers, Retry and Next-stage actions.
- **Stage progress persistence**: new `quiz_stage_progress` table (schema v17,
  additive migration) storing best score/stars, attempt count and passed state
  per subject/stage; unlock state is derived (stage N+1 needs stage N passed).
- Unit tests for the stage rules (bucket math, stars, unlock ladder) and for
  the repository (stage slicing + best-result merge).

### Changed
- `QuizMode` gains a `stage` mode; stage attempts are recorded like any other
  quiz, so Analytics / Wrong Answers / Review keep working.

### Notes
- Data-driven: stages are derived from the subject's question count at runtime,
  so future bank additions automatically extend the ladder — no data changes
  needed and the duplicate-prevention rule is untouched.

## [0.10.2] — 2026-08-08

**Fix: quiz banks now actually ship in the APK.** Flutter's asset bundler only
includes files *directly inside* a declared asset directory — it does not
recurse into subdirectories. The 46 bank files live in subdirectories of
`assets/quiz/`, so the previous release packaged only `manifest.json` and the
seeder failed to load any questions on device (Quiz section showed 0
questions). Each quiz subdirectory is now declared explicitly in `pubspec.yaml`
so every bank ships. The seeder was also hardened: a failing bank is logged and
skipped instead of aborting the whole seed, and a CI regression test asserts
that every manifest bank file is covered by a declared asset.

## [0.10.1] — 2026-08-08

**Bundled exam question banks.** The Quiz Engine now ships its full curated
content instead of demo rows: **5,243 deduplicated MCQs across 46 banks** under
`assets/quiz/` (Pakistan Affairs 130×10, Islamic Studies 100×22, General Science
& Ability 130×7, English 833), seeded once into the normal quiz tables by a
manifest-driven seeder. Every generated question is guarded by
`QuizDuplicateChecker` before it can be saved.

### Added
- **Quiz duplicate prevention** — `QuizDuplicateChecker` rejects exact,
  reworded, option-reordered, different-option and same-concept duplicates
  against the entire corpus before a generated MCQ is saved.
- **Dataset integrity test** — the full shipped corpus must parse cleanly and
  pass the duplicate check in CI.

### Changed
- The legacy demo seed is replaced by the bundled manifest seeder (dataset
  version `quiz-bundled-2026.08-v24`); existing installs re-seed once
  automatically.

### Fixed
- The seeder detects legacy demo rows by their `demo_` id prefix (`source` is
  an in-memory-only entity field and is never persisted on the row).

## [Unreleased]

### Added
- **Duplicate prevention for generated MCQs (`QuizDuplicateChecker`).** A pure,
  deterministic check now guards every generated question before it is saved:
  the candidate is compared against the ENTIRE question bank and rejected when
  it is an exact duplicate, a reworded duplicate, the same question with
  reordered options, the same question with different options, or the same
  knowledge point (paraphrase). `QuizAdminRepository.addGeneratedQuestions`
  saves only the questions that pass, never modifies or duplicates existing
  rows, and reports each rejection with the reason and the colliding question.
  Uniqueness wins over quantity: if duplicates are found, fewer questions are
  returned than requested rather than lowering the bar. Unit-tested in
  `test/modules/quiz/quiz_duplicate_check_test.dart`.
- **Dataset-level duplicate prevention test**
  (`test/modules/quiz/quiz_dataset_integrity_test.dart`). Every bundled bank
  under `assets/quiz/` is parsed with the same `QuizJsonParser` the seeder uses
  and the whole shipped corpus (~3,750 questions) is run through the real
  `QuizDuplicateChecker` — any duplicate group (exact, reordered options,
  different options, reworded or same-concept) fails the suite, so a future
  edit can never silently re-introduce duplicate questions.

### Changed
- **Quiz banks deduplicated.** General Science & Ability is now **910 unique
  MCQs across the 7 banks** — physics (130), chemistry (130), biology (130),
  computer (130), earth & space (130), inventions & scientists (130), and math &
  reasoning (130). The GSA banks were expanded from 662 to 910 questions (+248):
  every new question was pre-checked against the entire bundled corpus with
  `QuizDuplicateChecker`, and exact, reworded, different-option, reordered-
  option and same-concept collisions were rejected before anything was saved. English is now **833 unique MCQs across the 7 banks** —
  antonyms (77), grammar (187), idioms & phrases (117), one-word substitution
  (103), sentence correction (104), synonyms (127), and vocabulary (118).
  Islamic Studies is now **2,200 unique MCQs across the 22 banks** and
  Pakistan Affairs is now **1,300 unique MCQs across the 10 banks** (all
  re-validated with sequential IDs; see the rebalancing entry below). Every bank was checked against the
  duplicate-prevention rules in `QuizDuplicateChecker`, and the remaining
  duplicate and near-duplicate questions (same fact re-worded, same question
  re-asked with different wording or options, same sentence across banks,
  identical stems re-asked with reworded answers) were removed so the shipped
  corpus passes the same check that guards new MCQs. Dataset version bumped
  (`quiz-bundled-2026.08-v23`) so existing installs re-seed and pick up the
  expanded, deduplicated set without losing progress.
- **Quiz bank rebalancing.** Islamic Studies is now **2,200 unique MCQs — 100
  per bank across all 22 banks** (previously 48–100 per bank, 1,334 total) and
  Pakistan Affairs is now **1,300 unique MCQs — 130 per bank across all 10
  banks** (previously 91–130, 910 total). Each new question was authored
  against its bank's existing content and passed through the same
  `QuizDuplicateChecker` the app uses: every candidate was compared with the
  ENTIRE bundled corpus and exact, reworded, different-option,
  reordered-option and same-concept collisions were rejected before anything
  was saved (16 near-duplicates were caught and dropped). Banks are capped at
  their targets with sequential IDs, JSON re-validated, and the whole shipped
  corpus (~5,243 questions) passes the dataset integrity test. Dataset version
  bumped (`quiz-bundled-2026.08-v24`) so existing installs re-seed and pick up
  the balanced set without losing progress.

## [0.5.0] — 2026-07-25

Phase v0.5.0 — **Grammar hierarchy**: the module now follows a strict
**Category → Subcategory → Lesson** structure. Topics are no longer merged onto
one page; each type opens its own dedicated lesson.

### Added
- **Hierarchical navigation.** The Grammar home lists categories; tapping one
  shows its subtopics; a subtopic opens its own lesson (supports 3 levels, e.g.
  Tenses → Present Tense → Present Simple). New `grammar_topics` tree table
  (schema **v8**, additive), seeded from a bundled `grammar_topics.json`; a new
  Topic screen and route (`/grammar/topic/:id`).
- **Dedicated lessons** with the mandated sections: Introduction, Urdu
  Explanation, English Explanation, Types, Rules, Examples, Common Mistakes,
  Practice, Quiz, Summary. Empty sections are hidden.
- **Fully authored flagship subtrees:** Parts of Speech (9 lessons: noun,
  pronoun, verb, adjective, adverb, preposition, conjunction, interjection,
  determiner) and Tenses (Present/Past/Future → 12 tense lessons), each with all
  sections including Urdu explanations and a quiz.

### Changed
- The previous flat lessons (Sentence Structure, Phrases, Clauses, Articles,
  Prepositions, Conjunctions, Subject–Verb Agreement, Modals, Active & Passive
  Voice, Direct & Indirect Speech, Punctuation, Conditional Sentences, Common
  Errors) are preserved as leaf categories so nothing is lost; they can be split
  into subtopics the same way the flagship categories were. Progress and
  favorites are reused, keyed by leaf id.

### Notes
- Offline-first; search now spans all leaf lessons. New tests cover the tree data
  source, the seeder and the bundled tree's shape (Parts of Speech = 9 leaves,
  Tenses = 3 branches × 4). `flutter analyze` is clean and the suite passes.

## [0.4.4] — 2026-07-25

Phase v0.4.4 — **expanded the curated dictionary pack** so the rich exam sections
(Urdu meanings, synonyms & antonyms, usage, collocations, word forms, idioms,
exam notes) appear for far more words.

### Changed
- The curated exam pack grew from **40 → 159 words**, adding high-frequency
  everyday and academic/editorial vocabulary (e.g. analyze, benefit, crucial,
  demonstrate, evaluate, implement, negotiate, significant, undermine). Each new
  entry has ordered Urdu meanings, an English definition, synonyms/antonyms,
  a context-tagged usage sentence (English + Urdu), collocations, word forms and
  an exam note. Bumped the dataset version so installs re-seed the larger pack.

### Notes
- These sections are curated (verified) content and render only for words in the
  pack; other words still show Meaning, Pronunciation and derived Related Words,
  hiding unverifiable sections (accuracy over completeness). `flutter analyze` is
  clean and the full suite passes.

## [0.4.3] — 2026-07-25

Phase v0.4.3 — enforces the **mandatory Dictionary display rules**: a fixed
section order, an offline audio pronunciation button, and family-only Related
Words. Additive; no existing feature removed.

### Added
- **Audio pronunciation** — a "tap to hear" button backed by on-device TTS
  (`flutter_tts`), working offline for installed voices. UK and US buttons are
  shown only when that accent's voice is available; a loading spinner shows while
  speaking; TTS errors never crash the app. IPA supports optional UK/US variants.

### Changed
- **Word Details now follows the exact mandated order**: Word → Meaning (same
  sense) → Pronunciation + Audio + Part of Speech → Other Common Meanings →
  Synonyms & Antonyms → Usage → Collocations → Word Forms / Related Words →
  Idioms → Exam Note. Extra base senses now surface under "Other Common
  Meanings" (the standalone Definitions list was folded in).
- **Word Forms and Related Words are one merged section** (curated forms first,
  then derived family words).
- **Related Words are now family-only.** Derivation matches the full root (word
  minus a trailing "e") instead of a fixed prefix, so `inquire → inquiry /
  inquirer / inquiring` and `govern → government / governor / governance`, while
  look-alikes like `policy → police` are correctly excluded.

### Notes
- Accuracy over completeness: sections with unverifiable data are hidden rather
  than shown wrong. New tests cover the family-only related-words derivation and
  the audio button's availability/disabled/play states. `flutter analyze` is
  clean and the full suite passes.

## [0.4.2] — 2026-07-25

Phase v0.4.2 — **Dictionary v2**: a professional, offline-first, exam-oriented
word profile (CSS/PMS/FPSC/IELTS) built on top of the existing dictionary and
hybrid translation. No existing feature was removed; everything is additive.

### Added
- **Redesigned Word Details** (Material 3 cards) showing, in order: Meaning
  (ordered Urdu + concise English), Pronunciation & Part of Speech, base
  Definitions, Other Common Meanings, Synonyms & Antonyms, exam-oriented Usage
  (one context-tagged sentence with the searched word highlighted, EN + Urdu),
  Common Collocations, Word Forms, Idioms & Phrases, and an Exam Note. Every
  section hides gracefully when its data is unavailable.
- **Curated exam word pack** — a bundled `exam_words.json` (40 high-frequency
  exam/editorial words) seeded once into the new `dictionary_exam_entries` table
  (schema **v7**, additive). Stored as JSON so richer content ships with no
  schema change.
- **Related Words** — derived offline from the base dictionary by shared root
  (e.g. economy → economic, economics, economist), shown as tappable chips.
- **Search history** — recent lookups saved locally in `dictionary_search_history`
  (capped at ~100, auto-pruned), surfaced as "Recent" chips on the Dictionary
  home with a Clear action.
- **Bookmark, Copy, and an Offline-status indicator** (🟢 Available Offline /
  🌐 Retrieved Online • Saved Offline). Bookmarks reuse the existing saved-words
  store.

### Changed
- Urdu meanings use the existing **hybrid translation** (offline cache first,
  then a cached online fallback) both in the reader and the Dictionary. Database
  schema bumped to **v7** with an additive `onUpgrade` migration (existing
  tables and data untouched).

### Notes
- Offline-first and fast: exam data and related words are local queries; the
  large base dictionary is unchanged. New tests cover the exam data source,
  seeder, related-words derivation, search-history capping and word-profile
  aggregation. `flutter analyze` is clean and the full suite passes.

## [0.4.1] — 2026-07-25

Phase v0.4.1 — the **Hybrid Translation System**. An enhancement of the existing
offline Translate module (not a replacement): it stays offline-first but now
seamlessly falls back to an online provider and caches the result for offline
reuse. No existing feature was changed or broken; everything is additive.

### Added
- **Online fallback (English → Urdu, and other target languages).** When a word
  has no offline translation, and only then, the reader popup fetches it from a
  configurable online provider, shows it, and **saves it for offline use** so the
  next lookup is fully local. The provider sits behind a
  `RemoteTranslationService` interface (default: MyMemory, keyless) and can be
  swapped with a one-line DI change — no UI edits. Connectivity is detected via a
  `ConnectivityService` interface.
- **Offline translation cache.** A new additive `translation_cache` table
  (schema **v6**) stores online results separately from the bundled data set, so
  re-seeding the bundle never discards cached words. Its composite primary key
  prevents duplicate cache rows.
- **Source labelling in the popup:** *Source: Offline*, or *Source: Online ·
  Saved for offline use.*, and a clear *“No offline translation found — connect
  to the internet…”* state with Retry.
- **Dictionary integration:** every word successfully translated online is
  registered into the Dictionary index (additive `registerExternalWord`), so it
  becomes searchable in future lookups.

### Changed
- Offline lookup now consults the bundled data set **and** the cache; the online
  provider is never called when a local result exists. Database schema bumped to
  **v6** with an additive `onUpgrade` migration (existing tables untouched).

### Fixed
- **Online fallback now works in release builds.** The `INTERNET` permission was
  only declared in the debug/profile manifests (Flutter template default), so
  release builds could not reach the provider — the connectivity check and HTTP
  request failed and the offline message showed immediately. `INTERNET` is now
  declared in the **main** manifest. The flow was also hardened to attempt the
  provider on every offline miss (connectivity is consulted only to classify a
  failure, so a false-negative probe can’t suppress the fallback), and the
  Dictionary word details now use the same hybrid path — so the online fallback
  behaves identically in **both** the PDF reader and Dictionary search.

### Notes
- Offline-first and non-blocking: PDF reading is never blocked; requests are
  de-duplicated (cache-first + provider-keyed caching + a DB primary key). New
  unit tests cover offline lookup, online fallback, cache insertion, cached
  lookup, the no-internet path, duplicate-cache prevention and response parsing.
  `flutter analyze` is clean and the full suite passes.

## [0.4.0] — 2026-07-25

Phase v0.4.0 — the offline **Grammar** learning module. A complete, offline
grammar course that plugs into the app through the existing `FeatureModule`
contract. No existing feature was changed; the module is entirely additive.

### Added
- **Grammar Home** (Material 3): instant, debounced search, category filters,
  **Continue learning**, **Recent topics**, **Favorites**, and all topics grouped
  by category with per-category completion counts.
- **Lesson screen**: explanation, rules, examples, notes, tips, common mistakes
  and **interactive multiple-choice practice questions** (tap to check, with
  explanations), plus a favorite toggle and a mark-complete action.
- **15 offline lessons** across four categories (Foundations; Verbs & Tenses;
  Speech & Connectors; Mechanics): Parts of Speech, Sentence Structure, Phrases,
  Clauses, Articles, Tenses, Subject–Verb Agreement, Modals, Active & Passive
  Voice, Conditional Sentences, Direct & Indirect Speech, Prepositions,
  Conjunctions, Punctuation and Common Errors — **60 practice questions** total.
- **Progress tracking**: completed lessons, in-progress (with furthest-read
  fraction) and recently-viewed, all reactive and stored locally.
- **Home entry & navigation**: the Grammar Home tile is now a live entry (was a
  “coming soon” placeholder); `GrammarModule` is a real, active module in the
  registry, contributing the `/grammar` and `/grammar/lesson/:id` routes.

### Changed
- Database schema bumped to **v5** with an additive `onUpgrade` migration that
  creates three tables — `grammar_lessons` (bulk-seeded once from a bundled JSON
  asset), `grammar_progress` and `grammar_favorites` — plus their indexes. All
  existing tables and data are untouched. The lesson body is stored as JSON, so
  new content fields can ship without a schema redesign; re-seeding never touches
  the user's progress or favorites.

### Notes
- 100% offline; the lesson content is original material under the app's MIT
  license. Covered by unit tests (data source, seeder, and content validated
  against the shipped asset) and a widget test for the interactive practice
  question. `flutter analyze` reports **0 issues** and the full suite passes.

## [0.3.4] — 2026-07-25

### Changed
- **Urdu meaning now appears directly below the English definition** on the
  Dictionary detail screen (previously it sat above the senses). It is still
  read from the **same** `TranslationRepository` (via `translationProvider(lang:
  'ur')`) that powers the reader's Translate popup — one shared offline dataset,
  no duplicate Urdu store. The card only shows when the word has an offline Urdu
  translation.

## [0.3.3] — 2026-07-24

Urdu meanings now appear **inside the Dictionary**, alongside the English
definition — using the very same translation repository as the reader's
Translate popup.

### Added
- **Urdu meaning card on the Word Details screen.** When a word exists in the
  offline Urdu translation data, its Urdu meaning is shown (right-to-left) above
  the English senses. Words with no Urdu simply omit the card.

### Changed
- The Dictionary and the PDF **Translate** feature now read Urdu from **one
  shared source** — the same `TranslationRepository`, via the same
  `translationProvider(lang: 'ur')` — so Urdu results are identical in both
  places (and share one first-run seed + cache). No separate Urdu database was
  created; the existing translation dataset and architecture are reused as-is.

### Notes
- Reader, database schema, translation seeding and the translation dataset are
  unchanged — this is a Dictionary-UI integration only. The cross-module link is
  through the Translation module's public repository/provider, so both modules
  stay independent.

Significantly expanded the offline **English → Urdu** dataset for English
learners and competitive-exam students. Data-only change — the translation
architecture, database schema, seeding process, reader and UI are all unchanged.

### Changed
- **English → Urdu coverage roughly doubled: 6,256 → 12,559 headwords**
  (~26,600 senses), with much stronger academic, newspaper and exam vocabulary
  (e.g. analysis → تَحْلِیل، تَجْزِیَہ · economy → مَعِیشَت، اِقْتِصاد ·
  parliament → مَجْلِس، پارْلِیمان · inflation → اِفْراطِ زَر، مہنگائی ·
  examination → اِمْتِحان، جائزہ · democracy → جَمْہُورِیَت).
- The data is now mined from **both** the English-Wiktionary translation tables
  **and** the Urdu-Wiktionary glosses (via kaikki.org), then merged and
  de-duplicated (diacritic-insensitive) — all still CC BY-SA 4.0.
- Bumped the bundled data-set version so existing installs re-seed once to pick
  up the larger set (settings and saved vocabulary are untouched).

### Notes
- No schema migration, no seeding-logic change: the same batched, streaming
  seeder ingests the larger asset. The other languages (fr/pt/hi/ar) are
  unchanged. Words still absent from Wiktionary show the graceful "no offline
  translation" state.

## [0.3.1] — 2026-07-24

**Urdu** is now a first-class offline translation language, prioritised for the
app's Pakistani audience. Additive only — no architecture change.

### Added
- **Offline English → Urdu translations** (6,256 headwords / ~10,800 senses),
  extracted from **English Wiktionary** (via kaikki.org, CC BY-SA 4.0) and merged
  into the bundled translation data set beside the existing FreeDict languages.
  Coverage is comparable to the French set; quality is human-curated
  (e.g. school → اِسْکُول، مَدْرَسَہ، مَکْتَب…).

### Changed
- **Urdu is the default translation language and is listed first** in the
  Settings picker, prioritising it for Pakistani users. All languages remain
  fully user-selectable; anyone can switch in Settings → Translation.
- Bumped the bundled translation data-set version, so existing installs re-seed
  once to pick up Urdu (the offline table is rebuilt; user settings/favourites
  are untouched).

### Notes
- The translation data set now combines two open sources, each redistributed
  under its own license: **FreeDict (GPL)** for French/Portuguese/Hindi/Arabic
  and **Wiktionary (CC BY-SA 4.0)** for Urdu. See
  `assets/translations/README.txt`. App code remains MIT.
- FreeDict has no English–Urdu pair, which is why Urdu is sourced from
  Wiktionary; the modular pipeline ingests both into the same
  `translation_entries` table with no schema or code-path changes.

## [0.3.0] — 2026-07-24

Reader word-selection **Translate** action — offline, beside "Look up". No
existing feature or the Dictionary module was modified; everything is additive.

### Added
- **Translate word action** in the reader's selection toolbar, beside the
  existing **Look up**. Both appear only for **single-word** selections. The
  toolbar now renders one button per registered `WordAction`, so this was added
  purely by contributing an action to the shared registry — the reader was not
  special-cased.
- **Lightweight translation popup**: shows the original word, its translated
  meaning in the user's selected language (when available), a **Copy** button,
  and — only when a translation exists — a **Save to Vocabulary** button (saves
  into the shared Dictionary favorites via its public API).
- **Offline translation data**: a new `translation_entries` table (schema
  **v4**, additive migration) seeded once, on first use, from a bundled data set
  of **129,506 entries** across **French, Portuguese, Hindi and Arabic**
  (FreeDict, GPL). Lookups use a `(lang_code, word_lower)` composite index.
- **Translation language** setting (Settings → Translation): choose the target
  language. Stored as a key-value setting (no schema change for the preference).

### Notes
- Offline coverage is per the bundled data set; when a word or language has no
  entry, the popup says so clearly and still offers Copy. Adding a language is a
  data + one-list-entry change — no code changes to the reader.
- Translation data is licensed **GPL** (FreeDict); the app code stays MIT. The
  license is bundled at `assets/translations/TRANSLATIONS_LICENSE.txt`.
- The Dictionary module is unchanged; "Save to Vocabulary" reuses its public
  repository so the two features share one vocabulary store.

## [0.2.1] — 2026-07-24

Rebrand to **Sapiora** and regression fixes for PDF import and discovery. No
architecture change; the database and all existing data are preserved
(additive migration only).

### Changed
- **Rebranded Lexiora → Sapiora** across all visible surfaces: app name,
  launcher label, About screen, in-app copy, the root widget, and all docs.
  Internal identifiers are intentionally unchanged for backward compatibility —
  the Android `applicationId` (`com.lexiora.app`), the Dart package name
  (`lexiora`), the database file (`lexiora`) and the platform channel
  (`lexiora/platform`) all stay the same, so existing installs keep their data.

### Added
- **Manual “Import PDF” restored** — a clearly visible Import button (FAB on the
  Home and Library screens). Opens the system file picker with **multi-select**,
  copies the chosen PDFs into app storage, and they appear in the Library
  **immediately** (no restart). Works even without all-files access.
- Manual import and automatic discovery now **coexist**, sharing one de-dup key
  (`fileName|fileSize`, rename-stable) so a file that was both imported and
  auto-discovered is never listed twice.
- `documents.managed_file` column (schema **v3**, additive migration):
  distinguishes app-imported copies (deleted with the document) from in-place
  auto-discovered files (the user's own file is never deleted).

### Fixed
- **Auto-discovery missed many PDFs.** The filesystem walk previously skipped the
  entire `Android/` tree, which excluded `Android/media/…` where messaging apps
  (e.g. WhatsApp Documents) keep PDFs. It now traverses everything except the
  genuinely private `Android/data` and `Android/obb`, raises the recursion depth
  cap (25), and wraps each directory/entry in its own try/catch so a single
  unreadable folder can no longer abort the whole scan. Result: substantially
  more valid PDFs are discovered.

## [0.2.0] — 2026-07-24

Phase 2.1 — the **offline Dictionary engine**. A fast, fully offline dictionary
that also plugs into the PDF reader. No existing feature was changed; the module
is entirely additive.

### Added
- **Offline dictionary database.** A new `dictionary_entries` table (schema v2)
  seeded once, on first use, from a bundled data set of **163,201 real entries
  across 107,946 headwords** (Wordset Dictionary, CC BY-SA 4.0). Each entry has
  word, part of speech, meaning and (where available) an example sentence; the
  schema also carries an IPA field for future data. Seeding streams a
  gzip-compressed asset in batches on the database isolate, so the UI never
  blocks; a one-time progress screen is shown.
- **Fast search.** Case-insensitive, index-backed prefix search (`word_lower`
  index + range scan) with results grouped by headword, exact matches first.
  Instant-as-you-type with a 180 ms debounce, stale-response cancellation, and
  lazy pagination (infinite scroll).
- **Dictionary screen** (Material 3): search bar with clear button, plus
  distinct loading, empty (“start typing”), no-result and results states. When
  the search box is empty it lists your saved words. A one-time “Preparing the
  dictionary” progress state covers first-run seeding.
- **Word details screen**: headword, IPA (when present), all senses (each with
  part of speech, meaning and example) and a favorite (star) toggle.
- **Favorites (saved vocabulary).** Add/remove from favorites anywhere (search
  tiles, details, reader popup); persisted locally in a dedicated
  `dictionary_favorites` table so they survive any future dictionary re-seed.
- **Reader integration.** Selecting a single word in the PDF reader now shows a
  “Look up” action that opens a lightweight popup with the word, its meaning and
  a single **⭐ Save to Vocabulary** button — nothing else. This is wired through
  the existing `WordActionRegistry`, so the reader stays fully decoupled from the
  dictionary.
- Dictionary data attribution dialog (CC BY-SA 4.0), and the license bundled at
  `assets/dictionary/DICTIONARY_LICENSE.txt`.

### Changed
- Database schema bumped to **v2** with an additive `onUpgrade` migration that
  creates the two dictionary tables and their indexes. All Phase 1 tables and
  data are untouched.
- The Dictionary Home tile is now a live entry (was a “coming soon” placeholder)
  and `DictionaryModule` is a real, active module in the registry.

### Notes
- The bundled data set has no IPA pronunciations (the source lacks them); the UI
  hides the IPA line when absent. The schema and details screen already support
  IPA for a future data set — swapping in a larger/richer set is a bundled-asset
  change plus a one-line version bump (favorites are unaffected).

## [0.1.5] — 2026-07-24

Phase 1.1 — fully automatic, zero-tap PDF discovery. The library now behaves
like Adobe Acrobat / Xodo: every PDF on the device is listed automatically, with
no "Import" or "Find on device" buttons anywhere in the app.

### Changed
- **Discovery is now fully automatic and reference-in-place.** On opening the
  Library (and on pull-to-refresh) Sapiora scans the device and lists every PDF,
  referencing each file at its real path — nothing is copied into the app. New
  files on the device appear on the next scan; removing a document deletes only
  the library entry, never the underlying file.
- **All-files access** (`MANAGE_EXTERNAL_STORAGE`) is now requested once, the way
  Acrobat/Xodo do, so the whole device can be enumerated. On Android 10 and below
  the legacy read permission is used instead (capped at API 29). The Library
  shows a clear "Allow access to your files" state with a single Grant button
  when access hasn't been granted yet.

### Removed
- The manual **Import PDF** button (Home + Library FABs) and the **Find on
  device / Scan a folder** menu — discovery is automatic, so they are gone.
- Dead code paths behind those features: the single-file SAF picker, the
  MediaStore scan, the folder-tree (SAF) scan, the content-URI cache copy, the
  `FileImportService` / `StoragePaths` services, the now-unused
  `androidx.documentfile` dependency, and the title/size de-dup helpers.

### Fixed
- Removed two leftover Flutter-template `TODO` comments in the Android Gradle
  config (application ID and release signing), replaced with accurate notes.

### Notes
- `MANAGE_EXTERNAL_STORAGE` is a Google Play **sensitive** permission: shipping
  on Play requires a declaration justifying all-files access (a file-manager /
  document-reader use case qualifies). Direct APK / sideload distribution is
  unaffected. See README → "Permissions & Play Store".

## [0.1.4] — 2026-07-24

Phase 1.1 — automatic PDF discovery fixed and made reliable.

### Fixed
- **"Find on device" always reported "No new PDF found".** Two defects in the
  MediaStore scan: (1) it filtered on `MIME_TYPE = 'application/pdf'`, but
  MediaStore frequently leaves MIME_TYPE null for documents, so PDFs were
  missed; (2) it rejected rows via `File(path).canRead()`, which is always false
  under scoped storage (Android 10+), filtering out every result. The scan now
  matches by MIME type **or** `.pdf` extension, returns content URIs, and never
  touches raw file paths.

### Added
- **SAF folder scan (reliable on Android 11+).** Because `MediaStore.Files`
  cannot list arbitrary PDFs on Android 11+ without All-Files-Access, a
  "Scan a folder…" action — and an automatic fallback when the device scan finds
  nothing — lets the user grant a folder (e.g. Downloads) via the Storage Access
  Framework; Sapiora recursively finds PDFs there and imports them by copying
  bytes through `ContentResolver` (works under scoped storage).
- Detailed discovery logging (scanned count, each candidate URI, indexed count)
  under the `Sapiora` log tag.

### Changed
- Discovery copies files via content URIs instead of raw file paths, so it works
  on every Android version. Added the `androidx.documentfile` dependency for
  folder-tree traversal.

## [0.1.3] — 2026-07-24

Phase 1.1 hotfix — the reader initialization crash (pinpointed from the
on-device stack trace).

### Fixed
- **Reader crashed opening every PDF with `Null check operator used on a null
  value`.** The device trace showed `PdfTextSearcher._registerForDocumentChanges`
  throwing during `PdfrxReaderController` construction in `initState`. Root
  cause: `PdfTextSearcher(pdf)` was created **eagerly**, but its constructor
  runs `controller!.document.events…`, and pdfrx's `controller` getter returns
  `null` until the `PdfViewer` is attached and ready — so the `!` threw before
  the reader could mount (in **both** debug and release, which is why every PDF
  failed). Fix: the `PdfTextSearcher` is now created **lazily**, only after the
  viewer reports ready (`onViewerReady`); the match-highlight paint callback is
  wired in on the post-ready rebuild via a `ValueListenableBuilder(isReady)`.

Together with the v0.1.2 native-library extraction fix, the reader load path is
now correct end to end.

## [0.1.2] — 2026-07-24

Phase 1.1 hotfix — the **actual root cause** of the reader failure.

### Fixed
- **Every PDF failed to open in release builds (root cause found & fixed).**
  Evidence from the built APK showed `libpdfium.so` was `Stored` (uncompressed,
  unextracted) because release defaults to `extractNativeLibs=false`. pdfrx
  loads PDFium via `DynamicLibrary.open('libpdfium.so')` (bare name), which
  cannot resolve an unextracted in-APK library at runtime — so it threw during
  render (shown by the v0.1.1 diagnostic screen). Fix: `useLegacyPackaging =
  true` for `jniLibs` in `android/app/build.gradle.kts`, so native libraries are
  extracted at install and `dlopen` succeeds. Rebuilt APK confirms `libpdfium.so`
  is now `Deflated` (extractable). Debug builds were unaffected (debuggable apps
  already extract native libs), which is why the bug was release-only.

### Changed
- The global error screen now shows the full exception + stack trace (scrollable
  and selectable) so any future rendering failure is diagnosable directly on the
  device.

## [0.1.1] — 2026-07-24

Phase 1.1 — critical bug fixes, stability & polish. No new (Phase 2) modules.

### Fixed
- **Reader blank screen (critical):** the pdfrx viewer was rebuilt on every
  reader rebuild. It now uses a cached document ref (rebuilds never reload), an
  always-present AppBar in every state, in-viewer loading/error banners, a
  pre-open file-existence/size check, and a full error page with Retry/Back.
- **Never blank:** added a global `ErrorWidget.builder`, `FlutterError.onError`
  and a guarded zone in `main`, plus structured logging (navigation, file
  checks, PDF load) — no failure renders an unexplained blank/grey screen.
- **Permissions (critical):** declared `READ_EXTERNAL_STORAGE` (maxSdkVersion
  32) and implemented a real, version-aware request flow, fixing the previous
  "No permissions requested" on Android ≤ 12L. On Android 13+, storage
  permission does not apply — discovery uses MediaStore/SAF. `MANAGE_EXTERNAL_STORAGE`
  is deliberately never requested (Play-compliant).

### Added
- **Automatic PDF discovery:** a native MediaStore scan (`scanPdfs`) enumerates
  device PDFs; a **Refresh Library** action indexes new ones into the local
  database, de-duplicated, with manual import still available.
- **Import de-duplication:** re-importing an existing PDF is detected and
  reported instead of creating a duplicate.
- **Library:** search, sort (name / import date / last opened / file size), and
  richer empty states.
- **Settings:** Keep screen awake, Auto-resume.

### Notes
- Discovery/permission/rendering **runtime** behavior is verified on-device by
  the user; the build sandbox has no emulator. See `docs/TESTING_REPORT.md`.

## [0.1.0] — 2026-07-24

Phase 1 — the offline-first PDF study reader and the modular foundation.

### Added
- **Project foundation**
  - Feature-first Clean Architecture (domain / data / presentation) with a strict dependency rule.
  - Modular composition via a single `FeatureModule` contract driving DI (GetIt), routing (GoRouter) and Home tiles.
  - Material 3 theming (light/dark/system) with adjustable font scale.
  - Reactive local database with Drift (SQLite); one offline source of truth.
  - `Result`/`Failure` error model with a `guard()` boundary helper.
- **Library**
  - Import PDFs via the Android system picker (no storage permission required).
  - All / Recent / Favorites views, category filtering, rename, favorite, and delete (with full cleanup of related data).
- **Reader** (pdfrx / PDFium behind a swappable `PdfEngine` abstraction)
  - Fast lazy rendering tuned for large (500+ page) documents.
  - Vertical & horizontal reading, zoom, smooth navigation, go-to-page.
  - Day / Sepia / Night reading modes.
  - Full-text in-document search with match navigation.
  - Remembers last page; saves reading progress and history; "Continue reading" on Home.
- **Studying**
  - Highlights & underlines in multiple colors — create from selection, recolor, remove.
  - Notes attached to a page or to a specific text selection; view/edit/delete.
  - Bookmarks for a page or a selection.
  - Copy selected text; per-document Bookmarks/Notes/Highlights panel.
- **Home & Settings**
  - Premium dashboard with a search entry, Continue Reading, Recent, Favorites and module "Explore" tiles.
  - Settings: theme, font size, reading direction, reading mode, default highlight color, and backup/restore placeholders.
  - Responsive layouts from phones to tablets; subtle animations.
- **Future-proofing**
  - Prepared tap-on-word extension point (`WordAction` + `WordActionRegistry`) — defined, not implemented.
  - Compiling placeholder modules for Dictionary, Translation, Grammar, Vocabulary, Flashcards, Quiz, Admin, AI Assistant and Cloud Sync — each already plugged into the app.
- **Tooling**
  - Unit tests for domain logic; zero-issue `flutter analyze`.
  - GitHub Actions CI: analyze, test, build a release APK, upload it as an artifact and publish it to the `v0.1.0` release.

[0.1.0]: https://github.com/OWNER/Sapiora/releases/tag/v0.1.0

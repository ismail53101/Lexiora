# Changelog

All notable changes to Sapiora are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

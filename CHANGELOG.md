# Changelog

All notable changes to Lexiora are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.5] — 2026-07-24

Phase 1.1 — fully automatic, zero-tap PDF discovery. The library now behaves
like Adobe Acrobat / Xodo: every PDF on the device is listed automatically, with
no "Import" or "Find on device" buttons anywhere in the app.

### Changed
- **Discovery is now fully automatic and reference-in-place.** On opening the
  Library (and on pull-to-refresh) Lexiora scans the device and lists every PDF,
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
  Framework; Lexiora recursively finds PDFs there and imports them by copying
  bytes through `ContentResolver` (works under scoped storage).
- Detailed discovery logging (scanned count, each candidate URI, indexed count)
  under the `Lexiora` log tag.

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

[0.1.0]: https://github.com/OWNER/Lexiora/releases/tag/v0.1.0

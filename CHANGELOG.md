# Changelog

All notable changes to Lexiora are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

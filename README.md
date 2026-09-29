# Sapiora

**A premium, offline-first study & language-learning platform for Android — built with Flutter.**

Sapiora Phase 1 is a production-grade **PDF study reader**: it **automatically finds the PDFs already on your device** *and* lets you **import your own** with the system file picker, then reads them with a fast PDFium-based engine and lets you highlight, underline, annotate, bookmark and take notes. Everything is stored locally on the device. No account. No internet. Your library never leaves your phone.

It is also the **foundation** of a larger platform. The architecture is designed so that nine planned modules (Dictionary, Translation, Grammar, Vocabulary Builder, Flashcards, Quiz, Admin, AI Assistant, Cloud Sync) can be added later **without modifying existing code**.

> Version `0.21.4` · Package `com.sapiora.app` · Flutter (stable) · Material 3

---

## ✨ Phase 1 features

**Reading**
- **Automatic device-wide PDF discovery** — every PDF on the device is found and listed on open (and on pull-to-refresh), Adobe Acrobat / Xodo style. Files are referenced **in place**; nothing is copied or uploaded.
- **Manual Import PDF** — a visible Import button (Home + Library) opens the system file picker with **multi-select**; imported files appear instantly. Import and auto-discovery coexist and never produce duplicates.
- Fast, lazy PDFium rendering tuned for large (500+ page) documents
- Vertical & horizontal reading directions
- Pinch/zoom, smooth page navigation, go-to-page
- Day / Sepia / **Night** reading modes
- Full-text **search inside the PDF** with match navigation
- **Remembers your last page** and reading progress; “Continue reading” on Home

**Studying**
- **Highlights & underlines** in multiple colors — edit, recolor and remove
- **Notes** attached to a page *or* to a specific text selection
- **Bookmarks** — bookmark a page, or bookmark a selection
- Copy selected text
- A per-document panel listing all bookmarks, notes and highlights
- **Look up a word in-reader** — select a single word to open a lightweight
  dictionary popup (word, meaning, and *Save to Vocabulary*)
- **Translate a word in-reader** — a *Translate* action beside *Look up* (single
  words) opens an offline translation popup (original word, translation in your
  chosen language, *Copy*, and *Save to Vocabulary*). **Urdu is first-class and
  the default** (prioritised for Pakistani users) with **~12,600 headwords**
  tuned for academic / newspaper / competitive-exam vocabulary; French,
  Portuguese, Hindi and Arabic are also offered. Set in Settings → Translation.

**Offline Dictionary** (Phase 2.1)
- **163,201 real entries** across 107,946 headwords, fully **offline** — bundled
  and loaded once on first use
- **Instant search**: index-backed, case-insensitive prefix search grouped by
  headword, debounced as you type, with lazy pagination
- **Word details**: part of speech, meaning(s), example sentences, IPA field
  (for future data)
- **Urdu meaning shown alongside the English definition** — read from the same
  offline translation repository as the reader's *Translate*, so Urdu is
  consistent everywhere (no separate Urdu database)
- **Favorites / saved vocabulary**, persisted locally and independent of the
  dictionary data

**Library & app**
- Beautiful Material 3 Home with search bar, Continue Reading, Recent, Favorites and category filtering
- Favorites, rename, delete (with full cleanup of related data)
- Light / Dark / System themes, adjustable font size, default highlight color
- **Responsive** layouts that scale from phones to tablets
- 100% offline · no account required

**Prepared, not implemented (Phase 1 scaffolding)**
- A **tap-on-word** extension point for future Dictionary / Translation / Grammar / Vocabulary actions
- Compiling placeholder modules for all nine future features, already plugged into the app

---

## 🧱 Tech stack

| Concern | Choice |
|---|---|
| Language / SDK | Dart 3.12 · Flutter 3.44 (stable) |
| UI | Material 3 |
| State management | Riverpod (`flutter_riverpod` ^3) |
| Dependency injection | GetIt ^9 |
| Navigation | GoRouter ^17 |
| Local database | Drift (SQLite) ^2 — reactive, type-safe |
| PDF engine | pdfrx ^2 (PDFium) — MIT, behind a swappable abstraction |
| PDF discovery | native platform channel (filesystem walk) + `permission_handler` (all-files access) |
| Dictionary data | Wordset Dictionary (CC BY-SA 4.0), bundled gzip JSON-Lines, seeded into Drift |
| Translation data | Urdu from Wiktionary/kaikki (CC BY-SA); fr/pt/hi/ar from FreeDict (GPL); bundled gzip JSON-Lines, seeded into Drift |
| Paths / storage | `path_provider`, `path` |

Every dependency is free and open source.

---

## 🏗️ Architecture at a glance

Sapiora uses **feature-first Clean Architecture** with a strict dependency rule (presentation → domain ← data; domain depends on nothing) and a modular composition model.

```
lib/
├── app/        # composition root: DI bootstrap, router, MaterialApp
├── core/       # cross-cutting: theme, database, reader-engine abstraction,
│               # module & navigation contracts, services, shared widgets
├── features/   # Phase 1 features (home, library, reader, annotations,
│               # notes, bookmarks, reading_progress, settings)
└── modules/    # compiling placeholders for the 9 future modules
```

The heart of the design is the **`FeatureModule`** contract: every feature and every future module registers its own dependencies (GetIt), routes (GoRouter) and Home tiles through it. Adding a module means implementing `FeatureModule` and appending it to a single list — **no existing file changes**.

Full details: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) · [`docs/FOLDER_STRUCTURE.md`](docs/FOLDER_STRUCTURE.md) · [`docs/FUTURE_INTEGRATION_GUIDE.md`](docs/FUTURE_INTEGRATION_GUIDE.md) · [`docs/ROADMAP.md`](docs/ROADMAP.md)

---

## 🚀 Getting started

### Prerequisites
- Flutter **3.44.x** (stable) — `flutter --version`
- Android SDK (API 26+) and a JDK 17 for building the Android app

### Setup

```bash
git clone https://github.com/<owner>/Sapiora.git
cd Sapiora

flutter pub get

# Generate the Drift database code (creates the *.g.dart files)
dart run build_runner build

# Run on a connected device / emulator
flutter run
```

### Quality checks

```bash
flutter analyze     # static analysis (should report no issues)
flutter test        # unit tests
```

### Build a release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> **Note on binaries:** to keep the repository free of binary blobs, the Gradle
> wrapper jar and the Drift `*.g.dart` files are **not committed** — they are
> generated by `flutter pub get` / `dart run build_runner build` / the Gradle
> wrapper step. CI does this automatically (see below). Locally, if
> `android/gradle/wrapper/gradle-wrapper.jar` is missing, run
> `cd android && gradle wrapper --gradle-version 9.1.0` once.

---

## 🤖 Continuous integration

[`.github/workflows/build.yml`](.github/workflows/build.yml) runs on every push to `main`:

1. Sets up JDK 17 + Flutter stable (with caching)
2. `flutter pub get`
3. `dart run build_runner build` (Drift codegen)
4. Regenerates the Gradle wrapper
5. `flutter analyze`
6. `flutter test`
7. `flutter build apk --release`
8. Uploads `app-release.apk` as a **workflow artifact**
9. Publishes it as an asset on a GitHub Release whose tag is derived from the pubspec version (e.g. **`v0.2.1`**)

The release APK is signed with the debug key by default (see `android/app/build.gradle.kts`); add a signing config there for Play Store distribution.

---

## 🔐 Permissions & Play Store

Sapiora lists the PDFs already on your device, so it needs to read them:

- **Android 11+ (API 30+):** requests **All files access**
  (`MANAGE_EXTERNAL_STORAGE`) once, on first open of the Library — the same
  capability Adobe Acrobat and Xodo use to browse a device's documents. Files
  are read **in place**; nothing is copied into the app and nothing leaves the
  device.
- **Android 10 and below (API ≤ 29):** uses the legacy `READ_EXTERNAL_STORAGE`
  permission (declared with `maxSdkVersion="29"`).

If access hasn't been granted, the Library shows an **"Allow access to your
files"** screen with a single Grant button — the app never crashes or shows a
blank screen.

> **Google Play note.** `MANAGE_EXTERNAL_STORAGE` is a Play **sensitive**
> permission. Publishing on Play requires a declaration justifying all-files
> access; a document reader / file-manager use case is an accepted
> justification, but review is stricter. **Direct APK / sideload distribution is
> unaffected.** If Play compliance without the declaration is required, the
> discovery layer is isolated behind `PdfDiscoveryService` +
> `PermissionService` and can be switched to a Storage-Access-Framework
> folder-grant model without touching the reader or library UI.

## 🗺️ Roadmap & versioning

Sapiora follows [Semantic Versioning](https://semver.org). Phase 1 shipped the
**v0.1.x** line; Phase 2.1 (the offline Dictionary) is **v0.2.0** (current). The
remaining planned modules and their versions are described in
[`docs/ROADMAP.md`](docs/ROADMAP.md). Changes are tracked in
[`CHANGELOG.md`](CHANGELOG.md).

## 📄 License

Application code is released under the [MIT License](LICENSE).

**Dictionary data** is provided by the [Wordset Dictionary](https://github.com/wordset/wordset-dictionary)
and is licensed under **CC BY-SA 4.0** (with portions derived from Princeton
WordNet 3.0). It is redistributed unmodified in structure under the same
license; the full text is bundled at `assets/dictionary/DICTIONARY_LICENSE.txt`
and surfaced in-app via the Dictionary screen's ⓘ button. The CC BY-SA license
applies to the bundled data only, not to the application code.

**Translation data** combines two open sources, each redistributed under its own
license: English→French/Portuguese/Hindi/Arabic from the
[FreeDict project](https://freedict.org) (**GPL**), and English→**Urdu** from
[Wiktionary](https://en.wiktionary.org) via [kaikki.org](https://kaikki.org)
(**CC BY-SA 4.0**, © Wiktionary contributors). See
`assets/translations/README.txt` and `TRANSLATIONS_LICENSE.txt`. These licenses
apply to the bundled data only, not to the application code.

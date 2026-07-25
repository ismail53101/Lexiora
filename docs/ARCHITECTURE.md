# Sapiora — Architecture

This document explains how Sapiora is structured, why, and how the pieces fit
together so that future modules can be added **without changing existing code**.

---

## 1. Guiding principles

- **Clean Architecture** — a strict, inward-pointing dependency rule.
- **Feature-first modularity** — code is organised by feature, not by layer.
- **SOLID** — small, single-responsibility classes; dependencies on abstractions.
- **Offline-first** — everything works locally; no network is required at runtime.
- **Open/Closed at the app level** — the app is *composed* from a list of modules;
  extending it is additive.

---

## 2. Layers & the dependency rule

Each feature is split into three layers:

```
presentation  ─▶  domain  ◀─  data
   (UI,            (entities,     (repository
   Riverpod)        use cases,     implementations,
                    repo interfaces) Drift, services)
```

- **domain** depends on *nothing* (pure Dart: entities, repository interfaces, use cases).
- **data** depends on **domain** (implements the repository interfaces using Drift/services).
- **presentation** depends on **domain** (calls use cases; never touches `data` directly).

The only glue that knows about all three is the **composition root** in `lib/app/`.

### Error handling
Instead of throwing across layers, use cases return a `Result<T>` (`Ok` | `Err`)
from `core/utils/result.dart`. The data layer throws typed `AppException`s; the
`guard()` helper (`core/utils/guard.dart`) converts them into `Failure` values.
This keeps error handling explicit and testable.

---

## 3. State management (Riverpod)

- **Queries** (reactive lists) are exposed as `StreamProvider`s that watch a
  repository's Drift `watch` streams (e.g. `allDocumentsProvider`).
- **Commands** are use-case objects exposed via `Provider`s; the UI calls them
  and folds the returned `Result` (e.g. `autoDiscoverProvider`,
  `togglePageBookmarkProvider`).
- Widgets are `ConsumerWidget` / `ConsumerStatefulWidget`.

Providers resolve their repositories/services from **GetIt**, so the reactive
layer stays decoupled from construction.

---

## 4. Dependency injection (GetIt)

`lib/app/di/injector.dart` exposes the singleton locator `sl`.
`injector_config.dart#configureDependencies()`:

1. registers cross-cutting **core singletons** (`AppDatabase`,
   `DeviceInfoService`, `PdfDiscoveryService`, `PermissionService`,
   `ScreenWakeService`, `WordActionRegistry`);
2. asks **every module** to register its own dependencies;
3. aggregates the Home destinations each module contributes.

Repositories are `registerLazySingleton`, so registration order never matters.

---

## 5. Navigation (GoRouter)

`lib/app/router/app_router.dart#createAppRouter()` builds a single `GoRouter`
by concatenating the `RouteBase`s that each module returns from
`FeatureModule.routes()`. Route paths/names live in `app/router/app_routes.dart`.
Adding a screen = a module returns another `GoRoute`; the router file never changes.

---

## 6. Persistence (Drift / SQLite)

One Drift database (`core/database/app_database.dart`) holds all tables
(`documents`, `categories`, `bookmarks`, `highlights`, `notes`,
`reading_progress`, `reading_sessions`, `settings`). Rationale:

- a single SQLite file = one offline source of truth;
- Drift gives type-safe queries and **reactive `watch()` streams** that feed
  Riverpod directly;
- each feature's repository owns its queries, so features stay independent.

Annotation geometry is stored as **normalized rects** (0..1 of the page) via a
`TypeConverter`, so highlights/notes stay aligned at any zoom and are never
written into the PDF. New tables for future modules are added here with a bumped
`schemaVersion` + a migration step; existing tables are never rewritten.

---

## 7. The modular extension mechanism (the important part)

Every feature and every future module implements one contract:

```dart
abstract class FeatureModule {
  String get id;
  String get name;
  void registerDependencies(GetIt getIt);              // DI
  List<RouteBase> routes(GetIt getIt) => const [];      // navigation
  List<HomeDestination> homeDestinations(GetIt getIt) => const []; // Home tiles
}
```

The app is composed from **one list** — `lib/app/di/module_registry.dart`:

```dart
final List<FeatureModule> appModules = [
  HomeModule(), LibraryModule(), ReaderModule(), SettingsModule(),
  ReadingProgressModule(), AnnotationsModule(), NotesModule(), BookmarksModule(),
  // future modules (placeholder scaffolds):
  DictionaryModule(), TranslationModule(), GrammarModule(), VocabularyModule(),
  FlashcardsModule(), QuizModule(), AiAssistantModule(), AdminModule(),
  CloudSyncModule(),
];
```

Bootstrap iterates this list for DI, routing and Home tiles:

```
configureDependencies() ─▶ for each module: registerDependencies(sl)
createAppRouter()       ─▶ for each module: routes(sl)  ──▶ GoRouter
HomeDestinationRegistry ─▶ for each module: homeDestinations(sl)
```

> **To add a feature: implement `FeatureModule`, append it to `appModules`.**
> Nothing else changes. That is the Open/Closed Principle, structurally enforced.

---

## 8. Swappable PDF engine

The reader depends only on abstractions in `core/reader_engine/`:

- `PdfEngine` — `createController()`, `buildViewer()`, `readDocumentInfo()`
- `PdfReaderController` — page/zoom/search/selection, exposed as `ValueListenable`s
- `PdfViewConfig`, `ReaderOverlayRect`, `PdfTextSelectionData` — engine-neutral models

The pdfrx implementation lives entirely in `features/reader/data/`
(`PdfrxEngine`, `PdfrxReaderController`, `PdfrxReaderView`). It is the **only**
place that imports `pdfrx`. Swapping to another renderer means providing a new
`PdfEngine` binding in `ReaderModule.registerDependencies` — no feature/UI change.

---

## 9. Tap-on-word extension point (multi-action)

`core/reader_engine/word_action.dart` defines `WordAction` and a
`WordActionRegistry` singleton (registered in DI). Modules contribute actions at
startup: the **Dictionary module** registers `dictionary.define` ("Look up",
priority 10) and the **Translation module** registers `translation.translate`
("Translate", priority 20). When a single word is selected, the reader's
selection toolbar renders **one button per registered action** (ordered by
priority) and invokes the chosen one, which opens that module's popup.

Crucially, the reader depends only on this **core abstraction** — it never
imports the dictionary or translation modules, and it was not special-cased to
add Translate: contributing another `WordAction` is all it took. Future language
modules (synonyms, grammar, …) register further actions the same way, with no
change to the reader. This is the Open/Closed Principle at the interaction
layer.

---

## 10. Offline & security posture

- No runtime network calls; no account. Everything stays on the device.
- **Storage access for discovery.** To list the PDFs already on the device,
  Sapiora requests **All files access** (`MANAGE_EXTERNAL_STORAGE`) on Android
  11+, and the legacy read permission on Android ≤ 10. Files are read **in
  place** — never copied into the app and never uploaded. Discovery is isolated
  behind two swappable services: `PdfDiscoveryService` (the native filesystem
  walk over the `lexiora/platform` channel) and `PermissionService` (the
  version-aware grant flow + opening the OS app-settings page). Because nothing
  else in the app touches these, the whole storage strategy can be replaced
  (e.g. with a Play-review-friendly SAF folder grant) without changing the
  reader or library UI.

---

## 11. Performance

- Lazy, virtualized rendering via pdfrx (PDFium) — suitable for 500+ page PDFs.
- Per-page text extraction on demand for search rather than loading all text.
- Reactive Drift streams update only what changed; lists use `builder`s.
- `const` widgets and normalized-rect overlays keep scrolling smooth.

---

## 12. Testing

Domain logic is covered by fast, dependency-free unit tests (`test/`) using
hand-written fakes — no database or platform channels required, so they run in
CI in seconds. See `test/features/**` and `test/core/result_test.dart`.

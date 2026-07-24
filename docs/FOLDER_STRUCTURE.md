# Lexiora — Folder Structure

A guided tour of the repository. The golden rule: **`domain` never imports
`data` or `presentation`**, and features never import each other's internals —
they collaborate only through domain interfaces and shared `core` contracts.

```
lexiora/
├── android/                     # Android host project (Kotlin DSL, AGP 9, minSdk 26)
│   └── app/src/main/res/        # Vector adaptive launcher icon (no raster assets)
├── assets/icon/                 # Brand icon source (optional)
├── docs/                        # This documentation set
├── test/                        # Unit tests (domain use cases, entities, Result)
├── .github/workflows/build.yml  # CI: analyze, test, build & release the APK
│
└── lib/
    ├── main.dart                # Entry point: init pdfrx, DI, router, runApp
    │
    ├── app/                     # ── Composition root ──────────────────────────
    │   ├── app.dart             # LexioraApp: MaterialApp.router + theme + text scale
    │   ├── di/
    │   │   ├── injector.dart         # the GetIt instance `sl`
    │   │   ├── injector_config.dart  # configureDependencies(): core + modules
    │   │   └── module_registry.dart  # THE list of app modules (edit to add one)
    │   └── router/
    │       ├── app_router.dart       # createAppRouter(): routes from all modules
    │       └── app_routes.dart       # route path/name constants
    │
    ├── core/                    # ── Cross-cutting building blocks ─────────────
    │   ├── constants/           # app & database constants
    │   ├── error/               # Failure (values) + AppException (thrown)
    │   ├── usecase/             # UseCase / StreamUseCase base contracts
    │   ├── utils/               # Result<T>, typedefs, guard()
    │   ├── models/              # shared value objects (NormalizedRect)
    │   ├── module/              # FeatureModule contract (the plug-in seam)
    │   ├── navigation/          # HomeDestination + registry
    │   ├── reader_engine/       # engine-AGNOSTIC PDF abstraction:
    │   │   ├── pdf_engine.dart          # PdfEngine + PdfViewConfig
    │   │   ├── pdf_reader_controller.dart# PdfReaderController + PdfSearchState
    │   │   ├── reader_models.dart        # selection/overlay/enums/value objects
    │   │   └── word_action.dart          # tap-on-word extension point (Phase 1: empty)
    │   ├── theme/               # Material 3 light/dark theme + brand colors
    │   ├── responsive/          # breakpoints for phone/tablet layouts
    │   ├── database/            # Drift database, tables, converters
    │   ├── services/            # PdfDiscoveryService, PermissionService, DeviceInfoService, ScreenWakeService
    │   └── widgets/             # shared widgets (EmptyState, SectionHeader, …)
    │
    ├── features/                # ── Phase 1 features (feature-first) ──────────
    │   ├── home/                # dashboard: search, continue reading, recent, explore
    │   ├── library/             # automatic discovery, list, recent, favorites, categories
    │   ├── reader/              # the PDF reader (pdfrx impl lives in data/)
    │   ├── annotations/         # highlights & underlines
    │   ├── notes/               # page- and selection-anchored notes
    │   ├── bookmarks/           # page & selection bookmarks
    │   ├── reading_progress/    # last page, %, history, continue reading
    │   └── settings/            # theme, font size, reading direction, colors, backup*
    │
    └── modules/                 # ── Future modules (compiling scaffolds only) ──
        ├── dictionary/          # }
        ├── translation/         # }
        ├── grammar/             # }  Each implements FeatureModule with NO behavior.
        ├── vocabulary/          # }  They already plug into DI, routing and the
        ├── flashcards/          # }  Home "Explore" tiles ("coming soon"), proving
        ├── quiz/                # }  the architecture end-to-end.
        ├── ai_assistant/        # }
        ├── admin/               # }
        └── cloud_sync/          # }
```

### Anatomy of a feature

Every feature under `lib/features/<name>/` follows the same shape:

```
<feature>/
├── domain/
│   ├── entities/         # plain immutable models (Equatable)
│   ├── repositories/     # abstract repository interfaces
│   └── usecases/         # business operations (return Result / Stream)
├── data/
│   └── repositories/     # Drift/service-backed implementations
├── presentation/
│   ├── providers/        # Riverpod providers (queries + command use cases)
│   ├── pages/            # screens
│   └── widgets/          # feature-specific widgets
└── <feature>_module.dart # FeatureModule: wires DI + routes + Home tiles
```

The `reader` feature additionally contains `data/pdfrx_*.dart` — the **only**
files in the codebase that import `pdfrx`.

\* Backup/Restore in Settings are intentional Phase 1 placeholders.

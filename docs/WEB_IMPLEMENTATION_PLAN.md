# Sapiora Web implementation plan

## Decision

Sapiora Web will be a local-only browser application in the existing Flutter repository. It will reuse the same branding, bundled learning content, domain models, and compatible business logic as Android. It will not add accounts, cloud sync, export, or import.

The Android target remains unchanged while web support is introduced behind platform-specific adapters and conditional imports.

## Product promise

The web target should provide the same useful Sapiora experience wherever browser capabilities allow it: PDF reading, search, reading progress, notes, highlights, underlines, bookmarks, dictionary, translations, vocabulary, flashcards, quizzes, grammar, settings, themes, and other bundled study content.

User-created data is stored locally in the current browser and device. Android and Web data are intentionally separate because this phase does not include synchronization or migration.

## Platform substitutions

| Android capability | Web implementation |
|---|---|
| Automatic device-wide PDF discovery | Explicit browser file picker and drag-and-drop import |
| Android storage permissions | Browser file access selected by the user |
| Drift database backed by native SQLite | Web-compatible local persistence using IndexedDB or SQLite WASM, selected after a small compatibility spike |
| Native PDFium/pdfrx integration | Browser-supported PDF rendering adapter with the same reader domain contract |
| Native text-to-speech | Browser Speech Synthesis adapter with a no-op fallback |
| Android notifications | Browser notifications only where permission and support exist; no hard dependency |
| Native file sharing | Browser download/share APIs with graceful fallback |
| Device and screen-wake services | Browser capability checks and no-op fallbacks |
| Native Google Drive integration | Deferred until a web-specific browser OAuth flow is intentionally added |

## Non-breaking architecture

1. Preserve existing Android implementations.
2. Define or reuse interfaces at the domain/core boundary.
3. Add web implementations through conditional imports or platform registrations.
4. Keep Android-only code out of web-compiled files.
5. Make web startup independent from Android permission prompts, native notifications, and device-wide PDF discovery.
6. Keep bundled assets shared between Android and Web.

## Delivery phases

### Phase 1: web target and startup

Add the Flutter Web target, browser metadata, responsive shell, routing, theme support, and a web-safe composition root. The first web build must start without invoking Android permissions, native notifications, or unsupported plugins.

### Phase 2: local storage and PDF reading

Add browser-local persistence and a browser file picker. Port the library, reader, document metadata, reading progress, search, bookmarks, notes, highlights, and underlines. Validate that large PDFs fail gracefully instead of producing a blank page.

### Phase 3: bundled study content

Enable the existing dictionary, translations, grammar, vocabulary, flashcards, quizzes, and other bundled datasets in the web target. Keep seeding and lookup logic platform-neutral; replace only file-system and compression access that prevents web compilation.

### Phase 4: optional browser capabilities

Add browser-safe implementations for speech, AI/current affairs requests, downloads, share links, and notifications where supported. Unsupported capabilities must degrade visibly and safely rather than blocking startup.

### Phase 5: verification and release

Run Android analysis/tests and Web analysis/build independently. Add CI steps for a web build without changing the Android release job. Test desktop and mobile browser layouts, file selection, local persistence, reader behavior, and feature fallbacks.

## Data and privacy boundary

The APK binary does not contain a recoverable copy of a user's private Drift database. Since sync and import/export are intentionally excluded, the Web app will contain the same built-in Sapiora content but will not display Android-created PDFs, notes, bookmarks, highlights, or progress.

Clearing browser storage can remove local Web data. The UI should communicate this when local storage is first used.

## Acceptance criteria for the first implementation

- Android source files and Android startup behavior remain unchanged.
- `flutter build web` can compile the web target without Android-only imports leaking into the web build.
- Sapiora Web launches without Android permission or notification prompts.
- The web shell uses Sapiora branding and responsive navigation.
- Unsupported browser features use safe fallbacks instead of crashing the app.

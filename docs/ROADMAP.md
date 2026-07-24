# Lexiora — Roadmap

Lexiora ships in phases. Phase 1 delivers a complete, offline PDF study reader
and the architecture for everything that follows. Each future module plugs into
the existing app via the `FeatureModule` contract (see
[`FUTURE_INTEGRATION_GUIDE.md`](FUTURE_INTEGRATION_GUIDE.md)) — no rewrites.

Versioning follows [SemVer](https://semver.org): new modules are **minor**
releases (`0.x`) until a `1.0.0` feature-complete milestone.

---

## ✅ Phase 1 — `v0.1.0` (current)

Offline PDF study reader.

- Import, read (zoom, scroll direction, night mode, search, go-to-page)
- Remember last page, reading progress & history, continue reading
- Highlights & underlines (multi-color, edit, remove), notes (page & selection),
  bookmarks (page & selection), copy
- Library (recent, favorites, categories), Material 3 UI, dark/light, tablet layouts
- 100% offline · no account · no unnecessary permissions
- Modular foundation + compiling scaffolds for all future modules
- Prepared tap-on-word extension point

---

## 🔜 Future modules

Delivery order is indicative; each is independent thanks to the module system.

| Version | Module | Summary |
|---|---|---|
| `v0.2.0` | **Dictionary** | Offline/online word definitions; first tap-on-word action |
| `v0.3.0` | **Multi-language Translation** | Selection & word translation across languages |
| `v0.4.0` | **Grammar** | Grammar explanations and checks for selected text |
| `v0.5.0` | **Vocabulary Builder** | Save words from the reader into personal lists |
| `v0.6.0` | **Flashcards** | Spaced-repetition review built from vocabulary |
| `v0.7.0` | **Quiz System** | Auto-generated quizzes from documents & vocabulary |
| `v0.8.0` | **AI Assistant** | Ask questions about the current text; summaries |
| `v0.9.0` | **Admin Panel** | Back-office/content management (internal) |
| `v0.10.0` | **Cloud Sync** | Optional, opt-in backup & multi-device sync |
| `v1.0.0` | **Platform GA** | Hardened, localized, store-ready release |

### Cross-cutting later work
- Signing config & Play Store release pipeline
- Localization (the UI is structured for it)
- iOS/desktop targets (pdfrx and the architecture already support them)
- Accessibility polish and automated widget/integration tests

---

## Design commitments carried forward
- Offline-first remains the default; Cloud Sync is strictly optional.
- Each module owns its data, routes and UI; the core stays thin.
- Adding a module never edits another module.

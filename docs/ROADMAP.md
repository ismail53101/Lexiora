# Sapiora — Roadmap

Sapiora ships in phases. Phase 1 delivers a complete, offline PDF study reader
and the architecture for everything that follows. Each future module plugs into
the existing app via the `FeatureModule` contract (see
[`FUTURE_INTEGRATION_GUIDE.md`](FUTURE_INTEGRATION_GUIDE.md)) — no rewrites.

Versioning follows [SemVer](https://semver.org): new modules are **minor**
releases (`0.x`) until a `1.0.0` feature-complete milestone.

---

## ✅ Phase 1 — `v0.1.x` (current: `v0.1.5`)

Offline PDF study reader.

- **Automatic device-wide PDF discovery** (no import / no file picker; files read
  in place), read (zoom, scroll direction, night mode, search, go-to-page)
- Remember last page, reading progress & history, continue reading
- Highlights & underlines (multi-color, edit, remove), notes (page & selection),
  bookmarks (page & selection), copy
- Library (recent, favorites, categories), Material 3 UI, dark/light, tablet layouts
- 100% offline · no account · nothing ever leaves the device
- Modular foundation + compiling scaffolds for all future modules
- Prepared tap-on-word extension point

### Phase 1.x release hardening (planned)
- Production upload keystore + Play signing config
- Google Play "All files access" declaration **or** an optional SAF
  folder-grant discovery mode for stricter Play compliance

---

## ✅ Phase 2.1 — `v0.2.0` (current): Offline Dictionary

Shipped. A fully offline dictionary engine as an independent module.

- Bundled offline data set (163,201 entries / 107,946 headwords; Wordset,
  CC BY-SA 4.0), seeded once into `dictionary_entries` (schema v2)
- Instant, index-backed prefix search grouped by headword; debounced + paged
- Word details (part of speech, meanings, examples, IPA field for future data)
- Favorites / saved vocabulary, stored independently of the dictionary data
- Reader tap-on-word → lightweight "Look up" popup (word, meaning, Save to
  Vocabulary) via the core `WordActionRegistry` — the first realized tap-on-word
  action

---

## 🔜 Future modules

Delivery order is indicative; each is independent thanks to the module system.

| Version | Module | Summary |
|---|---|---|
| ~~`v0.2.0`~~ | ~~**Dictionary**~~ | ✅ Shipped — offline word definitions; first tap-on-word action |
| ~~`v0.3.0`~~ | ~~**Multi-language Translation**~~ | ✅ Shipped — offline reader "Translate" word action (French/Portuguese/Hindi/Arabic) |
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

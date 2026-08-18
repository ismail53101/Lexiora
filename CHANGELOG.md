# Changelog

All notable changes to Sapiora are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.23.1] — 2026-08-15

### Fixed

- **Nonsense usage sentences eliminated from the Dictionary word details.**
  WordNet's synset examples frequently illustrate a *different* word than the
  headword (e.g. `elevate` → "John was kicked upstairs when a replacement was
  hired"), which read as nonsense in English and machine-translated into
  nonsense Urdu. The Usage card now only ever shows a sentence that actually
  contains the headword (or one of its inflections — plurals, -ed/-ing,
  y→ies, plus an irregular-verb table so "We came back…" still matches
  "come back"); otherwise the card is hidden instead of showing garbage.
  This covers all ~8,400 affected words — including words users have already
  seen on installed builds, since the check runs at render time, not at seed
  time. Copy-to-clipboard uses the same filtered resolution so copied text
  matches what's displayed.
- **Curated example sentences + Urdu for 112 words whose old usage lines
  were wrong.** That includes every word users hit in screenshots
  (`elevate` → "The company decided to elevate her to the position of
  manager" → کمپنی نے اسے مینیجر کے عہدے پر ترقی دینے کا فیصلہ کیا),
  plus the common words pinned in earlier releases (`have`, `create`,
  `education`, `schedule`, `process`, `develop`, `achieve`, …) and a sweep
  of all remaining curated entries whose sentence illustrated a different
  word — `autumn`→"the leaves turn brown in autumn", `paradise`→"the
  island looked like paradise", `spicy`→"the spicy food made my mouth
  burn", and 84 more, replacing off-topic/placeholder examples (e.g. the
  "(please add an English translation…)" stubs) with clean sentences + real
  Urdu. Only sentences about the headword can ever be shown or auto-
  translated now.

## [0.23.0] — 2026-08-12

### Changed

- **Vocabulary section trimmed to a competitive-exam focus** (12 lists → 5).
  Removed General, Business, Oxford 3000/5000, Academic Word List, IELTS,
  TOEFL, Technology and Medical packs; kept:
  - **CSS / BPSC Vocabulary** (1,010)
  - **GRE High Frequency** (121)
  - **One-Word Substitutions** (new, 134) — classic CSS/BPSC/PMS exam items
    (Altruist, Ambidextrous, Genocide, Misanthrope, …) with Urdu + IPA
  - **Idioms** (68) and **Proverbs** (232) — the combined "Idioms & Proverbs"
    pack is now split into two separate lists using its existing per-entry
    classification, so idioms and proverbs no longer mix.
- Pack tests updated for the new list set (5 packs, ≥ 1,500 words, IPA
  requirement skipped for both phrase lists).

## [0.22.3] — 2026-08-12

### Fixed

- **92 wrong Urdu meanings corrected in one batch** (a full sweep of the
  high-frequency dictionary section found Hindi/Sanskrit leakage and wrong
  senses in the kaikki-derived pack). Added to the corrections pack
  (`zz_curated_corrections.json`, 1,180 → 1,272 entries):
  - Wrong meaning: `hardship` → مشکل (was محنت "hard work"), `cell` → خلیہ
    (was خلا "void"), `well` → کنواں (was کلیہ "kidney"), `die` → مرنا
    (was سونا "sleep"), `ever` → کبھی (was ہرگز "never"), `ride` → سواری
    کرنا (was جھولا "swing"), `section` → حصہ (was قسمت "fate"), `shoot` →
    گولی مارنا (was کیل "nail"), `design` → ڈیزائن (was سنسکار "ritual"),
    `stress` → دباؤ (was آگھات "blow"), `sense` → حس (was ارتھ/مضمون),
    `charge` → الزام (was حوالہ "reference"), `figure` → شکل (was مورت
    "idol"), `student` → طالب علم (was معلم "teacher"), `average` → اوسط
    (was مدھم "dim"), `tall` → لمبا (was اونٹ "camel"), `member` → رکن
    (was عضو "organ"), `rule` → قاعدہ (was نیم "half"), `father` → باپ
    (was اب "now"), `neat` → صاف ستھرا (was اجلا "bright"), `stage` →
    مرحلہ (was اکھاڑا "arena"), `discover` → دریافت کرنا (was پژوہش
    "research"), `declare` → اعلان کرنا (was نااہل قرار دینا).
  - Hindi/Sanskrit leakage removed: `war`/`battle`/`sing`/`red`/`power`/
    `spirit`/`mind`/`community`/`century`/`available`/`enemy`/`evidence`/
    `material`/`action`/`development`/`mass`/`human`/`local`/`black`/
    `paper`/`meaning`/`slowly`/`arm`/`leg`/`information`/`establish`/`step`/
    `observe`/`eye`/`hand`/`four`/`here`/`three`/`home`/`office`/`head`/
    `foot`/`today`/`government`/`smile`/`horse`/`air`/`much`/`just`/
    `general`/`complete`/`dark`/`accept`/`view`/`apply`/`develop`/`lie`/
    `act`/`amount`/`range`/`hit`/`cut`/`function`/`plant`/`product`/
    `voice`/`even`/`attention`/`admit`/`bear`/`feature`/`reflect`/`space`/
    `object`/`particular`/`table`/`treat`/`door`/`care`/`swing` — each now
    carries the common, learner-standard Urdu meaning.
- The batch is reproducible: `tools/dictionary/fix_urdu_meanings.py` re-applies
  it, and the packs were regenerated (urdu_wiktionary_pack.json 5,743 → 5,651
  entries as the corrected words moved to the winning zz pack).

## [0.22.2] — 2026-08-12

### Added

- **Every high-frequency word now has Urdu in the dictionary section.** The
  corrections pack (`zz_curated_corrections.json`, 732 → 1,180 entries) now
  hand-pins simple, exam-appropriate Urdu for all of the **top ~2,000 most
  common English words** (measured by SemCor frequency) that the kaikki
  sources and old pack missed — have, down, out, create, education, schedule,
  define, determine, prevent, maintain, approach, conduct, data, term,
  pattern, sample, select, perform, settle, vary, employ, shift, identify,
  introduce, advance, award, factor, display, engage, assign, velocity, ...
  Only genuinely offensive headwords (negro, damn, bastard) and fragments
  (non, anti, u.s.) are intentionally left English-only. Coverage: **0 real
  words missing Urdu in the top-1,000**, 0 in the top-2,000.
- **A second Urdu source in the dictionary pipeline.** `rebuild_dictionary.py`
  now also ingests the kaikki.org **English** Wiktionary dump (each English
  headword's curated Urdu `translations`), alongside the existing Urdu dump.
  The English dump contributes 779 headwords / 1,517 Urdu translations as
  candidates; **240 words** in the pack (bench, brake, boulevard, biology,
  chemistry, chicken, beach, ...) get their Urdu from this source alone
  because the Urdu dump doesn't cover them, and it independently confirms the
  existing meanings for hundreds more.

### Fixed

- **Gloss-first Urdu extraction.** The old extractor read each Urdu sense's
  first *link*, which is often a `{{topic|...}}` category tag — that is how
  wrong pairs like `automotive → شیشہ` (windscreen), `semantics → ضد`
  (antonym) and `windscreen → شیشہ` mis-pairings were born. The pipeline now
  takes the sense's English **gloss** (stripping a leading infinitive "to " so
  `to accept → accept`), and filters offensive senses, digit/vulgar Urdu
  words, and junk headwords (parentheses, trailing hyphens, phrase glosses).
- **Common-sense WordNet ordering bug.** Per-lemma SemCor counts were being
  overwritten by the synset's *last* (rarest) member, so `cat` ranked "to
  vomit" above "feline mammal". Counts are now per-lemma (with the cntlist's
  satellite-adjective keys matched via their gloss word).
- **Stale entries can no longer freeze into the pack.** The pipeline read its
  own previous output as an input, so one bad row (`have → گلا بیٹھنا`)
  survived every rebuild. Previous-pack Urdu is now an explicit snapshot
  (`OLD_URDU_PACK`) used only as a fallback — and it now **defaults to a
  committed copy** of the pre-pipeline pack
  (`tools/dictionary/snapshots/urdu_wiktionary_pack.v21.8.json`), so a plain
  `python3 tools/dictionary/rebuild_dictionary.py` run is reproducible out of
  the box. The fallback contributes 26 good words the two kaikki sources miss
  (astronomy, biology, botany, chemistry, geography, linguistics, music,
  mythology, physics, politics, rooster, ...).
- **+448 hand-curated corrections** (732 → 1,180): wrong or awkward Urdu
  meanings and sense-order conflicts (bank, sheik, miss, basic, compulsory,
  constitutional, fez, semantics, automotive, scared, page, bug, agency,
  oyster, dissimilar, hearts, union, distressed, fired, participate,
  establish, thereby, warrant, ...) are pinned in `zz_curated_corrections.json`,
  which always wins the merge. The last 7 fix mis-pairs the second source
  surfaced (`union → میتھن`, `distressed → دین`, `participate → بیٹھنا`,
  `thereby → اس کے علاوہ`, ...), and 3 more fix wrong fallback-only pairs
  inherited from the pre-pipeline pack (`courtesan → آنٹی "aunt"` → طوائف,
  `lesbianism → چپٹی "flat"` → ہم جنس پرستی, `oblique → خزاؤں "taxes"` →
  ترچھا).
- **Vulgar/sensitive content is blocked in both sources.** The English-dump
  loader now drops vulgar/sensitive English headwords (arse, ass, anal,
  condom, crap, fuck, sex, slut, vagina, ...) exactly like the Urdu-dump path
  already did, and a latent regex bug (`copulat|masturbat|ejaculat` required
  a word boundary right after the stem, so copulate/copulation,
  masturbate/masturbation and ejaculate/ejaculation never matched) is fixed.
  13 such entries were removed from the pack.
- **Empty entries eliminated:** entries whose Urdu came with no usable English
  body are kept only when the base Wordset dictionary supplies the definition,
  so the app never shows a word with "no information".

## [0.22.1] — 2026-08-12

### Changed

- **The dictionary now has a real JSON pipeline** (`tools/dictionary/rebuild_dictionary.py`)
  instead of one-off scripts. It regenerates the two data packs from raw
  licensed sources (WordNet 3.1 + kaikki.org Urdu + the bundled Wordset base),
  picks every word's **most common sense by real frequency data**, and
  revalidates the output — so expanding or fixing the dictionary from now on
  is running one script, not hand-editing thousands of entries.

### Added

- **English definition + example sentences for essentially every dictionary
  word.** The old `000_wordnet_enrichment.json` carried only example sentences
  (~30k) — 110k words had no definition of their own, so the app fell back to
  the base dictionary's *first* sense, which for many words was a rare or
  technical one (`bat` → "a turn at bat", `mother` → "inspiration",
  `bright` → "full of promise"). The regenerated pack gives all ~112k words a
  **common-sense-first English definition** (WordNet senses ranked by SemCor
  frequency) plus example sentences where WordNet has them. Machine-generated
  synonyms/antonyms are intentionally **not** shipped: the pipeline no longer
  emits them (v0.21.8 removed the noisy auto-synonyms; only the hand-curated
  packs carry synonyms).
- **Urdu coverage expanded ~4,800 → ~5,700 headwords** in the regenerated
  `urdu_wiktionary_pack.json`, with **common-sense-first Urdu** picked from
  the primary English gloss of each Urdu Wiktionary sense — the same
  frequency-aware logic that fixed `abacus → جنت` now applies to every
  kaikki-derived pairing, not just the 732 hand-corrected words.

### Fixed

- **Wrong-Urdu / wrong-definition regressions the auto-pipeline could have
  introduced are excluded by design:** headwords owned by the richer
  hand-curated packs (`exam_words`, `common_words*`, `zz_` corrections) are
  never touched, suffix fragments (`-ed`, `-ly`) and definitional phrase
  glosses ("a code of laws") are dropped, and all Urdu is validated as Urdu
  script (0 Latin leakages).

## [0.22.0] — 2026-08-12

### Fixed

- **732 wrong dictionary meanings corrected (Urdu + English).** The
  kaikki.org-derived `urdu_wiktionary_pack.json` paired some English headwords
  with a *rare or technical* Urdu sense — e.g. `angel → سر` (head),
  `breakfast → حاضری` (attendance), `bright → آئینہ` (mirror), `abacus → جنت`
  (heaven), `robber → یتیم` (orphan), `squabble → چونچ` (beak) — and showed
  rare/technical English definitions for many more (e.g. `bat → to wink
  briefly`, `mother → make children`, `salt → preserve with salt`).
- A new hand-curated **`zz_curated_corrections.json` corrections pack** (732
  entries) pins the common, exam-appropriate English definition + simple Urdu
  meaning for every affected word. Because the exam-pack seeder merges packs
  alphabetically with the last one winning, the `zz_` pack always overrides
  the raw kaikki entries — fixing the word profile page in the Dictionary
  **and** the reader pop-up, fully offline, on next launch (the seed
  signature changes, so re-seeding happens automatically).
- Every corrected entry was validated: 0 duplicate headwords, proper Urdu
  script + non-empty English meaning + part of speech, and an independent
  Urdu→English reverse audit confirms no remaining misaligned pair.

## [0.21.9] — 2026-08-11

### Added

- **Separate "Idioms & Proverbs" list in the Vocabulary section (300 curated
  entries).** The English→Urdu idioms/proverbs now have their own dedicated
  A–Z vocabulary list (`assets/vocabulary/idioms.json`, list id `idioms`) with
  search by English or Urdu, part-of-speech chips (Idiom / Proverb) and a short
  simple English meaning per entry. Derived from the licensed Apache-2.0
  dataset `assets/idioms/idioms.json` (Ehtisham1328/urdu-idioms-with-english-
  translation); only genuinely useful, correctly-paired idioms/proverbs were
  kept, deduped, and every entry validated for Urdu script + non-empty meaning.
  Kept as a separate data structure from normal vocabulary — never merged into
  the dictionary. Loaded automatically by the pack seeder on next launch.

## [0.21.8] — 2026-08-11

### Fixed

- **Auto-generated synonyms/antonyms removed.** The WordNet-generated
  Synonyms & Antonyms from 0.21.7 were too noisy for a learner dictionary
  (e.g. `avoid → face up`, `complain → quetch/kvetch`, `important → of
  import`). All machine-generated synonyms/antonyms have been eliminated;
  only the hand-curated ones remain (the 159 exam words + `de-escalation` /
  `communiqué`). The Synonyms & Antonyms section simply hides for every other
  word instead of showing wrong data.
- **Example sentences kept.** The WordNet example sentences (best sense,
  filtered for inappropriate content) remain for ~34k words — the Usage
  section still shows a real sentence with Urdu (fetched once online, then
  cached).

## [0.21.7] — 2026-08-11

### Added

- **Synonyms, antonyms and example sentences for every dictionary word.**
  New WordNet 3.1 enrichment (`000_wordnet_enrichment.json`, ~111k entries,
  sense-aligned so the picked synonyms match the word's real meaning) plus
  in-place enrichment of the curated packs. The Word Details screen now shows
  Synonyms & Antonyms for ~70k words (previously 159) and an example sentence
  with Urdu for ~34k words — the Urdu of auto-derived sentences is fetched by
  the hybrid translator and cached for offline reuse.
- **Curated exam extras** — `de-escalation` and `communiqué` (with Urdu usage),
  and `examData` now falls back to base forms + de-accented forms
  (`insulated` → `insulate`, `communiqué` → `communique`).
- **English → Urdu idioms (1,874)** — a separate, licensed dataset under
  `assets/idioms/`, never merged into vocabulary.
- **Offline translation extras** — `urdu_wiktionary_extra.json` (5,593 rows)
  and hand-curated `curated_reader_fixes.json`, auto-merged by the translation
  seeder via content signature.

### Fixed

- **Reader pop-up meanings for the reported NEXA booklet words** — `insulated`
  (was موصل = conductor), `communiqué` (was بات چیت), `underlining` (was a
  transliteration) and `internationalising` / `open-ended` / `de-escalation` /
  `diplomatically` / `wedged` now resolve to curated English + Urdu meanings
  fully offline.

## [0.21.6] — 2026-08-11

### Added

- **Curated common-word dictionary (642 entries)** — `assets/dictionary/common_words.json`
  + `common_words_2.json`. Simple English definitions **and** simple Urdu for the
  everyday words users tap in the reader (connectors, prepositions, common verbs
  and nouns). Auto-discovered by the exam seeder — no code change needed to grow it.

### Fixed

- **Online fallback now translates the bare word, not the WordNet definition.**
  Previously, uncached words were machine-translated from their verbose dictionary
  definition (e.g. `eventually` → "غير متعینہ مدت یا خاص طور پر طویل تاخیر کے بعد").
  Now the fallback translates just the word itself, producing short, natural Urdu.
- **Reader pop-up now seeds the curated dictionary before translating.** The
  curated common-word layer was previously only loaded on the Dictionary page,
  so reader pop-ups never saw it.
- **Word-sense heuristic penalises loaded/technical senses** ("notoriety",
  "pathology", "deficiency") so the offline dictionary picks the everyday sense
  for the long tail of uncovered words.

## [0.21.5] — 2026-08-11

### Fixed

- **Reader pop-up word meanings are now correct.** The pop-up used the
  offline dictionary's first sense, which for common words is often the rare
  or literary one (`attention` → "treatment", `tragedy` → "drama"). Meanings
  are now resolved through a five-tier system that prioritises the curated
  exam packs (CSS/BPSC, Oxford, IELTS…) with inflected-form matching
  (`contributing` → `contribute`), a curated layer for everyday words the raw
  dictionary gets wrong, and a best-sense heuristic for the long tail — so
  `attention` → توجہ, `tragedy` → سانحہ, and `contributing` → حصہ ڈالنا. The
  Urdu translation flows through the same resolution, so English meaning and
  Urdu are always consistent and curated Urdu is served offline.

### Added

- **Privacy Policy.** New in-app Settings → About → Privacy Policy screen and
  a hosted policy at `docs/privacy-policy.html` (for the Play Store listing).
- **Licenses & Credits.** New in-app Settings → About → Licenses & Credits
  screen that displays the bundled dictionary and translation data licenses
  (Wordset CC BY-SA, WordNet/Princeton, translation data GPL v2) plus the
  Flutter package licenses.
- **Branded splash screen.** The launch screen now uses the Sapiora navy brand
  colour (Android 12+ gets the matching system splash).

### Changed

- **Sapiora name consistency.** GitHub workflow name/release title, README
  package line, and the pubspec description all now say Sapiora.

## [0.21.4] — 2026-08-10

### Fixed

- **Double-tap zoom no longer jumps to the first page.** The zoom centre is
  now converted to true document coordinates — the same conversion pdfrx
  itself uses for pinch zoom — so double-tapping keeps the tapped content
  under your finger instead of flinging the view back to page 1.
- **English meaning now shows in the reader pop-up on fresh installs.** The
  bundled dictionary seeds lazily and the pop-up never triggered the seed, so
  on a new install every word's English definition silently disappeared. The
  pop-up now ensures the dictionary is ready before lookup, falls back to the
  curated CSS/BPSC exam packs for words the base dictionary doesn't cover,
  and degrades gracefully (no stuck spinner) if a lookup fails.

### Changed

- **CSS / BPSC Vocabulary is now the first word list.** The combined CSS/BPSC
  pack (1,010 words) is pinned to the top of the Vocabulary screen so
  competitive-exam words are the first thing you see.

## [0.21.3] — 2026-08-10

### Added

- **Double-tap zoom in the PDF reader.** Double-tap anywhere on a page zooms
  to a comfortable close-up centred on your finger (about 1.6×), and
  double-tapping again zooms back out to fit the screen. Text selection,
  pinch-zoom and panning are completely unaffected.

### Changed

- **CSS / BPSC Vocabulary expanded to 1,010 exam-oriented words.** The
  combined CSS/BPSC list now spans Governance, Economy, Education, Climate,
  Security, International Relations, Society, Technology, Analytical,
  Solutions, Essay, Connectors and General vocabulary — each word with a
  simple English meaning and a clear Urdu translation, still A–Z sorted.

### Fixed

- **Sense-correct Urdu translations for single words.** Online translators
  routinely picked the wrong meaning for isolated words — e.g. "execution"
  came back as پھانسی ("hanging") instead of عملدرآمد ("carrying out"). The
  reader now translates the word's English definition instead of the bare
  word, so the Urdu meaning matches the sense actually used in the text.
- **Online translation quality switched to Google Translate.** The free,
  keyless Google web endpoint replaces MyMemory as the online provider —
  noticeably better for both single words and full phrases/sentences.
- **English meaning now appears for far more words.** PDF selections often
  carry a stray trailing punctuation character (e.g. "execution,"), which
  stopped the pop-up from treating the selection as a single word — so the
  simple English definition (and the clean word saved to Vocabulary) were
  missing. Selections are now cleaned before lookup.

## [0.21.2] — 2026-08-10

### Changed

- **Every subject now wears its own colour on the session card itself.** The
  subject headline on each planner task card is tinted with the subject's
  colour (auto-assigned per subject — no manual set-up needed), so a row of
  different subjects reads as a colourful study line instead of one flat
  colour, while completed sessions still grey out with a strikethrough.
- **Break cards redesigned to match session cards.** Breaks no longer render
  as a thin italic "Break · 11:05 AM – 11:10 AM" line that sat oddly under the
  sessions. Each break is now a proper card with a tinted briefcase chip, a
  bold title and the time range below in the break colour — consistent with
  the study sessions around it.
- **Premium Pomodoro timer interaction.** Tapping the timer ring now starts
  the countdown and tapping it again pauses it — the separate Start button is
  gone, leaving just a Reset button and a "tap the ring" hint. Rotating the
  phone switches to a big-screen layout: a large ring on the left with the
  mode, hint and Reset on the right.
- **Picking a start time flows straight into the end time.** Tapping Start
  opens the time picker; after you confirm it with OK, the End time picker
  opens automatically (pre-filled with start + 1h) so you only confirm the
  end — no separate End tap needed. Breaks do the same with start + 15 min.

## [0.21.1] — 2026-08-10

### Changed

- **Study Planner now opens straight into the tabbed planner.** Opening Study
  Planner lands on the mockup interface: the Daily | Weekly | Monthly pill
  switcher sits right at the top, with the selected view below it — Daily
  (led by the 🔥 streak / 🎯 goal / ⏱ study-today overview row), Weekly
  (collapsible day cards) and Monthly (calendar, stats grid + progress
  donut). No more separate dashboard before the planner.
- **Every dashboard feature stays reachable from the planner's ⋮ menu:**
  Study Timer (Pomodoro + Manual + full screen), Progress (weekly / monthly
  statistics), Quick Actions, Templates, Manage Subjects and Export &
  Backup. The old standalone dashboard page and its unused daily-planner
  card were removed.
- **Planner views match the mockup's subject-colour look.** Each day of the
  week strip now shows its subjects as small coloured dots, task rows draw a
  subject-coloured timeline, every task card shows its time range tinted in
  the subject's colour, and the break row uses the mockup's briefcase icon.

## [0.21.0] — 2026-08-10

### Added

- **Unified Study Planner with a Daily / Weekly / Monthly switcher.** The
  planner is now one continuous experience: a segmented Daily | Weekly |
  Monthly control sits at the top of every planner page (and a redesigned
  unified Planner page bundles all three views behind a pill switcher with
  colour-coded subjects, round checkmarks, a collapsible weekly list and a
  monthly calendar with a stats grid + progress donut).
  - **Daily** — week date-strip navigation with tappable day pills.
  - **Weekly** — collapsible day rows that show "Weekday, date · N tasks"
    and expand to the full day on tap; only today opens by default.
  - **Monthly** — calendar with task-colour dots, month-at-a-glance stats
    and a progress ring.

### Fixed

- **Study Planner build restored.** The planner redesign had accidentally
  removed the shared `day_planner_section.dart` widget while the Daily,
  Weekly and Monthly pages still used it, which broke `flutter analyze` and
  the APK build. The widget is restored (unchanged), so the planner ships.

## [0.20.0] — 2026-08-09

### Changed

- **Wrong Answers and Statistics removed from the MCQs section.** The subject
  page's Practice card is now a pure study surface: MCQs and Bookmarks only.
  The Wrong Answers row (which previously opened the answers-shown feed or,
  before that, a practice notebook) and the Statistics row are gone entirely,
  and the now-unused subject stats page was deleted. The Quiz section still
  owns its own wrong-answers notebook via the Quiz home menu, untouched.

## [0.19.0] — 2026-08-09

### Changed

- **Wrong Answers is now a study feed, not a practice notebook.** Tapping
  Wrong Answers on a subject page opens the same answers-shown MCQs feed
  scoped to that subject's wrong-answer notebook — the correct answer is
  already marked on every card, with search, filters, bookmarks and
  "Read more >>" explanations. The old page (a bare list plus a "Retry all"
  button that launched the interactive practice player) is gone from the
  MCQs section: that behaviour belongs to the Quiz section only.
- **Statistics page rebuilt to be useful from day one.** The subject stats
  page now always shows Questions, Bookmarked and Topics, plus a per-topic
  breakdown with bookmark counts (tap a topic to open its study feed). Wrong
  and Accuracy tiles only appear when real data exists, so the page never
  shows dead zero tiles.

## [0.18.0] — 2026-08-09

### Changed

- **Every MCQs entry opens the answers-shown study feed.** Tapping a topic on
  a subject page (e.g. English → Synonyms) now opens the same study-mode feed
  as the Practice → MCQs row: a scrollable list of question cards with the
  correct answer already marked in the accent colour (bold + faint tint),
  search, filters, bookmarks and "Read more >>" explanations — scoped to that
  topic's questions. The interactive practice player (green/red feedback,
  question counter, Previous/Skip/Next, timer) is no longer reachable from the
  MCQs section: that behaviour belongs to the Quiz section only, so the two
  modes can never be mixed. No question data was touched; the Quiz (staged)
  section is completely unchanged.

## [0.17.0] — 2026-08-09

### Changed

- **Quiz stage player: 50s timer, freeze-on-answer, shuffled options.** The
  per-question countdown is now 50 seconds (was 30). The timer freezes the
  instant the user answers — it never keeps counting down to zero while the
  user reviews the green/red feedback. Pressing NEXT (or FINISH) resets it to
  50 seconds for the next question. MCQ options are shuffled per question when
  the question loads (never reshuffled on rebuild), and the correct-answer
  reference is remapped along with the order, so the correct answer is no
  longer predictably option A — it lands randomly across A/B/C/D while grading
  still matches the real answer. Timeout (skipped), scoring, results, QUIT and
  the MCQs study feed are unchanged.

## [0.16.0] — 2026-08-09

### Changed

- **MCQs section is a pure study/revision feed.** The MCQs browse cards no
  longer borrow any Quiz-screen furniture: radio icons, check badges and
  green correct-answer tints are gone. Each card now shows the question in
  bold, the options A–D beneath it, the correct option quietly marked in the
  app's accent colour (bold text + faint tint, no icons, no borders), and a
  bottom-right "Read more >>" link that expands the explanation in place.
  True/False and fill-in-the-blank rows use the same quiet accent treatment.
  Bookmarks, search, filters, lazy pagination and all question data are
  unchanged; the Quiz section is completely untouched.

## [0.15.0] — 2026-08-09

### Changed

- **Quiz stages give instant feedback.** The Quiz (stage) player now behaves
  like the reference interactive test: select an option and the correct answer
  turns green immediately, a picked-wrong answer turns red, and the actual
  correct answer also turns green. All four options lock after answering — no
  changing, no multiple selections. **NEXT / FINISH is disabled until you
  answer** (the 30s timer still auto-advances unanswered questions as before),
  the counter shows `1/10` style numbering, and the question now sits in a
  prominent rounded, bordered card that wraps long questions. QUIT, the timer,
  scoring, stage progress and the results screen are unchanged. The MCQs
  browse section keeps showing answers upfront — the two modes stay separate.

## [0.14.0] — 2026-08-09

### Changed

- **Unmistakable answer feedback across the Quiz screens.** All MCQ surfaces
  now share one option-card component and a green-correct / red-wrong
  language (mirroring the classic PAK MCQS reference, inside the dark theme):
  - **Practice (MCQs) player:** picking an answer instantly fills the correct
    option solid green with a check + "Correct" pill (bold white text) and the
    picked-wrong option solid red with a "Wrong" pill; the rest stay muted.
    Question numbering and the progress bar are unchanged.
  - **Stage (Quiz) player:** option cards are pixel-identical to practice —
    picked = purple-tinted fill + filled radio, unpicked = dark surface.
  - **Review answers:** correct = green, wrong = red, matching the players.
  - **MCQs browse cards:** the inline correct-answer highlight is green now,
    so "correct = green" reads consistently in every screen.

## [0.13.0] — 2026-08-09

### Added

- **Search & filters in the MCQs browser.** The study-mode MCQs list now has a
  search box (matches question text/options, debounced) plus filter chips for
  question **type** (MCQ / True-False / Fill-blank), **difficulty**
  (Easy / Medium / Hard) and **bookmarked-only**, with a Reset chip to clear
  everything. The banner updates to show the number of matching questions.

## [0.12.0] — 2026-08-09

### Added

- **Study-mode MCQs browser.** The MCQs section now mirrors the classic
  "All MCQs" layout: a scrollable list of question cards where the **correct
  answer is highlighted right inside the options** (bold, tinted, with a check
  mark), so answers are always visible while browsing — no tapping needed.
  Each card shows the question type/difficulty, a bookmark toggle, and a
  "Read more" expander for the explanation. The list loads lazily in pages
  (25 at a time) so subjects with 2,200 questions stay smooth.

### Changed

- **Quiz home decluttered.** The redundant "Subjects" list below the MCQs /
  Quiz cards is gone — subjects are reached from inside either card, exactly
  like the reference app.

## [0.11.1] — 2026-08-09

### Fixed

- **Quiz home cards no longer disappear.** The MCQs / Quiz cards on the Quiz
  tab used `CrossAxisAlignment.stretch` inside a `ListView`, which hands the
  cards an unbounded (infinite) height constraint — Flutter's flex layout then
  produced an infinite-height child and the whole card row (and everything
  below it) failed to lay out in the release build. The row is now wrapped in
  `IntrinsicHeight` so both cards size to a real, equal height.

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

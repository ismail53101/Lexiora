import 'package:drift/drift.dart';
import 'package:lexiora/core/database/converters.dart';

/// An imported PDF document and its library metadata.
@DataClassName('DocumentRow')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 512)();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();
  TextColumn get coverPath => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get importedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

  /// True when the file at [filePath] is a private copy the app made during
  /// manual import (stored under the app's files dir). Such files are deleted
  /// when the document is removed. Auto-discovered documents reference the
  /// user's own file in place ([managedFile] = false) and are never deleted.
  BoolColumn get managedFile =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A user-defined library category (e.g. "Grammar", "Novels").
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 128)();
  IntColumn get colorValue => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A page-level bookmark (optionally created from a text selection, in which
/// case the selected text is stored in [label]).
@DataClassName('BookmarkRow')
class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text()();
  IntColumn get pageNumber => integer()();
  TextColumn get label => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A text-anchored highlight or underline. Geometry is stored as normalized
/// rects so it survives zoom and re-layout.
@DataClassName('HighlightRow')
class Highlights extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text()();
  IntColumn get pageNumber => integer()();

  /// Mirrors `AnnotationType.index`: 0 = highlight, 1 = underline.
  IntColumn get type => integer().withDefault(const Constant(0))();
  IntColumn get colorValue => integer()();
  TextColumn get selectedText => text().withDefault(const Constant(''))();
  TextColumn get rects => text().map(const NormalizedRectListConverter())();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A note attached either to a whole page or to a specific text selection.
@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text()();
  IntColumn get pageNumber => integer()();
  TextColumn get content => text()();

  /// Mirrors `NoteAnchor.index`: 0 = page, 1 = selection.
  IntColumn get anchorType => integer().withDefault(const Constant(0))();
  TextColumn get selectedText => text().nullable()();

  /// Normalized rects for selection-anchored notes; empty list for page notes.
  TextColumn get rects => text().map(const NormalizedRectListConverter())();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The current reading position and computed progress for a document (one row
/// per document).
@DataClassName('ReadingProgressRow')
class ReadingProgress extends Table {
  TextColumn get documentId => text()();
  IntColumn get lastPage => integer().withDefault(const Constant(1))();
  IntColumn get totalPages => integer().withDefault(const Constant(0))();
  RealColumn get percent => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {documentId};
}

/// A single reading-history entry, appended each time a document is opened.
@DataClassName('ReadingSessionRow')
class ReadingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text()();
  IntColumn get pageNumber => integer()();
  DateTimeColumn get openedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Key-value application settings, kept in the same local database so there is a
/// single offline source of truth.
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// A single offline dictionary sense (one row per word × meaning).
///
/// This table is **read-mostly**: it is bulk-seeded once from the bundled data
/// set and then only queried. A word with several senses has several rows;
/// searches group by [wordLower]. [wordLower] is the lowercased headword and is
/// indexed for fast, case-insensitive prefix search over 150k+ rows. The schema
/// is intentionally flat and additive so future fields (e.g. frequency rank,
/// audio pronunciation) can be added without reshaping it. Favourites live in a
/// separate [DictionaryFavorites] table so this data can be re-seeded without
/// ever touching the user's saved words.
@DataClassName('DictionaryEntryRow')
class DictionaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Headword as displayed (original casing), e.g. "Apple".
  TextColumn get word => text()();

  /// Lowercased headword used for indexed, case-insensitive search.
  TextColumn get wordLower => text()();

  /// Grammatical category, e.g. "noun" (nullable — not every source has it).
  TextColumn get partOfSpeech => text().nullable()();

  /// The definition text for this sense.
  TextColumn get meaning => text()();

  /// IPA pronunciation, when available (the bundled set does not include it).
  TextColumn get ipaPronunciation => text().nullable()();

  /// An example sentence for this sense, when available.
  TextColumn get exampleSentence => text().nullable()();
}

/// A user-saved ("favorite" / saved-to-vocabulary) word.
///
/// Keyed by [wordLower] so a word is favourited once regardless of how many
/// senses it has. A snapshot of the primary part-of-speech and meaning is
/// denormalized here so the Favorites list renders from a single table (fully
/// reactive, and independent of any dictionary re-seed).
@DataClassName('DictionaryFavoriteRow')
class DictionaryFavorites extends Table {
  TextColumn get wordLower => text()();
  TextColumn get word => text()();
  TextColumn get partOfSpeech => text().nullable()();
  TextColumn get meaning => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {wordLower};
}

/// A curated, exam-oriented dictionary entry (Dictionary v2).
///
/// Read-mostly: seeded once from the bundled `exam_words.json`. The rich body
/// (ordered Urdu meanings, other meanings, synonyms/antonyms, context usage,
/// collocations, word forms, idioms, exam note, pronunciation) is stored as a
/// single JSON document in [contentJson] so new fields can be added later with
/// no schema change. Keyed by the lowercased headword for O(1) lookup.
@DataClassName('DictionaryExamEntryRow')
class DictionaryExamEntries extends Table {
  TextColumn get wordLower => text()();
  TextColumn get word => text()();
  TextColumn get contentJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {wordLower};
}

/// The user's recent word searches (capped and auto-pruned). Local-only.
@DataClassName('SearchHistoryRow')
class DictionarySearchHistory extends Table {
  TextColumn get wordLower => text()();
  TextColumn get word => text()();
  DateTimeColumn get searchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {wordLower};
}

/// An offline translation of an English headword into one target language.
///
/// Read-only, bulk-seeded from the bundled data set. Looked up by
/// ([langCode], [wordLower]); a composite index makes that lookup fast across
/// the whole multi-language table. This lives alongside — and independent of —
/// the dictionary tables so the Translation module owns its own data.
@DataClassName('TranslationEntryRow')
class TranslationEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Two-letter target language code, e.g. "fr", "hi".
  TextColumn get langCode => text()();

  /// Lowercased English headword being translated.
  TextColumn get wordLower => text()();

  /// The translation text (one or more senses, joined).
  TextColumn get translation => text()();
}

/// Online-fetched translations saved for offline reuse (Hybrid Translation
/// System, Phase v0.4.1).
///
/// This table is **separate** from the read-only, bulk-seeded
/// [TranslationEntries] so that re-seeding the bundled data set never wipes the
/// user's cached online translations. A lookup consults the bundled table first
/// and then this cache — both are "offline" from the reader's point of view.
/// The composite primary key ([langCode], [wordLower]) makes lookups fast and
/// **prevents duplicate cache rows** for the same word/language at the database
/// level (an upsert simply refreshes the existing row).
@DataClassName('TranslationCacheRow')
class TranslationCache extends Table {
  /// Two-letter target language code, e.g. "ur".
  TextColumn get langCode => text()();

  /// Lowercased English headword being translated.
  TextColumn get wordLower => text()();

  /// The original (display) casing of the word.
  TextColumn get word => text()();

  /// The cached translation text.
  TextColumn get translation => text()();

  /// How the entry was obtained (e.g. "online"). Kept so cached rows can be
  /// distinguished/managed later without a schema change.
  TextColumn get source => text().withDefault(const Constant('online'))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {langCode, wordLower};
}

/// A single offline grammar lesson (Phase v0.4.0).
///
/// This table is **read-mostly**: it is seeded once from the bundled JSON data
/// set and then only queried. The list-facing metadata (title, category,
/// summary, order) lives in dedicated columns for fast, index-backed listing
/// and search, while the full lesson body (explanation, rules, examples, notes,
/// tips, common mistakes and practice questions) is stored as a single JSON
/// document in [contentJson]. Keeping the body as JSON means new content fields
/// can be added later with **no schema change** — only a bumped dataset version
/// and an updated asset. The user's reading progress and saved lessons live in
/// the separate [GrammarProgress] and [GrammarFavorites] tables, so lessons can
/// be re-seeded without ever touching them.
@DataClassName('GrammarLessonRow')
class GrammarLessons extends Table {
  /// Stable slug id, e.g. `parts-of-speech`.
  TextColumn get id => text()();

  /// Grouping category, e.g. `Foundations`.
  TextColumn get category => text()();

  /// Display title, e.g. `Parts of Speech`.
  TextColumn get title => text()();

  /// One-line description shown in lists and cards.
  TextColumn get summary => text()();

  /// Lowercased haystack (title + summary + keywords + category) used for
  /// case-insensitive substring search.
  TextColumn get searchText => text()();

  /// Sort order within the whole module and within a category (lower first).
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  /// The full lesson body encoded as a JSON object (explanation, rules,
  /// examples, notes, tips, commonMistakes, practiceQuestions).
  TextColumn get contentJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Per-lesson reading progress (one row per lesson the user has opened).
///
/// Rows are created lazily the first time a lesson is opened. [status] mirrors
/// `GrammarProgressStatus.index` (0 = not started, 1 = in progress,
/// 2 = completed). [scrollProgress] is the furthest read fraction (0..1) and
/// drives the "Continue learning" and progress-bar UI.
@DataClassName('GrammarProgressRow')
class GrammarProgress extends Table {
  TextColumn get lessonId => text()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  RealColumn get scrollProgress => real().withDefault(const Constant(0))();
  DateTimeColumn get lastViewedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {lessonId};
}

/// A user-saved ("favorite") grammar lesson.
///
/// Keyed by [lessonId]. A snapshot of the title and category is denormalized
/// here so the Favorites list renders from a single table (fully reactive and
/// independent of any lessons re-seed).
@DataClassName('GrammarFavoriteRow')
class GrammarFavorites extends Table {
  TextColumn get lessonId => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {lessonId};
}

/// A node in the Grammar Category → Subcategory → Lesson tree (Phase v0.5.0).
///
/// Branch nodes ([isLeaf] = false) group children; leaf nodes carry a full
/// lesson in [contentJson] (introduction, Urdu/English explanation, types,
/// rules, examples, common mistakes, practice, quiz, summary). Seeded once from
/// the bundled tree. [parentId] is null for top-level categories. Progress and
/// favorites are keyed by a leaf's [id] in the existing grammar tables.
@DataClassName('GrammarTopicRow')
class GrammarTopics extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  BoolColumn get isLeaf => boolean().withDefault(const Constant(false))();

  /// Lowercased haystack (leaf title + intro/keywords) for search over lessons.
  TextColumn get searchText => text().withDefault(const Constant(''))();

  /// Full lesson body as JSON, for leaves only (null for branches).
  TextColumn get contentJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A vocabulary word list (Phase v0.6.0), e.g. "General Vocabulary",
/// "Business Vocabulary", "GRE High Frequency".
///
/// The Vocabulary module is a *learning* feature (organized A–Z word lists),
/// distinct from the Dictionary. Lists and their words are seeded from bundled
/// JSON packs under `assets/vocabulary/` (one pack per list) and merged into
/// these read-mostly tables. [wordCount] is denormalized so the lists screen
/// renders from a single query.
@DataClassName('VocabularyListRow')
class VocabularyLists extends Table {
  /// Stable slug id, e.g. `general`, `business`.
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A single vocabulary word within a list (Phase v0.6.0).
///
/// Deliberately minimal — this is a learning card, not a dictionary entry: the
/// English word, its IPA, a short Urdu meaning, a short English meaning, and the
/// part of speech. (Long definitions, examples, synonyms, idioms, etc. live in
/// the Dictionary module.) [letter] is the A–Z bucket used for sticky headers
/// and the quick-jump rail; [searchText] holds `wordLower + urduMeaning` so a
/// single indexed column powers instant search in both English and Urdu.
@DataClassName('VocabularyWordRow')
class VocabularyWords extends Table {
  /// Stable composite id: `<listId>/<wordLower>`.
  TextColumn get id => text()();
  TextColumn get listId => text()();
  TextColumn get word => text()();
  TextColumn get wordLower => text()();

  /// Uppercase A–Z bucket (or `#` for non-alphabetic) for grouping/headers.
  TextColumn get letter => text().withLength(min: 1, max: 1)();
  TextColumn get ipa => text().nullable()();
  TextColumn get urduMeaning => text()();
  TextColumn get englishMeaning => text()();
  TextColumn get partOfSpeech => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  /// Lowercased English word + Urdu meaning, for case-insensitive substring
  /// search across both scripts.
  TextColumn get searchText => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ── Study Hub (Phase v0.7.0) ────────────────────────────────────────────────
//
// The Study Hub is the user's personal learning dashboard. All three tables
// below hold USER data (never authored content), keyed by [day] ('YYYY-MM-DD',
// local) for fast per-day and per-range queries. Every row carries a stable
// UUID [id] and timestamps so a future Cloud Sync layer can diff/merge without
// any schema change. These are additive: no existing table is touched.

/// A planned study task for a given [day].
@DataClassName('StudyTaskRow')
class StudyTasks extends Table {
  TextColumn get id => text()();
  TextColumn get day => text()();
  TextColumn get title => text()();
  TextColumn get subject => text().nullable()();

  /// Start/end time as minutes from midnight (0–1439); null when unscheduled.
  IntColumn get startMinute => integer().nullable()();
  IntColumn get endMinute => integer().nullable()();

  /// 0 = low, 1 = medium, 2 = high (mirrors TaskPriority.index).
  IntColumn get priority => integer().withDefault(const Constant(1))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  // ── v0.7.1 (Academic Planning System) — all additive & nullable/defaulted so
  //    existing rows remain valid. [title] stays the human label (subject for
  //    new sessions; the break name for breaks).

  /// The topic within the subject (user-defined; null for breaks).
  TextColumn get topic => text().nullable()();

  /// Free-form notes/description (user-defined).
  TextColumn get notes => text().nullable()();

  /// 0 = pending, 1 = in progress, 2 = completed (mirrors TaskStatus.index).
  /// Kept in sync with [completed] so pre-v0.7.1 queries keep working.
  IntColumn get status => integer().withDefault(const Constant(0))();

  /// Actual studied minutes recorded for this session (via a timer); optional.
  IntColumn get durationMinutes => integer().nullable()();

  /// 'session' or 'break' (mirrors SessionKind.key). Existing rows default to
  /// 'session'. Breaks store their name in [title] and never count as sessions.
  TextColumn get kind =>
      text().withDefault(const Constant('session'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A daily goal with progress (e.g. "Learn 20 vocabulary words").
@DataClassName('StudyGoalRow')
class StudyGoals extends Table {
  TextColumn get id => text()();
  TextColumn get day => text()();
  TextColumn get title => text()();

  /// vocabulary / reading / grammar / mcq / custom (mirrors GoalType.key).
  TextColumn get type => text().withDefault(const Constant('custom'))();
  IntColumn get targetCount => integer().withDefault(const Constant(1))();
  IntColumn get currentCount => integer().withDefault(const Constant(0))();
  TextColumn get unit => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A recorded study session — a completed Pomodoro focus block or a manual log.
/// Drives Study Hours, the streak, and the weekly/monthly statistics.
@DataClassName('StudySessionRow')
class StudySessions extends Table {
  TextColumn get id => text()();
  TextColumn get day => text()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationMinutes => integer()();

  /// pomodoro / manual.
  TextColumn get kind => text().withDefault(const Constant('pomodoro'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A reusable study routine template (Phase v0.7.1), e.g. "CSS Routine".
/// Applying a template copies its items into a day's [StudyTasks] as fully
/// editable sessions — it never locks any data.
@DataClassName('StudyTemplateRow')
class StudyTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A single session/break inside a [StudyTemplates] routine.
@DataClassName('StudyTemplateItemRow')
class StudyTemplateItems extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text()();
  TextColumn get kind => text().withDefault(const Constant('session'))();
  TextColumn get title => text()();
  TextColumn get subject => text().nullable()();
  TextColumn get topic => text().nullable()();
  IntColumn get startMinute => integer().nullable()();
  IntColumn get endMinute => integer().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  TextColumn get notes => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A user-defined subject with a custom colour (Phase v0.7.2).
///
/// Subjects are keyed by [nameLower] (case-insensitive) so a session's free-text
/// subject maps to its colour. Deleting/archiving a subject never touches study
/// history — sessions keep their text; they simply lose (or regain) the colour.
@DataClassName('StudySubjectRow')
class StudySubjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get nameLower => text()();

  /// ARGB colour value.
  IntColumn get color => integer()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ── Flashcards (Phase v0.8.0) ───────────────────────────────────────────────
//
// A brand-new, independent module. Everything is user-defined. Subject colours
// are NOT duplicated here — they are read from `study_subjects`. Cards carry
// SM-2-ready scheduling fields ([easeFactor], [intervalDays], [repetitions],
// [lapses], [dueAt], [reviewState]); the full SM-2 algorithm is not implemented.

/// A user-created deck of flashcards.
@DataClassName('DeckRow')
class Decks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get subject => text().nullable()();
  TextColumn get topic => text().nullable()();

  /// Optional deck-specific ARGB colour (else the subject colour is used).
  IntColumn get color => integer().nullable()();

  /// Material icon code point for the deck.
  IntColumn get icon => integer().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A single flashcard. Front/back are free text (rich-text ready). Bookmark,
/// favourite and difficulty are user controls; the scheduling fields make the
/// card SM-2 compatible without implementing the algorithm.
@DataClassName('FlashcardRow')
class Flashcards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text()();
  TextColumn get front => text()();
  TextColumn get back => text()();
  TextColumn get subject => text().nullable()();
  TextColumn get topic => text().nullable()();

  /// Comma-separated user tags (free text).
  TextColumn get tags => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// 0 = none, 1 = easy, 2 = medium, 3 = hard (mirrors CardDifficulty.index).
  IntColumn get difficulty => integer().withDefault(const Constant(0))();
  BoolColumn get bookmarked => boolean().withDefault(const Constant(false))();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();

  // ── SM-2-ready scheduling (simple placeholder scheduler drives these) ──
  /// 0 = new, 1 = learning, 2 = review (mirrors ReviewState.index).
  IntColumn get reviewState => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();

  TextColumn get searchText => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One review event, for statistics and (future) SM-2 tuning.
@DataClassName('ReviewLogRow')
class ReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get cardId => text()();
  TextColumn get deckId => text()();

  /// 0 = again, 1 = hard, 2 = good, 3 = easy (mirrors CardRating.index).
  IntColumn get rating => integer()();
  TextColumn get day => text()();
  DateTimeColumn get reviewedAt => dateTime()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ── Quiz Engine (Phase v0.9.0) ──────────────────────────────────────────────
//
// A brand-new, fully independent module. It stores NO built-in content — the
// tables ship empty. Questions are *content*, loaded later via Local JSON /
// Admin CMS / Cloud API through the QuestionProvider abstraction. Nothing here
// is hardcoded: banks, subjects, topics, tags and questions are all data-driven.
// Subject colours are read (never duplicated) from `study_subjects`.

/// A Question Bank — a versioned, taggable group of questions (usually one
/// per imported JSON pack, but user/Admin-creatable too). Total-question count
/// is computed on demand (never denormalised) so it can never drift.
@DataClassName('QuizBankRow')
class QuizBanks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get subject => text().nullable()();
  TextColumn get topic => text().nullable()();
  TextColumn get description => text().nullable()();

  /// Optional bank-specific ARGB colour (else the subject colour is used).
  IntColumn get color => integer().nullable()();

  /// Comma-separated free-text tags.
  TextColumn get tags => text().nullable()();

  /// Content version string (e.g. "1.0") carried from the source pack.
  TextColumn get version => text().nullable()();

  /// Provenance of the bank: 'manual' | 'local_json' | 'admin' | 'cloud'.
  TextColumn get source => text().withDefault(const Constant('manual'))();

  /// Stable id from the external source, for merge/replace deduplication.
  TextColumn get externalId => text().nullable()();

  /// Links into the Subject → Topic hierarchy (v0.9.1). Nullable for banks not
  /// yet filed under a subject/topic. Managed by the Admin CMS / demo seeder.
  TextColumn get subjectId => text().nullable()();
  TextColumn get topicId => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get searchText => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A universal question. [type] selects how [optionsJson] / [answerJson] are
/// interpreted, so one row models MCQ (single), True/False and Fill-in-the-Blank
/// today and Matching / Multi-Correct later — no schema change required.
@DataClassName('QuizQuestionRow')
class QuizQuestions extends Table {
  TextColumn get id => text()();
  TextColumn get bankId => text()();

  /// Mirrors QuestionType.index: 0 mcqSingle, 1 trueFalse, 2 fillBlank,
  /// 3 matching (reserved), 4 multiCorrect (reserved).
  IntColumn get type => integer().withDefault(const Constant(0))();

  /// The question stem / prompt (free text, markdown-ready).
  TextColumn get prompt => text()();

  /// JSON array of option strings (MCQ/matching). Null for True/False & Blank.
  TextColumn get optionsJson => text().nullable()();

  /// JSON-encoded correct answer, shape depends on [type]:
  /// mcqSingle → int index; trueFalse → bool; fillBlank → [accepted strings];
  /// multiCorrect → [indices]; matching → {left: right}.
  TextColumn get answerJson => text().nullable()();
  TextColumn get explanation => text().nullable()();

  /// Denormalised (from the bank/pack) for fast filtering & subject analytics.
  TextColumn get subject => text().nullable()();
  TextColumn get topic => text().nullable()();
  TextColumn get tags => text().nullable()();

  /// 0 = none, 1 = easy, 2 = medium, 3 = hard (mirrors QuizDifficulty.index).
  IntColumn get difficulty => integer().withDefault(const Constant(0))();
  BoolColumn get bookmarked => boolean().withDefault(const Constant(false))();

  /// Stable id from the external source, for merge/replace deduplication.
  TextColumn get externalId => text().nullable()();

  /// Links into the Subject → Topic hierarchy (v0.9.1); denormalised for fast
  /// per-subject/topic filtering and analytics.
  TextColumn get subjectId => text().nullable()();
  TextColumn get topicId => text().nullable()();
  TextColumn get searchText => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One quiz attempt (session/result). Finished attempts feed Analytics; an
/// unfinished attempt ([finishedAt] null) represents an in-progress session.
@DataClassName('QuizAttemptRow')
class QuizAttempts extends Table {
  TextColumn get id => text()();

  /// Bank studied, or null for a mixed/custom selection.
  TextColumn get bankId => text().nullable()();

  /// 0 = practice, 1 = exam (mirrors QuizMode.index).
  IntColumn get mode => integer().withDefault(const Constant(0))();
  TextColumn get title => text().nullable()();
  IntColumn get totalQuestions => integer().withDefault(const Constant(0))();
  IntColumn get correct => integer().withDefault(const Constant(0))();
  IntColumn get wrong => integer().withDefault(const Constant(0))();
  IntColumn get skipped => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  /// 'YYYY-MM-DD' of completion, for daily/weekly/monthly analytics ranges.
  TextColumn get day => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A single response within an attempt — powers Review Answers and the automatic
/// Wrong-Answer Notebook. [subject] is copied from the question at answer time
/// so subject analytics survive later content re-imports.
@DataClassName('QuizAnswerRow')
class QuizAttemptAnswers extends Table {
  TextColumn get id => text()();
  TextColumn get attemptId => text()();
  TextColumn get questionId => text()();

  /// JSON-encoded answer the user gave (null when skipped).
  TextColumn get givenJson => text().nullable()();
  BoolColumn get isCorrect => boolean().withDefault(const Constant(false))();
  BoolColumn get skipped => boolean().withDefault(const Constant(false))();
  TextColumn get subject => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  IntColumn get timeMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The Wrong-Answer Notebook: one row per question the user has gotten wrong
/// (deduped by [questionId]). Auto-upserted after each attempt; user can review,
/// retry, delete or clear all.
@DataClassName('QuizWrongRow')
class QuizWrongAnswers extends Table {
  /// The question id (natural key → one notebook entry per question).
  TextColumn get questionId => text()();
  TextColumn get bankId => text().nullable()();
  TextColumn get subject => text().nullable()();

  /// JSON of the most recent wrong answer given.
  TextColumn get lastGivenJson => text().nullable()();
  IntColumn get wrongCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastWrongAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {questionId};
}

/// Key–value store for Quiz Engine preferences (default mode, questions per
/// quiz, shuffle, timer, show-explanations, negative marking, …). Key-value so
/// new settings never need a migration.
@DataClassName('QuizSettingRow')
class QuizSettingsRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// A top-level Quiz Subject (v0.9.1). Fully data-driven: created, ordered,
/// coloured and iconised from the hidden Admin CMS (and the demo seeder). The
/// public app renders whatever rows exist here — nothing is hardcoded.
@DataClassName('QuizSubjectRow')
class QuizSubjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();

  /// Material icon code point (optional).
  IntColumn get icon => integer().nullable()();

  /// ARGB colour (optional; else a subject colour / theme default is used).
  IntColumn get color => integer().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get searchText => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A Topic within a Subject (v0.9.1). Unlimited per subject; ordered/editable
/// from the Admin CMS. Quizzes (banks) and questions link here by [id].
@DataClassName('QuizTopicRow')
class QuizTopics extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get icon => integer().nullable()();
  IntColumn get color => integer().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Per-stage progress for the staged Quiz experience (Phase v0.11.0).
///
/// One row per (subject, stage): the user's best result on that stage's
/// 10-question challenge. Unlock logic is derived at read time (a stage is
/// unlocked once the previous stage is passed), so only the best result is
/// stored here — attempts/analytics still live in the existing quiz tables.
@DataClassName('QuizStageProgressRow')
class QuizStageProgress extends Table {
  TextColumn get subjectId => text()();
  IntColumn get stageIndex => integer()();

  /// Best percentage score (0–100) achieved on this stage.
  IntColumn get bestScore => integer().withDefault(const Constant(0))();

  /// Best star rating (0–3) achieved on this stage.
  IntColumn get bestStars => integer().withDefault(const Constant(0))();

  /// Total number of completed attempts on this stage.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// True once the stage was passed (score >= 50%), unlocking the next one.
  BoolColumn get passed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {subjectId, stageIndex};
}

// ── AI Assistant (Phase v0.10.0) ────────────────────────────────────────────
//
// Offline-first chat persistence for the AI Assistant. Two additive tables:
// a conversation per chat session and its ordered messages. Content only —
// the API key is never stored here (it comes from environment config).

/// One AI chat session (a conversation).
@DataClassName('AiConversationRow')
class AiConversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();

  /// The model used for this conversation (e.g. 'auto').
  TextColumn get model => text().nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  /// Lowercased title (+ optional content) for fast conversation search.
  TextColumn get searchText => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One message within a conversation.
@DataClassName('AiMessageRow')
class AiMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();

  /// 0 = system, 1 = user, 2 = assistant (mirrors AiRole.index).
  IntColumn get role => integer()();
  TextColumn get content => text()();

  /// 0 = done, 1 = error (mirrors AiMessageStatus persisted subset).
  IntColumn get status => integer().withDefault(const Constant(0))();
  TextColumn get error => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

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

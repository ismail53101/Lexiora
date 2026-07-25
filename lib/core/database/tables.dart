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

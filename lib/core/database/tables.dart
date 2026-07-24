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

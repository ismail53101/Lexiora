import 'dart:io';

import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/features/library/domain/entities/category.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/repositories/library_repository.dart';
import 'package:uuid/uuid.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(this._db);

  final AppDatabase _db;
  static const Uuid _uuid = Uuid();

  @override
  Stream<List<LibraryDocument>> watchAll() {
    final query = _db.select(_db.documents)
      ..orderBy([
        (t) => OrderingTerm(expression: t.importedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(_mapDocs);
  }

  @override
  Stream<List<LibraryDocument>> watchRecent({int limit = 10}) {
    final query = _db.select(_db.documents)
      ..where((t) => t.lastOpenedAt.isNotNull())
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.lastOpenedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.watch().map(_mapDocs);
  }

  @override
  Stream<List<LibraryDocument>> watchFavorites() {
    final query = _db.select(_db.documents)
      ..where((t) => t.isFavorite.equals(true))
      ..orderBy([
        (t) => OrderingTerm(expression: t.importedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(_mapDocs);
  }

  @override
  Stream<List<LibraryEntry>> watchContinueReading({int limit = 10}) {
    final query = _db.select(_db.documents).join([
      innerJoin(
        _db.readingProgress,
        _db.readingProgress.documentId.equalsExp(_db.documents.id),
      ),
    ])
      ..where(_db.readingProgress.percent.isBiggerThanValue(0.0) &
          _db.readingProgress.percent.isSmallerThanValue(1.0))
      ..orderBy([
        OrderingTerm(
          expression: _db.readingProgress.updatedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);

    return query.watch().map(
      (List<TypedResult> rows) {
        return rows.map((TypedResult row) {
          final DocumentRow d = row.readTable(_db.documents);
          final ReadingProgressRow p = row.readTable(_db.readingProgress);
          return LibraryEntry(
            document: _mapDoc(d),
            lastPage: p.lastPage,
            totalPages: p.totalPages,
            percent: p.percent,
          );
        }).toList(growable: false);
      },
    );
  }

  @override
  Stream<List<LibraryDocument>> watchByCategory(String categoryId) {
    final query = _db.select(_db.documents)
      ..where((t) => t.categoryId.equals(categoryId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.importedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(_mapDocs);
  }

  @override
  Future<LibraryDocument?> getById(String id) async {
    final DocumentRow? row = await (_db.select(_db.documents)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapDoc(row);
  }

  @override
  Future<Set<String>> existingKeys() async {
    final List<DocumentRow> rows = await _db.select(_db.documents).get();
    return rows
        .map((DocumentRow r) => libraryDedupKey(r.fileName, r.fileSize))
        .toSet();
  }

  @override
  Future<void> insert(LibraryDocument document) async {
    await _db.into(_db.documents).insert(
          DocumentsCompanion.insert(
            id: document.id,
            title: document.title,
            fileName: document.fileName,
            filePath: document.filePath,
            importedAt: document.importedAt,
            fileSize: Value(document.fileSize),
            pageCount: Value(document.pageCount),
            coverPath: Value(document.coverPath),
            categoryId: Value(document.categoryId),
            isFavorite: Value(document.isFavorite),
            lastOpenedAt: Value(document.lastOpenedAt),
            managedFile: Value(document.isManaged),
          ),
        );
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final DocumentRow? row = await (_db.select(_db.documents)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    await (_db.update(_db.documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(isFavorite: Value(!row.isFavorite)));
  }

  @override
  Future<void> rename(String id, String title) async {
    await (_db.update(_db.documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(title: Value(title)));
  }

  @override
  Future<void> updateFilePath(String id, String filePath) async {
    await (_db.update(_db.documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(filePath: Value(filePath)));
  }

  @override
  Future<void> updateCoverPath(String id, String coverPath) async {
    await (_db.update(_db.documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(coverPath: Value(coverPath)));
  }

  @override
  Future<void> assignCategory(String id, String? categoryId) async {
    await (_db.update(_db.documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(categoryId: Value(categoryId)));
  }

  @override
  Future<void> markOpened(String id) async {
    await (_db.update(_db.documents)..where((t) => t.id.equals(id)))
        .write(DocumentsCompanion(lastOpenedAt: Value(DateTime.now())));
  }

  @override
  Future<void> delete(String id) async {
    final DocumentRow? row = await (_db.select(_db.documents)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    // App-managed import copies are deleted from disk; in-place discovered
    // files (the user's own) are never removed — only the library entry is.
    if (row != null && row.managedFile) {
      try {
        final File file = File(row.filePath);
        if (file.existsSync()) file.deleteSync();
      } on Object catch (e) {
        AppLogger.w('Could not delete managed file ${row.filePath}: $e');
      }
    }
    await (_db.delete(_db.documents)..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<Category>> watchCategories() {
    final query = _db.select(_db.categories)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch().map(
          (List<CategoryRow> rows) =>
              rows.map(_mapCategory).toList(growable: false),
        );
  }

  @override
  Future<void> createCategory(String name, int colorValue) async {
    await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            id: _uuid.v4(),
            name: name,
            colorValue: colorValue,
            createdAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> deleteCategory(String id) async {
    // Detach documents from the category before removing it.
    await (_db.update(_db.documents)..where((t) => t.categoryId.equals(id)))
        .write(const DocumentsCompanion(categoryId: Value<String?>(null)));
    await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  }

  List<LibraryDocument> _mapDocs(List<DocumentRow> rows) =>
      rows.map(_mapDoc).toList(growable: false);

  LibraryDocument _mapDoc(DocumentRow r) => LibraryDocument(
        id: r.id,
        title: r.title,
        fileName: r.fileName,
        filePath: r.filePath,
        fileSize: r.fileSize,
        pageCount: r.pageCount,
        isFavorite: r.isFavorite,
        importedAt: r.importedAt,
        coverPath: r.coverPath,
        categoryId: r.categoryId,
        lastOpenedAt: r.lastOpenedAt,
        isManaged: r.managedFile,
      );

  Category _mapCategory(CategoryRow r) => Category(
        id: r.id,
        name: r.name,
        colorValue: r.colorValue,
        createdAt: r.createdAt,
      );
}

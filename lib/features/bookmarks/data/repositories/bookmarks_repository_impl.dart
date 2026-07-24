import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lexiora/features/bookmarks/domain/repositories/bookmarks_repository.dart';
import 'package:uuid/uuid.dart';

class BookmarksRepositoryImpl implements BookmarksRepository {
  BookmarksRepositoryImpl(this._db);

  final AppDatabase _db;
  static const Uuid _uuid = Uuid();

  @override
  Stream<List<Bookmark>> watchForDocument(String documentId) {
    final query = _db.select(_db.bookmarks)
      ..where((t) => t.documentId.equals(documentId))
      ..orderBy([(t) => OrderingTerm(expression: t.pageNumber)]);
    return query.watch().map(
          (List<BookmarkRow> rows) => rows.map(_mapRow).toList(growable: false),
        );
  }

  @override
  Stream<bool> watchIsPageBookmarked(String documentId, int pageNumber) {
    final query = _db.select(_db.bookmarks)
      ..where((t) =>
          t.documentId.equals(documentId) & t.pageNumber.equals(pageNumber));
    return query.watch().map((List<BookmarkRow> rows) => rows.isNotEmpty);
  }

  @override
  Future<bool> isPageBookmarked(String documentId, int pageNumber) async {
    final rows = await (_db.select(_db.bookmarks)
          ..where((t) =>
              t.documentId.equals(documentId) &
              t.pageNumber.equals(pageNumber)))
        .get();
    return rows.isNotEmpty;
  }

  @override
  Future<void> add(Bookmark bookmark) async {
    await _db.into(_db.bookmarks).insert(
          BookmarksCompanion.insert(
            id: bookmark.id,
            documentId: bookmark.documentId,
            pageNumber: bookmark.pageNumber,
            createdAt: bookmark.createdAt,
            label: Value(bookmark.label),
          ),
        );
  }

  @override
  Future<void> addPageBookmark(String documentId, int pageNumber,
      {String? label}) async {
    await add(
      Bookmark(
        id: _uuid.v4(),
        documentId: documentId,
        pageNumber: pageNumber,
        label: label,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deletePageBookmark(String documentId, int pageNumber) async {
    await (_db.delete(_db.bookmarks)
          ..where((t) =>
              t.documentId.equals(documentId) &
              t.pageNumber.equals(pageNumber)))
        .go();
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.bookmarks)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> deleteForDocument(String documentId) async {
    await (_db.delete(_db.bookmarks)
          ..where((t) => t.documentId.equals(documentId)))
        .go();
  }

  Bookmark _mapRow(BookmarkRow r) => Bookmark(
        id: r.id,
        documentId: r.documentId,
        pageNumber: r.pageNumber,
        label: r.label,
        createdAt: r.createdAt,
      );
}

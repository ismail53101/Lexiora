import 'package:lexiora/features/bookmarks/domain/entities/bookmark.dart';

/// Domain contract for bookmark persistence.
abstract interface class BookmarksRepository {
  Stream<List<Bookmark>> watchForDocument(String documentId);

  /// Reactive "is this page bookmarked" flag for the reader's toggle button.
  Stream<bool> watchIsPageBookmarked(String documentId, int pageNumber);

  Future<bool> isPageBookmarked(String documentId, int pageNumber);

  Future<void> add(Bookmark bookmark);
  Future<void> addPageBookmark(String documentId, int pageNumber,
      {String? label});
  Future<void> deletePageBookmark(String documentId, int pageNumber);
  Future<void> delete(String id);
  Future<void> deleteForDocument(String documentId);
}

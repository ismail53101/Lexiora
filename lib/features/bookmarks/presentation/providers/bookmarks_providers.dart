import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lexiora/features/bookmarks/domain/repositories/bookmarks_repository.dart';
import 'package:lexiora/features/bookmarks/domain/usecases/bookmarks_usecases.dart';

/// Key identifying a specific page within a document, for page-scoped providers.
typedef DocPageKey = ({String documentId, int page});

final Provider<BookmarksRepository> bookmarksRepositoryProvider =
    Provider<BookmarksRepository>((Ref ref) => sl<BookmarksRepository>());

final bookmarksForDocumentProvider =
    StreamProvider.family<List<Bookmark>, String>(
  (Ref ref, String documentId) =>
      WatchBookmarks(ref.watch(bookmarksRepositoryProvider)).call(documentId),
);

final isPageBookmarkedProvider = StreamProvider.family<bool, DocPageKey>(
  (Ref ref, DocPageKey key) => ref
      .watch(bookmarksRepositoryProvider)
      .watchIsPageBookmarked(key.documentId, key.page),
);

final Provider<TogglePageBookmark> togglePageBookmarkProvider =
    Provider<TogglePageBookmark>(
  (Ref ref) => TogglePageBookmark(ref.watch(bookmarksRepositoryProvider)),
);

final Provider<AddBookmarkFromSelection> addBookmarkFromSelectionProvider =
    Provider<AddBookmarkFromSelection>(
  (Ref ref) => AddBookmarkFromSelection(ref.watch(bookmarksRepositoryProvider)),
);

final Provider<DeleteBookmark> deleteBookmarkProvider =
    Provider<DeleteBookmark>(
  (Ref ref) => DeleteBookmark(ref.watch(bookmarksRepositoryProvider)),
);

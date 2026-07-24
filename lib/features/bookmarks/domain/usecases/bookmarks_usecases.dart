import 'package:lexiora/core/reader_engine/reader_models.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lexiora/features/bookmarks/domain/repositories/bookmarks_repository.dart';

/// Streams all bookmarks for a document.
class WatchBookmarks implements StreamUseCase<List<Bookmark>, String> {
  const WatchBookmarks(this._repo);
  final BookmarksRepository _repo;

  @override
  Stream<List<Bookmark>> call(String documentId) =>
      _repo.watchForDocument(documentId);
}

/// Parameters for [TogglePageBookmark].
class ToggleBookmarkParams {
  const ToggleBookmarkParams(this.documentId, this.pageNumber);
  final String documentId;
  final int pageNumber;
}

/// Adds or removes the bookmark for a page; returns the new bookmarked state.
class TogglePageBookmark implements UseCase<bool, ToggleBookmarkParams> {
  const TogglePageBookmark(this._repo);
  final BookmarksRepository _repo;

  @override
  ResultFuture<bool> call(ToggleBookmarkParams params) => guard(() async {
        final bool bookmarked =
            await _repo.isPageBookmarked(params.documentId, params.pageNumber);
        if (bookmarked) {
          await _repo.deletePageBookmark(params.documentId, params.pageNumber);
          return false;
        }
        await _repo.addPageBookmark(params.documentId, params.pageNumber);
        return true;
      });
}

/// Parameters for [AddBookmarkFromSelection].
class BookmarkSelectionParams {
  const BookmarkSelectionParams({
    required this.documentId,
    required this.selection,
  });
  final String documentId;
  final PdfTextSelectionData selection;
}

/// Creates a bookmark on the selection's primary page, labelled with a snippet
/// of the selected text.
class AddBookmarkFromSelection
    implements UseCase<void, BookmarkSelectionParams> {
  const AddBookmarkFromSelection(this._repo);
  final BookmarksRepository _repo;

  @override
  ResultFuture<void> call(BookmarkSelectionParams params) => guard(() {
        final int page = params.selection.primaryPage ?? 1;
        final String text = params.selection.text.trim();
        final String label =
            text.length > 80 ? '${text.substring(0, 80)}…' : text;
        return _repo.addPageBookmark(
          params.documentId,
          page,
          label: label.isEmpty ? null : label,
        );
      });
}

class DeleteBookmark implements UseCase<void, String> {
  const DeleteBookmark(this._repo);
  final BookmarksRepository _repo;

  @override
  ResultFuture<void> call(String id) => guard(() => _repo.delete(id));
}

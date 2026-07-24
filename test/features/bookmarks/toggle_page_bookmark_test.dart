import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lexiora/features/bookmarks/domain/repositories/bookmarks_repository.dart';
import 'package:lexiora/features/bookmarks/domain/usecases/bookmarks_usecases.dart';

class _FakeBookmarksRepo implements BookmarksRepository {
  final Set<int> pages = <int>{};

  @override
  Future<bool> isPageBookmarked(String documentId, int pageNumber) async =>
      pages.contains(pageNumber);

  @override
  Future<void> addPageBookmark(String documentId, int pageNumber,
          {String? label}) async =>
      pages.add(pageNumber);

  @override
  Future<void> deletePageBookmark(String documentId, int pageNumber) async =>
      pages.remove(pageNumber);

  @override
  Future<void> add(Bookmark bookmark) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteForDocument(String documentId) async {}

  @override
  Stream<List<Bookmark>> watchForDocument(String documentId) =>
      const Stream<List<Bookmark>>.empty();

  @override
  Stream<bool> watchIsPageBookmarked(String documentId, int pageNumber) =>
      const Stream<bool>.empty();
}

void main() {
  test('TogglePageBookmark adds then removes a page bookmark', () async {
    final _FakeBookmarksRepo repo = _FakeBookmarksRepo();
    final TogglePageBookmark usecase = TogglePageBookmark(repo);

    final added = await usecase.call(const ToggleBookmarkParams('d', 3));
    expect(added.valueOrNull, isTrue);
    expect(repo.pages.contains(3), isTrue);

    final removed = await usecase.call(const ToggleBookmarkParams('d', 3));
    expect(removed.valueOrNull, isFalse);
    expect(repo.pages.contains(3), isFalse);
  });
}

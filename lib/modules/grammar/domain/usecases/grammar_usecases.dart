import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_topic.dart';
import 'package:lexiora/modules/grammar/domain/repositories/grammar_repository.dart';

class SetCompletedParams {
  const SetCompletedParams(this.leafId, {required this.completed});
  final String leafId;
  final bool completed;
}

class FavoriteParams {
  const FavoriteParams({required this.leafId, required this.title});
  final String leafId;
  final String title;
}

/// Loads a leaf lesson's full body.
class GetLeaf implements UseCase<GrammarLesson?, String> {
  const GetLeaf(this._repo);
  final GrammarRepository _repo;
  @override
  ResultFuture<GrammarLesson?> call(String id) => guard(() => _repo.leaf(id));
}

/// Searches leaf lessons.
class SearchGrammar
    implements UseCase<List<GrammarTopicSummary>, String> {
  const SearchGrammar(this._repo);
  final GrammarRepository _repo;
  @override
  ResultFuture<List<GrammarTopicSummary>> call(String query) =>
      guard(() => _repo.search(query));
}

class MarkLessonViewed implements UseCase<void, String> {
  const MarkLessonViewed(this._repo);
  final GrammarRepository _repo;
  @override
  ResultVoid call(String leafId) => guard(() => _repo.markViewed(leafId));
}

class SetLessonCompleted implements UseCase<void, SetCompletedParams> {
  const SetLessonCompleted(this._repo);
  final GrammarRepository _repo;
  @override
  ResultVoid call(SetCompletedParams params) => guard(
        () => _repo.setCompleted(params.leafId, completed: params.completed),
      );
}

class ToggleLessonFavorite implements UseCase<bool, FavoriteParams> {
  const ToggleLessonFavorite(this._repo);
  final GrammarRepository _repo;
  @override
  ResultFuture<bool> call(FavoriteParams params) => guard(() async {
        final bool currently = await _repo.isFavorite(params.leafId);
        if (currently) {
          await _repo.removeFavorite(params.leafId);
          return false;
        }
        await _repo.addFavorite(leafId: params.leafId, title: params.title);
        return true;
      });
}

/// Streams the children of a node (null = top-level categories).
class WatchChildren
    implements StreamUseCase<List<GrammarTopicSummary>, String?> {
  const WatchChildren(this._repo);
  final GrammarRepository _repo;
  @override
  Stream<List<GrammarTopicSummary>> call(String? parentId) =>
      _repo.watchChildren(parentId);
}

class WatchContinueLearning
    implements StreamUseCase<List<GrammarTopicSummary>, NoParams> {
  const WatchContinueLearning(this._repo);
  final GrammarRepository _repo;
  @override
  Stream<List<GrammarTopicSummary>> call(NoParams params) =>
      _repo.watchContinueLearning();
}

class WatchRecentLessons
    implements StreamUseCase<List<GrammarTopicSummary>, NoParams> {
  const WatchRecentLessons(this._repo);
  final GrammarRepository _repo;
  @override
  Stream<List<GrammarTopicSummary>> call(NoParams params) => _repo.watchRecent();
}

class WatchFavoriteLessons
    implements StreamUseCase<List<GrammarTopicSummary>, NoParams> {
  const WatchFavoriteLessons(this._repo);
  final GrammarRepository _repo;
  @override
  Stream<List<GrammarTopicSummary>> call(NoParams params) =>
      _repo.watchFavorites();
}

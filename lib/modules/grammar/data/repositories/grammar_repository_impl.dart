import 'package:lexiora/modules/grammar/data/datasources/grammar_local_data_source.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_topic.dart';
import 'package:lexiora/modules/grammar/domain/repositories/grammar_repository.dart';

/// [GrammarRepository] backed by the local database via [GrammarLocalDataSource].
class GrammarRepositoryImpl implements GrammarRepository {
  GrammarRepositoryImpl(this._local);

  final GrammarLocalDataSource _local;

  @override
  Stream<List<GrammarTopicSummary>> watchChildren(String? parentId) =>
      _local.watchChildren(parentId);

  @override
  Future<List<GrammarTopicSummary>> children(String? parentId) =>
      _local.children(parentId);

  @override
  Future<String?> topicTitle(String id) => _local.topicTitle(id);

  @override
  Future<GrammarLesson?> leaf(String id) => _local.leaf(id);

  @override
  Future<List<GrammarTopicSummary>> search(String query) =>
      _local.search(query);

  @override
  Stream<List<GrammarTopicSummary>> watchContinueLearning() =>
      _local.watchContinueLearning();

  @override
  Stream<List<GrammarTopicSummary>> watchRecent() => _local.watchRecent();

  @override
  Stream<List<GrammarTopicSummary>> watchFavorites() => _local.watchFavorites();

  @override
  Future<void> markViewed(String leafId) => _local.markViewed(leafId);

  @override
  Future<void> setCompleted(String leafId, {required bool completed}) =>
      _local.setCompleted(leafId, completed: completed);

  @override
  Stream<GrammarProgressStatus> watchStatus(String leafId) =>
      _local.watchStatus(leafId);

  @override
  Future<bool> isFavorite(String leafId) => _local.isFavorite(leafId);

  @override
  Stream<bool> watchIsFavorite(String leafId) =>
      _local.watchIsFavorite(leafId);

  @override
  Future<void> addFavorite({required String leafId, required String title}) =>
      _local.addFavorite(leafId: leafId, title: title);

  @override
  Future<void> removeFavorite(String leafId) => _local.removeFavorite(leafId);

  @override
  Future<int> topicCount() => _local.topicCount();
}

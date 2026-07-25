import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_topic.dart';

/// Domain contract for the offline Grammar tree (Category → Subcategory →
/// Lesson). Navigation reads children of a node; leaves resolve a full lesson.
/// Progress and favorites are keyed by a leaf's topic id.
abstract interface class GrammarRepository {
  /// Reactive children of [parentId] (null = top-level categories).
  Stream<List<GrammarTopicSummary>> watchChildren(String? parentId);

  /// One-shot children of [parentId].
  Future<List<GrammarTopicSummary>> children(String? parentId);

  /// The display title of a node (for app-bar breadcrumbs).
  Future<String?> topicTitle(String id);

  /// The full lesson for a leaf, or null when the id is not a leaf.
  Future<GrammarLesson?> leaf(String id);

  /// Leaf lessons matching [query].
  Future<List<GrammarTopicSummary>> search(String query);

  Stream<List<GrammarTopicSummary>> watchContinueLearning();
  Stream<List<GrammarTopicSummary>> watchRecent();
  Stream<List<GrammarTopicSummary>> watchFavorites();

  Future<void> markViewed(String leafId);
  Future<void> setCompleted(String leafId, {required bool completed});
  Stream<GrammarProgressStatus> watchStatus(String leafId);

  Future<bool> isFavorite(String leafId);
  Stream<bool> watchIsFavorite(String leafId);
  Future<void> addFavorite({required String leafId, required String title});
  Future<void> removeFavorite(String leafId);

  /// Total number of seeded topic nodes (diagnostics).
  Future<int> topicCount();
}

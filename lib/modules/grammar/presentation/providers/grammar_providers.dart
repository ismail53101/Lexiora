import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/grammar/data/grammar_seeder.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_topic.dart';
import 'package:lexiora/modules/grammar/domain/repositories/grammar_repository.dart';
import 'package:lexiora/modules/grammar/domain/usecases/grammar_usecases.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final Provider<GrammarRepository> grammarRepositoryProvider =
    Provider<GrammarRepository>((Ref ref) => sl<GrammarRepository>());

final Provider<GrammarSeeder> grammarSeederProvider =
    Provider<GrammarSeeder>((Ref ref) => sl<GrammarSeeder>());

/// Kicks off (idempotent) seeding; best-effort so a failure never blocks the UI.
final FutureProvider<void> grammarSeedProvider = FutureProvider<void>((Ref ref) async {
  try {
    await ref.watch(grammarSeederProvider).ensureSeeded();
  } on Object {
    // The tree simply won't be available this run.
  }
});

// ── Use cases ─────────────────────────────────────────────────────────────────

final Provider<GetLeaf> getLeafProvider =
    Provider<GetLeaf>((Ref ref) => GetLeaf(ref.watch(grammarRepositoryProvider)));

final Provider<SearchGrammar> searchGrammarProvider = Provider<SearchGrammar>(
  (Ref ref) => SearchGrammar(ref.watch(grammarRepositoryProvider)),
);

final Provider<MarkLessonViewed> markLessonViewedProvider =
    Provider<MarkLessonViewed>(
  (Ref ref) => MarkLessonViewed(ref.watch(grammarRepositoryProvider)),
);

final Provider<SetLessonCompleted> setLessonCompletedProvider =
    Provider<SetLessonCompleted>(
  (Ref ref) => SetLessonCompleted(ref.watch(grammarRepositoryProvider)),
);

final Provider<ToggleLessonFavorite> toggleLessonFavoriteProvider =
    Provider<ToggleLessonFavorite>(
  (Ref ref) => ToggleLessonFavorite(ref.watch(grammarRepositoryProvider)),
);

// ── Navigation (tree) ─────────────────────────────────────────────────────────

/// Children of a node; pass null for the top-level categories.
final grammarChildrenProvider =
    StreamProvider.family<List<GrammarTopicSummary>, String?>(
        (Ref ref, String? parentId) {
  ref.watch(grammarSeedProvider);
  return WatchChildren(ref.watch(grammarRepositoryProvider)).call(parentId);
});

final grammarContinueProvider = StreamProvider<List<GrammarTopicSummary>>(
  (Ref ref) {
    ref.watch(grammarSeedProvider);
    return WatchContinueLearning(ref.watch(grammarRepositoryProvider))
        .call(const NoParams());
  },
);

final grammarRecentProvider = StreamProvider<List<GrammarTopicSummary>>(
  (Ref ref) {
    ref.watch(grammarSeedProvider);
    return WatchRecentLessons(ref.watch(grammarRepositoryProvider))
        .call(const NoParams());
  },
);

final grammarFavoritesProvider = StreamProvider<List<GrammarTopicSummary>>(
  (Ref ref) {
    ref.watch(grammarSeedProvider);
    return WatchFavoriteLessons(ref.watch(grammarRepositoryProvider))
        .call(const NoParams());
  },
);

/// Full leaf lesson (Lesson screen). Ensures seeding first.
final grammarLeafProvider = FutureProvider.family<GrammarLesson?, String>(
  (Ref ref, String id) async {
    await ref.watch(grammarSeederProvider).ensureSeeded();
    final result = await ref.watch(getLeafProvider).call(id);
    return result.fold(
      (failure) => throw StateError(failure.message),
      (GrammarLesson? lesson) => lesson,
    );
  },
);

/// Node title (for the Topic screen app bar).
final grammarTopicTitleProvider = FutureProvider.family<String?, String>(
  (Ref ref, String id) async {
    await ref.watch(grammarSeederProvider).ensureSeeded();
    return ref.watch(grammarRepositoryProvider).topicTitle(id);
  },
);

final isLeafFavoriteProvider = StreamProvider.family<bool, String>(
  (Ref ref, String id) =>
      ref.watch(grammarRepositoryProvider).watchIsFavorite(id),
);

final leafStatusProvider =
    StreamProvider.family<GrammarProgressStatus, String>(
  (Ref ref, String id) => ref.watch(grammarRepositoryProvider).watchStatus(id),
);

// ── Search ────────────────────────────────────────────────────────────────────

/// Holds the current grammar search query (modern Notifier, not the legacy
/// StateProvider which Riverpod 3 moved out of the main library).
class GrammarQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final NotifierProvider<GrammarQuery, String> grammarQueryProvider =
    NotifierProvider<GrammarQuery, String>(GrammarQuery.new);

final grammarSearchResultsProvider =
    FutureProvider<List<GrammarTopicSummary>>((Ref ref) async {
  final String q = ref.watch(grammarQueryProvider).trim();
  if (q.isEmpty) return const <GrammarTopicSummary>[];
  await ref.watch(grammarSeederProvider).ensureSeeded();
  final result = await ref.watch(searchGrammarProvider).call(q);
  return result.fold(
    (failure) => throw StateError(failure.message),
    (List<GrammarTopicSummary> list) => list,
  );
});

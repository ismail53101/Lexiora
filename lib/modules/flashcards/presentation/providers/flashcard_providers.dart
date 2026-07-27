import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/modules/flashcards/data/services/flashcard_export_service.dart';
import 'package:lexiora/modules/flashcards/domain/entities/deck.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/flashcard_repository.dart';

final Provider<FlashcardRepository> flashcardRepositoryProvider =
    Provider<FlashcardRepository>((Ref ref) => sl<FlashcardRepository>());

final decksProvider = StreamProvider.family<List<DeckSummary>, bool>(
    (Ref ref, bool archived) =>
        ref.watch(flashcardRepositoryProvider).watchDecks(includeArchived: archived));

final StreamProvider<ReviewQueue> reviewQueueProvider =
    StreamProvider<ReviewQueue>(
        (Ref ref) => ref.watch(flashcardRepositoryProvider).watchReviewQueue());

final StreamProvider<FlashcardStats> flashcardStatsProvider =
    StreamProvider<FlashcardStats>(
        (Ref ref) => ref.watch(flashcardRepositoryProvider).watchStats());

final StreamProvider<List<Flashcard>> difficultCardsProvider =
    StreamProvider<List<Flashcard>>((Ref ref) =>
        ref.watch(flashcardRepositoryProvider).watchDifficultCards());

final StreamProvider<List<ReviewActivity>> recentActivityProvider =
    StreamProvider<List<ReviewActivity>>((Ref ref) =>
        ref.watch(flashcardRepositoryProvider).watchRecentActivity());

final StreamProvider<Map<String, int>> fcSubjectColorsProvider =
    StreamProvider<Map<String, int>>(
        (Ref ref) => ref.watch(flashcardRepositoryProvider).watchSubjectColors());

final fcSubjectSuggestionsProvider = FutureProvider.autoDispose<List<String>>(
    (Ref ref) => ref.watch(flashcardRepositoryProvider).subjectSuggestions());

final fcTagSuggestionsProvider = FutureProvider.autoDispose<List<String>>(
    (Ref ref) => ref.watch(flashcardRepositoryProvider).tagSuggestions());

final Provider<FlashcardExportService> fcExportServiceProvider =
    Provider<FlashcardExportService>((Ref ref) => const FlashcardExportService());

/// The current card search/filter.
class FlashcardFilterNotifier extends Notifier<FlashcardFilter> {
  @override
  FlashcardFilter build() => const FlashcardFilter();
  void set(FlashcardFilter f) => state = f;
  void setQuery(String q) => state = state.copyWith(query: q);
  void reset() => state = const FlashcardFilter();
}

final NotifierProvider<FlashcardFilterNotifier, FlashcardFilter>
    flashcardFilterProvider =
    NotifierProvider<FlashcardFilterNotifier, FlashcardFilter>(
        FlashcardFilterNotifier.new);

/// Bumped after any card/deck mutation so paginated (non-stream) lists reload.
class FcRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state = state + 1;
}

final NotifierProvider<FcRevision, int> fcRevisionProvider =
    NotifierProvider<FcRevision, int>(FcRevision.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/pronunciation_service.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/modules/vocabulary/data/vocabulary_seeder.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_list.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';
import 'package:lexiora/modules/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:lexiora/modules/vocabulary/domain/usecases/vocabulary_usecases.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final Provider<VocabularyRepository> vocabularyRepositoryProvider =
    Provider<VocabularyRepository>((Ref ref) => sl<VocabularyRepository>());

final Provider<VocabularySeeder> vocabularySeederProvider =
    Provider<VocabularySeeder>((Ref ref) => sl<VocabularySeeder>());

/// Kicks off (idempotent) seeding; best-effort so a failure never blocks the UI.
final FutureProvider<void> vocabularySeedProvider =
    FutureProvider<void>((Ref ref) async {
  try {
    await ref.watch(vocabularySeederProvider).ensureSeeded();
  } on Object {
    // The lists simply won't be available this run.
  }
});

/// On-device TTS for the pronunciation button. Reuses the shared core service.
final Provider<PronunciationService> vocabularyPronunciationServiceProvider =
    Provider<PronunciationService>((Ref ref) => sl<PronunciationService>());

// ── Reads ─────────────────────────────────────────────────────────────────────

final StreamProvider<List<VocabularyListSummary>> vocabularyListsProvider =
    StreamProvider<List<VocabularyListSummary>>((Ref ref) {
  ref.watch(vocabularySeedProvider);
  return WatchVocabularyLists(ref.watch(vocabularyRepositoryProvider))
      .call(const NoParams());
});

final vocabularyWordsProvider =
    StreamProvider.family<List<VocabularyWord>, String>(
        (Ref ref, String listId) {
  ref.watch(vocabularySeedProvider);
  return WatchVocabularyWords(ref.watch(vocabularyRepositoryProvider))
      .call(listId);
});

// ── Search ────────────────────────────────────────────────────────────────────

/// Holds the current search query for the open word list (English or Urdu).
class VocabularyQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final NotifierProvider<VocabularyQuery, String> vocabularyQueryProvider =
    NotifierProvider<VocabularyQuery, String>(VocabularyQuery.new);

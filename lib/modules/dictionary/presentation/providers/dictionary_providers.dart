import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/pronunciation_service.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/dictionary/data/dictionary_seeder.dart';
import 'package:lexiora/modules/dictionary/data/exam_words_seeder.dart';
import 'package:lexiora/modules/dictionary/data/services/ai_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/data/services/stands4_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/dictionary_usecases.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/get_word_profile.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/usage_relevance.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final Provider<DictionaryRepository> dictionaryRepositoryProvider =
    Provider<DictionaryRepository>((Ref ref) => sl<DictionaryRepository>());

final Provider<DictionarySeeder> dictionarySeederProvider =
    Provider<DictionarySeeder>((Ref ref) => sl<DictionarySeeder>());

// ── Use cases ─────────────────────────────────────────────────────────────────

final Provider<SearchDictionary> searchDictionaryProvider =
    Provider<SearchDictionary>(
  (Ref ref) => SearchDictionary(ref.watch(dictionaryRepositoryProvider)),
);

final Provider<GetWordDetails> getWordDetailsProvider =
    Provider<GetWordDetails>(
  (Ref ref) => GetWordDetails(ref.watch(dictionaryRepositoryProvider)),
);

final Provider<LookUpWord> lookUpWordProvider = Provider<LookUpWord>(
  (Ref ref) => LookUpWord(ref.watch(dictionaryRepositoryProvider)),
);

final Provider<ToggleWordFavorite> toggleWordFavoriteProvider =
    Provider<ToggleWordFavorite>(
  (Ref ref) => ToggleWordFavorite(ref.watch(dictionaryRepositoryProvider)),
);

// ── Reactive queries ──────────────────────────────────────────────────────────

/// Streams the saved-words list (most recently saved first).
final StreamProvider<List<DictionaryResult>> favoritesProvider =
    StreamProvider<List<DictionaryResult>>(
  (Ref ref) => WatchFavorites(ref.watch(dictionaryRepositoryProvider))
      .call(const NoParams()),
);

/// Reactive favorite state for a single word (keeps the ⭐ in sync everywhere).
final isWordFavoriteProvider = StreamProvider.family<bool, String>(
  (Ref ref, String wordLower) =>
      ref.watch(dictionaryRepositoryProvider).watchIsFavorite(wordLower),
);

/// Loads all senses for a headword (Word Details screen). Ensures the
/// dictionary is seeded first, so deep links / cold opens still work.
final wordDetailsProvider = FutureProvider.family<WordDetails?, String>(
  (Ref ref, String wordLower) async {
    await ref.watch(dictionarySeederProvider).ensureSeeded();
    final result =
        await ref.watch(getWordDetailsProvider).call(wordLower);
    return result.fold(
      (failure) => throw StateError(failure.message),
      (WordDetails? details) => details,
    );
  },
);

/// Primary-sense lookup for the lightweight reader popup. Ensures the
/// dictionary is seeded (handles first use from the reader before the
/// Dictionary screen has ever been opened).
final wordLookupProvider = FutureProvider.family<DictionaryResult?, String>(
  (Ref ref, String wordLower) async {
    await ref.watch(dictionarySeederProvider).ensureSeeded();
    final result = await ref.watch(lookUpWordProvider).call(wordLower);
    return result.fold(
      (failure) => throw StateError(failure.message),
      (DictionaryResult? r) => r,
    );
  },
);

// ── Dictionary v2 ─────────────────────────────────────────────────────────────

final Provider<ExamWordsSeeder> examWordsSeederProvider =
    Provider<ExamWordsSeeder>((Ref ref) => sl<ExamWordsSeeder>());

final Provider<GetWordProfile> getWordProfileProvider =
    Provider<GetWordProfile>(
  (Ref ref) => GetWordProfile(
    ref.watch(dictionaryRepositoryProvider),
    sl<AiDictionaryService>(),
    sl<Stands4DictionaryService>(),
  ),
);

/// Aggregated, offline word profile: curated exam data + base senses + derived
/// related words. Seeding is best-effort so a missing pack never breaks the
/// screen. Urdu meanings (hybrid) and bookmark state come from their own
/// providers.
final wordProfileProvider = FutureProvider.family<WordProfile, String>(
  (Ref ref, String wordLower) async {
    try {
      await ref.watch(dictionarySeederProvider).ensureSeeded();
    } on Object {
      // Base dictionary unavailable this run; profile degrades gracefully.
    }
    try {
      await ref.watch(examWordsSeederProvider).ensureSeeded();
    } on Object {
      // Curated pack is optional.
    }
    final result = await ref.watch(getWordProfileProvider).call(wordLower);
    return result.fold(
      (failure) => throw StateError(failure.message),
      (WordProfile profile) => profile,
    );
  },
);

/// Loads only the missing dictionary fields through AI in the background.
/// The local profile is never blocked by this provider.
final wordAiEnrichmentProvider =
    FutureProvider.family<AiWordProfile?, String>(
  (Ref ref, String wordLower) async {
    final WordProfile profile =
        await ref.watch(wordProfileProvider(wordLower).future);

    // AI is strictly a fallback for words absent from the local JSON-backed
    // dictionary. Existing local words may use STANDS4 for synonym enrichment,
    // but must never trigger an AI dictionary request for missing fields.
    if (profile.existsLocally) return null;

    final ExamWordData? exam = profile.exam;
    final WordDetails? base = profile.base;
    final List<String> missing = <String>[];

    final bool hasEnglish =
        (exam?.englishDefinition?.trim().isNotEmpty == true) ||
        (base?.primary?.meaning.trim().isNotEmpty == true);
    final bool hasUrdu = exam?.urduMeanings.isNotEmpty == true;
    final bool hasSynonyms = exam?.synonyms.isNotEmpty == true;
    final bool hasAntonyms = exam?.antonyms.isNotEmpty == true;
    final bool hasExample =
        validatedUsage(profile.wordLower, exam?.usage) != null ||
        base?.primary?.exampleSentence?.trim().isNotEmpty == true;
    final bool hasCollocations = exam?.collocations.isNotEmpty == true;
    final bool hasWordForms =
        exam?.wordForms.isNotEmpty == true || profile.relatedWords.isNotEmpty;
    final bool hasExamNote = exam?.examNote?.trim().isNotEmpty == true;

    if (!hasEnglish) missing.add('englishDefinition');
    if (!hasUrdu) missing.add('urduMeanings');
    if (!hasSynonyms) missing.add('synonyms');
    if (!hasAntonyms) missing.add('antonyms');
    if (!hasExample) {
      missing.add('exampleSentence');
      missing.add('exampleSentenceUrdu');
    }
    if (!hasCollocations) missing.add('collocations');
    if (!hasWordForms) missing.add('wordForms');
    if (!hasExamNote) missing.add('examNote');

    if (missing.isEmpty) return null;

    return sl<AiDictionaryService>().define(
      wordLower,
      missingFields: missing,
    );
  },
);

/// Reactive recent searches (most recent first).
final recentSearchesProvider = StreamProvider<List<String>>(
  (Ref ref) => ref.watch(dictionaryRepositoryProvider).watchRecentSearches(),
);

/// On-device audio pronunciation (TTS) service.
final Provider<PronunciationService> pronunciationServiceProvider =
    Provider<PronunciationService>((Ref ref) => sl<PronunciationService>());

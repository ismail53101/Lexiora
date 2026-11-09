import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
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
    } on Object {}
    try {
      await ref.watch(examWordsSeederProvider).ensureSeeded();
    } on Object {}

    final String wl = wordLower.trim().toLowerCase();
    final result = await ref.watch(getWordProfileProvider).call(wl);
    final WordProfile profile = result.fold(
      (failure) => throw StateError(failure.message),
      (WordProfile value) => value,
    );
    final AiWordProfile? cached =
        await ref.watch(dictionaryRepositoryProvider).cachedAiProfile(wl);
    return profile.copyWith(ai: cached);
  },
);

/// Enriches only a genuinely missing word automatically. For words already in
/// the bundled dictionary, AI enrichment is explicit via the AI button in the
/// details screen. Cached results are always returned without a network call.
final wordAiEnrichmentProvider =
    FutureProvider.family<AiWordProfile?, String>(
  (Ref ref, String wordLower) async {
    final String wl = wordLower.trim().toLowerCase();
    final DictionaryRepository repo = ref.watch(dictionaryRepositoryProvider);
    final AiWordProfile? cached = await repo.cachedAiProfile(wl);
    if (cached != null) return cached;

    final WordProfile profile = await ref.watch(wordProfileProvider(wl).future);
    if (profile.existsLocally) return null;

    final AiWordProfile? online = await _fetchDictionaryEnrichment(wl, ref);
    if (online != null) {
      await repo.saveAiProfile(online);
    }
    return online;
  },
);

/// Explicitly fetches/refreshes AI + online dictionary data and persists it.
/// Used by the AI icon on words that already have bundled offline content.
final FutureProviderFamily<AiWordProfile?, String> dictionaryAiRefreshProvider =
    FutureProvider.family<AiWordProfile?, String>((Ref ref, String wordLower) async {
  final String wl = wordLower.trim().toLowerCase();
  final AiWordProfile? online = await _fetchDictionaryEnrichment(wl, ref);
  if (online != null) {
    await ref.read(dictionaryRepositoryProvider).saveAiProfile(online);
  }
  return online;
});

Future<AiWordProfile?> _fetchDictionaryEnrichment(
  String wordLower,
  Ref ref,
) async {
  final Stands4DictionaryService stands4 = sl<Stands4DictionaryService>();
  final AiDictionaryService aiService = sl<AiDictionaryService>();
  final AiWordProfile? online = await stands4.define(wordLower);

  final List<String> aiFields = <String>[
    'englishDefinition',
    'urduMeanings',
    'partOfSpeech',
    'synonyms',
    'antonyms',
    'exampleSentence',
    'exampleSentenceUrdu',
    'collocations',
    'wordForms',
    'examNote',
  ];
  if (online != null) {
    aiFields.removeWhere((String field) {
      if (field == 'synonyms') return online.synonyms.isNotEmpty;
      if (field == 'antonyms') return online.antonyms.isNotEmpty;
      if (field == 'englishDefinition') return online.englishDefinition != null;
      if (field == 'partOfSpeech') return online.partOfSpeech != null;
      return false;
    });
  }
  final AiWordProfile? ai = aiFields.isEmpty
      ? null
      : await aiService.define(wordLower, missingFields: aiFields);

  if (online == null && ai == null) return null;
  final AiWordProfile merged = AiWordProfile(
    word: wordLower,
    source: online != null && ai != null
        ? 'stands4+ai'
        : online != null
            ? 'stands4'
            : 'ai',
    englishDefinition: ai?.englishDefinition ?? online?.englishDefinition,
    urduMeanings: ai?.urduMeanings.isNotEmpty == true
        ? ai!.urduMeanings
        : online?.urduMeanings ?? const <String>[],
    partOfSpeech: ai?.partOfSpeech ?? online?.partOfSpeech,
    synonyms: online?.synonyms.isNotEmpty == true
        ? online!.synonyms
        : ai?.synonyms ?? const <String>[],
    antonyms: online?.antonyms.isNotEmpty == true
        ? online!.antonyms
        : ai?.antonyms ?? const <String>[],
    exampleSentence: ai?.exampleSentence ?? online?.exampleSentence,
    exampleSentenceUrdu: ai?.exampleSentenceUrdu ?? online?.exampleSentenceUrdu,
    collocations: ai?.collocations.isNotEmpty == true
        ? ai!.collocations
        : online?.collocations ?? const <String>[],
    wordForms: ai?.wordForms.isNotEmpty == true
        ? ai!.wordForms
        : online?.wordForms ?? const <String>[],
    examNote: ai?.examNote ?? online?.examNote,
  );
  return merged.hasContent ? merged : null;
}

/// Reactive recent searches (most recent first).
final recentSearchesProvider = StreamProvider<List<String>>(
  (Ref ref) => ref.watch(dictionaryRepositoryProvider).watchRecentSearches(),
);

/// On-device audio pronunciation (TTS) service.
final Provider<PronunciationService> pronunciationServiceProvider =
    Provider<PronunciationService>((Ref ref) => sl<PronunciationService>());

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/pronunciation_service.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/dictionary/data/dictionary_seeder.dart';
import 'package:lexiora/modules/dictionary/data/exam_words_seeder.dart';
import 'package:lexiora/modules/dictionary/data/services/ai_dictionary_cache.dart';
import 'package:lexiora/modules/dictionary/data/services/ai_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/data/services/online_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/data/services/stands4_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/translation/domain/repositories/translation_repository.dart';
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

/// Supplements only fields absent from the local DarsNexa dictionary. The
/// network result is intentionally kept outside the database and is discarded
/// when unavailable, so offline/local behavior remains unchanged.
final freeDictionaryEnrichmentProvider =
    FutureProvider.family<FreeDictionaryProfile?, String>(
  (Ref ref, String wordLower) async {
    final WordProfile profile =
        await ref.watch(wordProfileProvider(wordLower).future);
    final bool needsSupplement =
        !profile.existsLocally ||
        profile.englishDefinition == null ||
        profile.pronunciation == null ||
        profile.partOfSpeech == null ||
        profile.base?.primary?.exampleSentence == null;
    if (!needsSupplement) return null;

    final OnlineDefinition? online =
        await sl<OnlineDictionaryService>().define(wordLower);
    if (online == null) return null;
    final List<FreeDictionarySense> senses = <FreeDictionarySense>[];
    final Set<String> seen = <String>{};
    void addSense(String meaning, String? pos, String? example) {
      final String key = meaning.trim();
      if (key.isEmpty || !seen.add(key)) return;
      senses.add(FreeDictionarySense(
        meaning: key,
        partOfSpeech: pos,
        example: example,
      ));
    }
    // The service chooses the best general definition for the lightweight
    // translation path; place it first for the profile too.
    addSense(online.meaning, online.partOfSpeech, null);
    for (final OnlineSense sense in online.senses) {
      addSense(sense.meaning, sense.partOfSpeech, sense.example);
    }
    if (senses.isEmpty) return null;
    return FreeDictionaryProfile(
      word: wordLower.trim(),
      senses: senses,
      phonetic: online.phonetic,
      audioUrl: online.audioUrl,
      synonyms: online.synonyms,
      antonyms: online.antonyms,
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

    final bool existsOffline = profile.existsLocally;
    final TranslationRepository translations = sl<TranslationRepository>();

    // Bundled/offline Urdu is authoritative. If it exists, this provider must
    // not call AI at all — even if the offline entry is missing other fields.
    final String? localUrdu =
        await translations.translate(wordLower, 'ur');
    final bool hasOfflineUrdu =
        (profile.exam?.urduMeanings.isNotEmpty == true) ||
        (localUrdu != null &&
            localUrdu.trim().isNotEmpty &&
            !(await translations.isCached(wordLower, 'ur')));

    if (existsOffline && hasOfflineUrdu) {
      return null;
    }

    final AiDictionaryCache cache = sl<AiDictionaryCache>();

    // A locally-known word is allowed only one AI gap: Urdu. Never enrich its
    // synonyms, antonyms, examples, collocations, etc.
    if (existsOffline) {
      final AiWordProfile? cached = await cache.get(wordLower);
      if (cached != null && cached.urduMeanings.isNotEmpty) {
        return AiWordProfile(
          word: cached.word,
          source: 'ai',
          urduMeanings: cached.urduMeanings,
        );
      }

      final AiWordProfile? generated = await sl<AiDictionaryService>().define(
        wordLower,
        missingFields: const <String>['urduMeanings'],
      );
      if (generated != null && generated.urduMeanings.isNotEmpty) {
        await cache.put(
          AiWordProfile(
            word: generated.word,
            source: 'ai',
            urduMeanings: generated.urduMeanings,
          ),
        );
        return generated;
      }
      return null;
    }

    // The word is genuinely absent from offline data: AI can provide the
    // complete lightweight fallback profile.
    final AiWordProfile? cached = await cache.get(wordLower);
    if (cached != null) return cached;

    final AiWordProfile? generated = await sl<AiDictionaryService>().define(
      wordLower,
      missingFields: const <String>[
        'englishDefinition',
        'urduMeanings',
        'synonyms',
        'antonyms',
        'exampleSentence',
        'exampleSentenceUrdu',
      ],
    );

    if (generated != null && generated.hasContent) {
      await cache.put(generated);
    }
    return generated;
  },
);

/// Reactive recent searches (most recent first).
final recentSearchesProvider = StreamProvider<List<String>>(
  (Ref ref) => ref.watch(dictionaryRepositoryProvider).watchRecentSearches(),
);

/// On-device audio pronunciation (TTS) service.
final Provider<PronunciationService> pronunciationServiceProvider =
    Provider<PronunciationService>((Ref ref) => sl<PronunciationService>());

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
    final String query = wordLower.trim().toLowerCase();
    if (query.isEmpty) return null;

    final AiDictionaryCache cache = sl<AiDictionaryCache>();
    AiWordProfile? merged;

    // First reuse any previously generated profile, but only as an enrichment
    // source. Existing offline/curated fields always remain authoritative.
    final AiWordProfile? cached = await cache.get(query);
    if (cached != null) {
      merged = cached;
    }

    // Build the exact gaps that still exist after local data + cache.
    Future<List<String>> missingFields(AiWordProfile? extra) async {
      bool hasText(String? value) => value != null && value.trim().isNotEmpty;
      bool hasList(List<String> value) => value.isNotEmpty;

      final List<String> missing = <String>[];

      final bool hasDefinition =
          profile.englishDefinition != null ||
          hasText(extra?.englishDefinition);
      final bool hasPos =
          profile.partOfSpeech != null || hasText(extra?.partOfSpeech);
      final bool hasSynonyms =
          profile.synonyms.isNotEmpty || hasList(extra?.synonyms ?? const <String>[]);
      final bool hasAntonyms =
          profile.antonyms.isNotEmpty || hasList(extra?.antonyms ?? const <String>[]);
      final bool hasExample =
          profile.base?.primary?.exampleSentence != null ||
          hasText(extra?.exampleSentence);
      final bool hasCollocations =
          profile.collocations.isNotEmpty ||
          hasList(extra?.collocations ?? const <String>[]);
      final bool hasWordForms =
          (profile.exam?.wordForms.isNotEmpty == true) ||
          profile.relatedWords.isNotEmpty ||
          hasList(extra?.wordForms ?? const <String>[]);
      final bool hasExamNote =
          profile.exam?.examNote != null || hasText(extra?.examNote);

      if (!hasDefinition) missing.add('englishDefinition');
      if (!hasPos) missing.add('partOfSpeech');
      if (!hasSynonyms) missing.add('synonyms');
      if (!hasAntonyms) missing.add('antonyms');
      if (!hasExample) missing.add('exampleSentence');
      if (!hasCollocations) missing.add('collocations');
      if (!hasWordForms) missing.add('wordForms');
      if (!hasExamNote) missing.add('examNote');

      final TranslationRepository translations = sl<TranslationRepository>();
      // Urdu is authoritative when bundled/cached locally. Only request AI
      // Urdu when the offline profile truly has no Urdu meaning.
      final String? localUrdu =
          await translations.translate(query, 'ur');
      final bool hasUrdu =
          profile.exam?.urduMeanings.isNotEmpty == true ||
          (localUrdu != null &&
              localUrdu.trim().isNotEmpty &&
              !(await translations.isCached(query, 'ur'))) ||
          (extra?.urduMeanings.isNotEmpty == true);
      if (!hasUrdu) missing.add('urduMeanings');

      return missing;
    }

    // STANDS4 is deliberately checked before AI. In particular, if local
    // synonyms or antonyms are absent, STANDS4 gets the first chance to fill
    // them. Existing STANDS4 credentials remain behind the Cloudflare Worker.
    List<String> missing = await missingFields(merged);
    final bool needsStands4 = missing.isNotEmpty &&
        <String>{
          'englishDefinition',
          'partOfSpeech',
          'synonyms',
          'antonyms',
          'exampleSentence',
          'collocations',
          'wordForms',
          'examNote',
        }.any(missing.contains);

    if (needsStands4) {
      try {
        final AiWordProfile? stands4 =
            await sl<Stands4DictionaryService>().define(query);
        if (stands4 != null && stands4.hasContent) {
          merged = merged == null ? stands4 : merged.mergeMissing(stands4);
        }
      } on Object {
        // STANDS4 is optional. Continue to AI without surfacing a network error.
      }
    }

    // Recalculate after STANDS4. AI receives only the fields that are still
    // genuinely absent, so it does not overwrite or duplicate good data.
    missing = await missingFields(merged);
    if (missing.isEmpty) {
      return merged;
    }

    final AiWordProfile? generated =
        await sl<AiDictionaryService>().define(
      query,
      missingFields: missing,
    );

    if (generated != null && generated.hasContent) {
      merged = merged == null ? generated : merged.mergeMissing(generated);
      // Keep the existing cache behavior for AI-generated data. STANDS4 data
      // is not persisted here because it is an external API result.
      if (generated.source == 'ai') {
        await cache.put(generated);
      }
    }

    return merged;
  },
);

/// Reactive recent searches (most recent first).
final recentSearchesProvider = StreamProvider<List<String>>(
  (Ref ref) => ref.watch(dictionaryRepositoryProvider).watchRecentSearches(),
);

/// On-device audio pronunciation (TTS) service.
final Provider<PronunciationService> pronunciationServiceProvider =
    Provider<PronunciationService>((Ref ref) => sl<PronunciationService>());

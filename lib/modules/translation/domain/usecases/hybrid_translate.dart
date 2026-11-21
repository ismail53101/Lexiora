import 'package:lexiora/core/services/connectivity_service.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';
import 'package:lexiora/modules/dictionary/data/services/ai_dictionary_cache.dart';
import 'package:lexiora/modules/dictionary/data/services/ai_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/translation/data/services/word_meaning_service.dart';
import 'package:lexiora/modules/translation/domain/entities/translation.dart';
import 'package:lexiora/modules/translation/domain/entities/translation_outcome.dart';
import 'package:lexiora/modules/translation/domain/repositories/translation_repository.dart';
import 'package:lexiora/modules/translation/domain/services/remote_translation_service.dart';

/// The word + target language for a hybrid translation.
class HybridTranslateParams {
  const HybridTranslateParams(this.word, this.languageCode);
  final String word;
  final String languageCode;
}

/// Offline-first translation with a seamless online fallback.
///
/// Order of operations (the heart of the Hybrid Translation System):
///   1. **Single-word sense disambiguation** — resolve the word's meaning via
///      [WordMeaningService] (curated exam packs → curated exam pack → offline
///      dictionary best sense → online best sense). If the resolved meaning
///      carries a curated Urdu translation, it is served **offline**; otherwise
///      the bundled offline word-level translation (Wiktionary-sourced) is
///      served. Only when both miss does the word fall through to the online
///      fallback, which translates the bare word itself (machine-translating
///      verbose dictionary definitions rendered unusable Urdu).
///   2. **Offline first** — look up the local database (bundled data + cache).
///      On a hit, return immediately; the online provider is **never** called.
///   3. **Connectivity** — on a miss, check whether the device is online.
///   4. **Online fallback** — fetch from the configurable
///      [RemoteTranslationService].
///   5. **Cache + integrate** — persist the result for offline reuse and
///      register the word in the Dictionary so it becomes searchable.
///
/// Returns a [TranslationOutcome] describing exactly what happened so the UI can
/// show the right message (offline / online-saved / no-internet / not-found).
class HybridTranslate
    implements UseCase<TranslationOutcome, HybridTranslateParams> {
  const HybridTranslate({
    required TranslationRepository translationRepository,
    required RemoteTranslationService remoteService,
    required ConnectivityService connectivity,
    required DictionaryRepository dictionaryRepository,
    required WordMeaningService meaningService,
    AiDictionaryService? aiDictionaryService,
    AiDictionaryCache? aiDictionaryCache,
  })  : _repo = translationRepository,
        _remote = remoteService,
        _connectivity = connectivity,
        _dictionary = dictionaryRepository,
        _meaningService = meaningService,
        _aiDictionary = aiDictionaryService,
        _aiCache = aiDictionaryCache;

  final TranslationRepository _repo;
  final RemoteTranslationService _remote;
  final ConnectivityService _connectivity;
  final DictionaryRepository _dictionary;
  final WordMeaningService _meaningService;
  final AiDictionaryService? _aiDictionary;
  final AiDictionaryCache? _aiCache;

  @override
  ResultFuture<TranslationOutcome> call(HybridTranslateParams params) =>
      guard(() async {
        final String word = params.word.trim();
        final String lang = params.languageCode.trim();
        if (word.isEmpty || lang.isEmpty) {
          return const TranslationOutcome.notFound();
        }

        // 1) Single-word sense-aware attempt.
        if (_isSingleWord(word)) {
          final WordMeaning? meaning = await _resolveMeaning(word);
          if (meaning != null) {
            final String curated = meaning.urdu ?? '';
            if (curated.trim().isNotEmpty) {
              // Curated exam-pack Urdu is authoritative and stays offline.
              await _repo.cacheTranslation(
                word: word,
                languageCode: lang,
                translation: curated,
              );
              await _registerInDictionary(word, curated);
              return TranslationOutcome.offline(
                Translation(word: word, languageCode: lang, text: curated),
              );
            }
          }

          // IMPORTANT: translationCache can contain an old online result.
          // It must not be mistaken for bundled/offline data, otherwise it
          // suppresses the AI dictionary fallback.
          final String? wordLevel = await _repo.translate(word, lang);
          final bool cachedOnline =
              await _repo.isCached(word, lang);
          if (wordLevel != null &&
              wordLevel.isNotEmpty &&
              !cachedOnline) {
            return TranslationOutcome.offline(
              Translation(word: word, languageCode: lang, text: wordLevel),
            );
          }
        }

        // 2) AI dictionary fallback for a single English word -> Urdu.
        // Offline words are NEVER sent for a complete AI profile. If the word
        // exists locally but lacks Urdu, AI is asked for Urdu only. If the word
        // does not exist locally at all, AI can provide the lightweight full
        // fallback profile.
        if (_aiDictionary != null &&
            _aiCache != null &&
            _isSingleWord(word) &&
            lang.toLowerCase() == 'ur') {
          final String wl = word.toLowerCase();
          final WordDetails? base = await _dictionary.wordDetails(wl);
          final WordMeaning? meaning = await _resolveMeaning(wl);
          final bool existsOffline =
              base != null || await _dictionary.examData(wl) != null;

          final AiWordProfile? cached = await _aiCache.get(wl);

          if (existsOffline) {
            if (cached != null && cached.urduMeanings.isNotEmpty) {
              final String aiUrdu = cached.urduMeanings.join('، ');
              return TranslationOutcome.ai(
                Translation(
                  word: word,
                  languageCode: lang,
                  text: aiUrdu,
                  source: TranslationSource.ai,
                ),
              );
            }

            final AiWordProfile? profile = await _aiDictionary.define(
              word,
              missingFields: const <String>['urduMeanings'],
            );
            if (profile != null && profile.urduMeanings.isNotEmpty) {
              final AiWordProfile urduOnly = AiWordProfile(
                word: profile.word,
                source: 'ai',
                urduMeanings: profile.urduMeanings,
              );
              await _aiCache.put(urduOnly);
              final String aiUrdu = profile.urduMeanings.join('، ');
              await _repo.cacheTranslation(
                word: word,
                languageCode: lang,
                translation: aiUrdu,
                source: 'ai',
              );
              return TranslationOutcome.ai(
                Translation(
                  word: word,
                  languageCode: lang,
                  text: aiUrdu,
                  source: TranslationSource.ai,
                ),
              );
            }
          } else {
            final AiWordProfile? profile = cached ??
                await _aiDictionary.define(
                  word,
                  missingFields: const <String>[
                    'englishDefinition',
                    'urduMeanings',
                    'synonyms',
                    'antonyms',
                    'exampleSentence',
                    'exampleSentenceUrdu',
                  ],
                );

            if (profile != null &&
                profile.urduMeanings.isNotEmpty) {
              if (cached == null) await _aiCache.put(profile);
              final String aiUrdu = profile.urduMeanings.join('، ');
              await _repo.cacheTranslation(
                word: word,
                languageCode: lang,
                translation: aiUrdu,
                source: 'ai',
              );
              return TranslationOutcome.ai(
                Translation(
                  word: word,
                  languageCode: lang,
                  text: aiUrdu,
                  source: TranslationSource.ai,
                ),
              );
            }
          }
        }

        // 3) Offline first — bundled data set, then the offline cache.
        final String? offline = await _repo.translate(word, lang);
        if (offline != null && offline.isNotEmpty) {
          return TranslationOutcome.offline(
            Translation(word: word, languageCode: lang, text: offline),
          );
        }

        // 4) No offline/AI result → attempt the online provider. We do not
        //    pre-gate on a connectivity probe: a false negative there would
        //    wrongly suppress the fallback (that was the reported bug). The
        //    connectivity check is consulted only to explain a failure.
        String? fetched;
        try {
          fetched =
              await _remote.translate(word: word, targetLanguageCode: lang);
        } on Object catch (e, s) {
          AppLogger.e('Online translation failed', error: e, stackTrace: s);
          final bool connected = await _isConnected();
          return connected
              ? const TranslationOutcome.error()
              : const TranslationOutcome.unavailableOffline();
        }
        final String text = fetched?.trim() ?? '';
        if (text.isEmpty) {
          return const TranslationOutcome.notFound();
        }

        // 5) Save the generic online result for offline reuse + dictionary search.
        await _repo.cacheTranslation(
          word: word,
          languageCode: lang,
          translation: text,
        );
        await _registerInDictionary(word, text);

        return TranslationOutcome.online(
          Translation(
            word: word,
            languageCode: lang,
            text: text,
            source: TranslationSource.online,
          ),
        );
      });

  bool _isSingleWord(String word) =>
      RegExp(r"^[A-Za-z][A-Za-z'’\-]*$").hasMatch(word);

  /// Best-effort meaning resolution — a failure simply falls back to the
  /// normal pipeline.
  Future<WordMeaning?> _resolveMeaning(String word) async {
    try {
      return await _meaningService.resolve(word.toLowerCase());
    } on Object catch (e, s) {
      AppLogger.e('Meaning resolution failed', error: e, stackTrace: s);
      return null;
    }
  }

  /// Connectivity probe used only to classify an online failure (no internet vs
  /// a provider/service error). Never blocks the fallback attempt itself.
  Future<bool> _isConnected() async {
    try {
      return await _connectivity.hasConnection();
    } on Object {
      return false;
    }
  }

  /// Best-effort: making the word searchable must never fail the translation.
  Future<void> _registerInDictionary(String word, String meaning) async {
    try {
      await _dictionary.registerExternalWord(word: word, meaning: meaning);
    } on Object catch (e, s) {
      AppLogger.e('Dictionary register failed', error: e, stackTrace: s);
    }
  }
}

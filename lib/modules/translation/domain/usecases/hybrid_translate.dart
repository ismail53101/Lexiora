import 'package:lexiora/core/services/connectivity_service.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';
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
  })  : _repo = translationRepository,
        _remote = remoteService,
        _connectivity = connectivity,
        _dictionary = dictionaryRepository,
        _meaningService = meaningService;

  final TranslationRepository _repo;
  final RemoteTranslationService _remote;
  final ConnectivityService _connectivity;
  final DictionaryRepository _dictionary;
  final WordMeaningService _meaningService;

  @override
  ResultFuture<TranslationOutcome> call(HybridTranslateParams params) =>
      guard(() async {
        final String word = params.word.trim();
        final String lang = params.languageCode.trim();
        if (word.isEmpty || lang.isEmpty) {
          return const TranslationOutcome.notFound();
        }

        // 1) Single-word sense-aware attempt. Works fully offline when the
        //    meaning carries a curated Urdu translation; otherwise the bundled
        //    offline word-level translation (Wiktionary-sourced, e.g.
        //    "reputation" → "شہرت") is served next. Only when both miss does
        //    the word fall through to the online fallback below, which
        //    translates the bare word itself — machine-translating the verbose
        //    WordNet definition used to produce garbage like "eventually" →
        //    "غير متعینہ مدت یا خاص طور پر طویل تاخیر کے بعد". The handful of
        //    multi-sense traps (e.g. "execution" → "پھانسی") are pinned by the
        //    curated packs / core-word overrides above, so translating the bare
        //    word is safe and reads naturally.
        if (_isSingleWord(word)) {
          final WordMeaning? meaning = await _resolveMeaning(word);
          if (meaning != null) {
            final String curated = meaning.urdu ?? '';
            if (curated.trim().isNotEmpty) {
              // Curated exam-pack Urdu — the best, exam-appropriate answer,
              // served offline and cached for reuse.
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

          // No curated Urdu → the offline word-level entry (bundled data +
          // cache) is a curated, word-sized answer.
          final String? wordLevel = await _repo.translate(word, lang);
          if (wordLevel != null && wordLevel.isNotEmpty) {
            return TranslationOutcome.offline(
              Translation(word: word, languageCode: lang, text: wordLevel),
            );
          }
        }

        // 2) Offline first — bundled data set, then the offline cache.
        final String? offline = await _repo.translate(word, lang);
        if (offline != null && offline.isNotEmpty) {
          return TranslationOutcome.offline(
            Translation(word: word, languageCode: lang, text: offline),
          );
        }

        // 3) No offline result → ALWAYS attempt the online provider. We do not
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

        // 5) Save for offline reuse + make the word searchable in the Dictionary.
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

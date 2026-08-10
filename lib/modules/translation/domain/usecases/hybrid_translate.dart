import 'package:lexiora/core/services/connectivity_service.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/modules/dictionary/data/services/online_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';
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
///   1. **Single-word sense disambiguation** — for a single word on a device
///      that appears to be online, translate the word's English *definition*
///      (offline dictionary first, then the free online dictionary) instead of
///      the bare word. Translators routinely pick the wrong sense for isolated
///      words — e.g. "execution" → "پھانسی" ("hanging") instead of
///      "عملدرآمد" ("carrying out") — while translating the definition
///      reliably lands on the intended sense.
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
    required OnlineDictionaryService onlineDictionary,
  })  : _repo = translationRepository,
        _remote = remoteService,
        _connectivity = connectivity,
        _dictionary = dictionaryRepository,
        _onlineDictionary = onlineDictionary;

  final TranslationRepository _repo;
  final RemoteTranslationService _remote;
  final ConnectivityService _connectivity;
  final DictionaryRepository _dictionary;
  final OnlineDictionaryService _onlineDictionary;

  @override
  ResultFuture<TranslationOutcome> call(HybridTranslateParams params) =>
      guard(() async {
        final String word = params.word.trim();
        final String lang = params.languageCode.trim();
        if (word.isEmpty || lang.isEmpty) {
          return const TranslationOutcome.notFound();
        }

        // 1) Single-word sense-aware attempt. Only run when the device appears
        //    online; otherwise skip straight to the fast offline path below.
        if (_isSingleWord(word)) {
          final bool connected = await _isConnected();
          if (connected) {
            final TranslationOutcome? sensed = await _translateByDefinition(
              word: word,
              lang: lang,
            );
            if (sensed != null) return sensed;
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

  /// Sense-aware online translation: translate the word's English definition
  /// instead of the bare word. Returns `null` when no definition is available
  /// or the online call failed, so callers fall back to the normal pipeline.
  Future<TranslationOutcome?> _translateByDefinition({
    required String word,
    required String lang,
  }) async {
    final String? definition = await _englishDefinition(word);
    if (definition == null || definition.isEmpty) return null;

    String? fetched;
    try {
      fetched = await _remote.translate(
        word: definition,
        targetLanguageCode: lang,
      );
    } on Object catch (e, s) {
      AppLogger.e('Definition translation failed', error: e, stackTrace: s);
      return null;
    }
    final String text = fetched?.trim() ?? '';
    if (text.isEmpty) return null;

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
  }

  /// Best English definition for [word] — the offline dictionary first (fast,
  /// always available), then the free online dictionary. Only Latin-script
  /// definitions are trusted: the Translation module registers translated text
  /// (often Urdu/Arabic) into the dictionary index, which is not a definition.
  Future<String?> _englishDefinition(String word) async {
    final DictionaryResult? local =
        await _dictionary.lookup(word.toLowerCase());
    final bool localIsEnglish = local != null &&
        !RegExp(r'[\u0600-\u06FF\u0750-\u077F]').hasMatch(local.meaning);
    if (localIsEnglish) return local.meaning;

    final OnlineDefinition? online = await _onlineDictionary.define(word);
    return online?.meaning;
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

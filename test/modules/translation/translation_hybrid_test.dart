import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/services/connectivity_service.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/dictionary/data/datasources/dictionary_local_data_source.dart';
import 'package:lexiora/modules/dictionary/data/repositories/dictionary_repository_impl.dart';
import 'package:lexiora/modules/dictionary/data/services/online_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/translation/data/services/word_meaning_service.dart';
import 'package:lexiora/modules/translation/data/datasources/translation_local_data_source.dart';
import 'package:lexiora/modules/translation/data/repositories/translation_repository_impl.dart';
import 'package:lexiora/modules/translation/domain/entities/translation.dart';
import 'package:lexiora/modules/translation/domain/entities/translation_outcome.dart';
import 'package:lexiora/modules/translation/domain/services/remote_translation_service.dart';
import 'package:lexiora/modules/translation/domain/usecases/hybrid_translate.dart';
import 'package:lexiora/modules/vocabulary/data/base_forms.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_list.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';
import 'package:lexiora/modules/vocabulary/domain/repositories/vocabulary_repository.dart';

/// Connectivity stub — toggled per test.
class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity(this.online);
  bool online;
  int callCount = 0;

  @override
  Future<bool> hasConnection() async {
    callCount++;
    return online;
  }
}

/// Remote provider stub — records calls; can return a value, null, or throw.
class _FakeRemote implements RemoteTranslationService {
  _FakeRemote({this.result, this.throws = false});
  String? result;
  bool throws;
  int callCount = 0;
  String? lastWord;

  @override
  String get providerName => 'Fake';

  @override
  Future<String?> translate({
    required String word,
    required String targetLanguageCode,
  }) async {
    callCount++;
    lastWord = word;
    if (throws) throw Exception('network down');
    return result;
  }
}

/// Online dictionary stub — returns a canned definition or none at all.
class _FakeOnlineDictionary extends OnlineDictionaryService {
  _FakeOnlineDictionary({this.definition});
  final String? definition;

  @override
  Future<OnlineDefinition?> define(String word) async => definition == null
      ? null
      : OnlineDefinition(meaning: definition!);
}

/// Vocabulary-pack stub — delegates lookups to a callback (receives each base
/// form, mirroring the real repository's flexible matching).
class _FakeVocabulary implements VocabularyRepository {
  _FakeVocabulary({this.onLookup});

  final Future<VocabularyWord?> Function(String wordLower)? onLookup;

  @override
  Future<VocabularyWord?> lookupWord(String wordLower) async =>
      onLookup?.call(wordLower);

  @override
  Future<VocabularyWord?> lookupWordFlexible(String wordLower) async {
    for (final String form in baseForms(wordLower)) {
      final VocabularyWord? hit = await onLookup?.call(form);
      if (hit != null) return hit;
    }
    return null;
  }

  @override
  Stream<List<VocabularyListSummary>> watchLists() =>
      const Stream<List<VocabularyListSummary>>.empty();

  @override
  Stream<List<VocabularyWord>> watchWords(String listId) =>
      const Stream<List<VocabularyWord>>.empty();
}

void main() {
  late AppDatabase db;
  late TranslationLocalDataSource ds;
  late TranslationRepositoryImpl repo;
  late DictionaryRepositoryImpl dictRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = TranslationLocalDataSource(db);
    repo = TranslationRepositoryImpl(ds);
    dictRepo = DictionaryRepositoryImpl(DictionaryLocalDataSource(db));
  });

  tearDown(() async {
    await db.close();
  });

  HybridTranslate buildUseCase({
    required _FakeRemote remote,
    required _FakeConnectivity connectivity,
    _FakeVocabulary? vocabulary,
    OnlineDictionaryService? onlineDict,
  }) =>
      HybridTranslate(
        translationRepository: repo,
        remoteService: remote,
        connectivity: connectivity,
        dictionaryRepository: dictRepo,
        meaningService: WordMeaningService(
          dictionary: dictRepo,
          vocabulary: vocabulary ?? _FakeVocabulary(),
          online: onlineDict ?? _FakeOnlineDictionary(),
        ),
      );

  Future<TranslationOutcome> run(
    HybridTranslate useCase,
    String word,
    String lang,
  ) async {
    final Result<TranslationOutcome> result =
        await useCase.call(HybridTranslateParams(word, lang));
    expect(result.isOk, isTrue, reason: 'use case should not error');
    return result.valueOrNull!;
  }

  Future<void> seedEntry(String lang, String word, String translation) =>
      ds.insertEntries(<TranslationEntriesCompanion>[
        TranslationEntriesCompanion.insert(
          langCode: lang,
          wordLower: word.toLowerCase(),
          translation: translation,
        ),
      ]);

  test('offline hit is returned and the network is NEVER called', () async {
    await seedEntry('ur', 'book', 'کتاب');
    final _FakeRemote remote = _FakeRemote(result: 'SHOULD NOT BE USED');
    final _FakeConnectivity conn = _FakeConnectivity(true);

    final TranslationOutcome outcome =
        await run(buildUseCase(remote: remote, connectivity: conn), 'book', 'ur');

    expect(outcome.status, TranslationOutcomeStatus.offline);
    expect(outcome.translation?.text, 'کتاب');
    expect(outcome.translation?.source, TranslationSource.offline);
    expect(remote.callCount, 0, reason: 'offline hit must not hit the network');
    // Single words consult connectivity once before the sense-aware attempt,
    // but a real translation request never fires when the offline DB hits.
  });

  test('single word stays offline-first when the device is offline', () async {
    await seedEntry('ur', 'book', 'کتاب');
    final _FakeRemote remote = _FakeRemote(result: 'SHOULD NOT BE USED');
    final _FakeConnectivity conn = _FakeConnectivity(false);

    final TranslationOutcome outcome =
        await run(buildUseCase(remote: remote, connectivity: conn), 'book', 'ur');

    expect(outcome.status, TranslationOutcomeStatus.offline);
    expect(outcome.translation?.text, 'کتاب');
    expect(remote.callCount, 0);
  });

  test('curated exam-pack meaning + Urdu is served offline (network untouched)',
      () async {
    final _FakeVocabulary vocab = _FakeVocabulary(
      onLookup: (String wl) async => wl == 'contribute'
          ? const VocabularyWord(
              id: 'cssbpsc/contribute',
              listId: 'cssbpsc',
              word: 'Contribute',
              letter: 'C',
              urduMeaning: 'حصہ ڈالنا',
              englishMeaning: 'help cause or produce a result',
              partOfSpeech: 'verb',
            )
          : null,
    );
    final _FakeRemote remote = _FakeRemote(result: 'SHOULD NOT BE USED');
    // Fully offline: the curated Urdu must still surface.
    final _FakeConnectivity conn = _FakeConnectivity(false);

    final TranslationOutcome outcome = await run(
      buildUseCase(remote: remote, connectivity: conn, vocabulary: vocab),
      'contributing', // inflected form → base-form match → 'Contribute'
      'ur',
    );

    expect(outcome.status, TranslationOutcomeStatus.offline);
    expect(outcome.translation?.text, 'حصہ ڈالنا');
    expect(remote.callCount, 0,
        reason: 'curated Urdu is offline — no network is ever used');
    // Cached under the original (inflected) word for offline reuse.
    expect(await repo.translate('contributing', 'ur'), 'حصہ ڈالنا');
  });

  test('offline word-level Urdu beats machine-translating the definition '
      '(no curated pack/override — e.g. reputation → شہرت)', () async {
    // 'reputation' has a bundled offline word-level Urdu entry but no curated
    // pack/override meaning. It must be served offline from that entry instead
    // of machine-translating the (often wrong) dictionary definition.
    await seedEntry('ur', 'reputation', 'شہرت');
    final _FakeRemote remote = _FakeRemote(result: 'SHOULD NOT BE USED');
    final _FakeConnectivity conn = _FakeConnectivity(true);

    final TranslationOutcome outcome = await run(
      buildUseCase(remote: remote, connectivity: conn),
      'reputation',
      'ur',
    );

    expect(outcome.status, TranslationOutcomeStatus.offline);
    expect(outcome.translation?.text, 'شہرت');
    expect(remote.callCount, 0,
        reason: 'bundled offline Urdu is used; the network is never touched');
  });

  test('single word outside the curated layers falls back to the ONLINE '
      'bare-word translation (never the WordNet definition)', () async {
    // 'elevation' is in none of the curated layers (packs, exam pack,
    // core-word overrides) and has no bundled offline Urdu in the test DB, so
    // it must fall through to the online provider — which translates the bare
    // word itself. Machine-translating verbose WordNet definitions produced
    // unusable Urdu (e.g. "eventually" → "غير متعینہ مدت…"), so the bare word
    // is the correct target now.
    await dictRepo.registerExternalWord(
      word: 'elevation',
      meaning: 'the act of making something higher or better',
    );
    final _FakeRemote remote = _FakeRemote(result: 'بلندی');
    final _FakeConnectivity conn = _FakeConnectivity(true);

    final TranslationOutcome outcome = await run(
      buildUseCase(remote: remote, connectivity: conn),
      'elevation',
      'ur',
    );

    expect(outcome.status, TranslationOutcomeStatus.online);
    expect(outcome.translation?.text, 'بلندی');
    expect(remote.lastWord, 'elevation',
        reason: 'the bare word — not the dictionary definition — is translated');
    // Cached under the original word for offline reuse.
    expect(await repo.translate('elevation', 'ur'), 'بلندی');
  });

  test('online fallback fetches, caches, and registers with the Dictionary',
      () async {
    final _FakeRemote remote = _FakeRemote(result: 'معیشت');
    final _FakeConnectivity conn = _FakeConnectivity(true);

    final TranslationOutcome outcome = await run(
      buildUseCase(remote: remote, connectivity: conn),
      'economy',
      'ur',
    );

    expect(outcome.status, TranslationOutcomeStatus.online);
    expect(outcome.translation?.text, 'معیشت');
    expect(outcome.translation?.source, TranslationSource.online);
    expect(remote.callCount, 1);

    // Cached for offline reuse.
    expect(await ds.isCached('economy', 'ur'), isTrue);
    expect(await ds.cachedCount(), 1);
    expect(await repo.translate('economy', 'ur'), 'معیشت');

    // Searchable from the Dictionary now.
    final List<DictionaryResult> hits = await dictRepo.search('economy');
    expect(hits.map((DictionaryResult r) => r.wordLower), contains('economy'));
  });

  test('a cached word is served offline on the next lookup (no 2nd API call)',
      () async {
    final _FakeRemote remote = _FakeRemote(result: 'معیشت');
    final _FakeConnectivity conn = _FakeConnectivity(true);
    final HybridTranslate useCase =
        buildUseCase(remote: remote, connectivity: conn);

    final TranslationOutcome first = await run(useCase, 'economy', 'ur');
    expect(first.status, TranslationOutcomeStatus.online);
    expect(remote.callCount, 1);

    final TranslationOutcome second = await run(useCase, 'economy', 'ur');
    expect(second.status, TranslationOutcomeStatus.offline,
        reason: 'second lookup is served from the cache');
    expect(second.translation?.text, 'معیشت');
    expect(remote.callCount, 1, reason: 'no duplicate API request');
  });

  test('offline miss with no internet: fallback is ATTEMPTED, then reports '
      'unavailableOffline (nothing cached)', () async {
    // A truly offline device: the remote call fails with a network error.
    final _FakeRemote remote = _FakeRemote(throws: true);
    final _FakeConnectivity conn = _FakeConnectivity(false);

    final TranslationOutcome outcome = await run(
      buildUseCase(remote: remote, connectivity: conn),
      'serendipity',
      'ur',
    );

    expect(outcome.status, TranslationOutcomeStatus.unavailableOffline);
    expect(remote.callCount, 1,
        reason: 'the online fallback must be attempted on every offline miss');
    expect(conn.callCount, greaterThan(0),
        reason: 'connectivity is consulted only to classify the failure');
    expect(await ds.cachedCount(), 0);
  });

  test('online provider returns null → notFound, nothing cached', () async {
    final _FakeRemote remote = _FakeRemote();
    final _FakeConnectivity conn = _FakeConnectivity(true);

    final TranslationOutcome outcome = await run(
      buildUseCase(remote: remote, connectivity: conn),
      'zzunknown',
      'ur',
    );

    expect(outcome.status, TranslationOutcomeStatus.notFound);
    expect(remote.callCount, 1);
    expect(await ds.cachedCount(), 0);
  });

  test('online provider throws → error outcome, nothing cached', () async {
    final _FakeRemote remote = _FakeRemote(throws: true);
    final _FakeConnectivity conn = _FakeConnectivity(true);

    final TranslationOutcome outcome = await run(
      buildUseCase(remote: remote, connectivity: conn),
      'anything',
      'ur',
    );

    expect(outcome.status, TranslationOutcomeStatus.error);
    expect(await ds.cachedCount(), 0);
  });

  test('cache insertion is idempotent (no duplicate rows; upsert refreshes)',
      () async {
    await ds.cacheTranslation(
      word: 'test',
      languageCode: 'ur',
      translation: 'آزمائش',
    );
    await ds.cacheTranslation(
      word: 'test',
      languageCode: 'ur',
      translation: 'ٹیسٹ', // re-cache same word/lang
    );

    expect(await ds.cachedCount(), 1, reason: 'composite PK prevents duplicates');
    expect(await repo.translate('test', 'ur'), 'ٹیسٹ',
        reason: 'upsert refreshes the cached value');
  });
}

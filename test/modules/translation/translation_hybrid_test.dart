import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/services/connectivity_service.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/dictionary/data/datasources/dictionary_local_data_source.dart';
import 'package:lexiora/modules/dictionary/data/repositories/dictionary_repository_impl.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/translation/data/datasources/translation_local_data_source.dart';
import 'package:lexiora/modules/translation/data/repositories/translation_repository_impl.dart';
import 'package:lexiora/modules/translation/domain/entities/translation.dart';
import 'package:lexiora/modules/translation/domain/entities/translation_outcome.dart';
import 'package:lexiora/modules/translation/domain/services/remote_translation_service.dart';
import 'package:lexiora/modules/translation/domain/usecases/hybrid_translate.dart';

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

  @override
  String get providerName => 'Fake';

  @override
  Future<String?> translate({
    required String word,
    required String targetLanguageCode,
  }) async {
    callCount++;
    if (throws) throw Exception('network down');
    return result;
  }
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
  }) =>
      HybridTranslate(
        translationRepository: repo,
        remoteService: remote,
        connectivity: connectivity,
        dictionaryRepository: dictRepo,
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
    expect(conn.callCount, 0, reason: 'no need to check connectivity on a hit');
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

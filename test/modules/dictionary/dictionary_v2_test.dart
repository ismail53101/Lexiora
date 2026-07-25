import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/dictionary/data/datasources/dictionary_local_data_source.dart';
import 'package:lexiora/modules/dictionary/data/exam_words_seeder.dart';
import 'package:lexiora/modules/dictionary/data/repositories/dictionary_repository_impl.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/get_word_profile.dart';

/// Serves canned strings as assets so the seeder runs without a real bundle.
class _MapAssetBundle extends CachingAssetBundle {
  _MapAssetBundle(this._contents);
  final Map<String, String> _contents;

  @override
  Future<ByteData> load(String key) async {
    final String? value = _contents[key];
    if (value == null) throw FlutterError('No fake asset "$key"');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

Map<String, dynamic> _examMap(String word) => <String, dynamic>{
      'word': word,
      'urduMeanings': <String>['پالیسی', 'حکمت عملی'],
      'englishDefinition': 'A plan or course of action.',
      'pronunciation': '/ˈpɒləsi/',
      'partOfSpeech': 'noun',
      'otherMeanings': <Map<String, dynamic>>[
        <String, dynamic>{'english': 'insurance contract', 'urdu': <String>['بیمہ']},
      ],
      'synonyms': <String>['strategy', 'plan'],
      'antonyms': <String>[],
      'usage': <String, dynamic>{
        'context': 'Economic',
        'english': 'The new $word controlled inflation.',
        'urdu': 'نئی پالیسی نے مہنگائی کو قابو کیا۔',
      },
      'collocations': <String>['foreign policy'],
      'wordForms': <String>['policies'],
      'idioms': <String>[],
      'examNote': 'Common in governance editorials.',
    };

void main() {
  late AppDatabase db;
  late DictionaryLocalDataSource ds;
  late DictionaryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = DictionaryLocalDataSource(db);
    repo = DictionaryRepositoryImpl(ds);
  });

  tearDown(() async {
    await db.close();
  });

  test('examData decodes a curated entry from JSON', () async {
    await ds.insertExamEntries(<DictionaryExamEntriesCompanion>[
      DictionaryExamEntriesCompanion.insert(
        wordLower: 'policy',
        word: 'policy',
        contentJson: jsonEncode(_examMap('policy')),
      ),
    ]);

    final ExamWordData? e = await ds.examData('policy');
    expect(e, isNotNull);
    expect(e!.urduMeanings, <String>['پالیسی', 'حکمت عملی']);
    expect(e.synonyms, contains('strategy'));
    expect(e.otherMeanings.single.english, 'insurance contract');
    expect(e.usage?.context, 'Economic');
    expect(e.collocations, contains('foreign policy'));
    expect(e.examNote, isNotNull);
    expect(await ds.examData('missing'), isNull);
  });

  test('exam seeder seeds from the bundle and is idempotent', () async {
    final String json = jsonEncode(<Map<String, dynamic>>[
      _examMap('policy'),
      _examMap('economy'),
    ]);
    final ExamWordsSeeder seeder = ExamWordsSeeder(
      ds,
      bundle: _MapAssetBundle(<String, String>{
        ExamDictionaryConstants.assetPath: json,
      }),
    );

    await seeder.ensureSeeded();
    expect(await ds.examCount(), 2);
    expect(seeder.ready.value, isTrue);

    await seeder.ensureSeeded();
    expect(await ds.examCount(), 2, reason: 'idempotent, no duplicates');
  });

  test('the bundled exam_words.json seeds the full pack and decodes', () async {
    final String raw =
        File(ExamDictionaryConstants.assetPath).readAsStringSync();
    await ExamWordsSeeder(
      ds,
      bundle: _MapAssetBundle(<String, String>{
        ExamDictionaryConstants.assetPath: raw,
      }),
    ).ensureSeeded();

    expect(await ds.examCount(), greaterThanOrEqualTo(150));
    final ExamWordData? policy = await ds.examData('policy');
    expect(policy, isNotNull);
    expect(policy!.urduMeanings, isNotEmpty);
    expect(policy.usage, isNotNull);
    expect(policy.synonyms, isNotEmpty);
  });

  test('auto-discovers and merges multiple packs (dedup: later pack wins)',
      () async {
    final Map<String, dynamic> sharedA = _examMap('shared')
      ..['englishDefinition'] = 'FROM PACK A';
    final Map<String, dynamic> sharedB = _examMap('shared')
      ..['englishDefinition'] = 'FROM PACK B';
    final String packA =
        jsonEncode(<Map<String, dynamic>>[_examMap('alpha'), sharedA]);
    final String packB =
        jsonEncode(<Map<String, dynamic>>[_examMap('beta'), sharedB]);

    final ExamWordsSeeder seeder = ExamWordsSeeder(
      ds,
      bundle: _MapAssetBundle(<String, String>{
        'assets/dictionary/exam_words.json': packA,
        'assets/dictionary/exam_words_2.json': packB,
      }),
      // Deterministic discovery order (production sorts the manifest the same way).
      listPacks: (AssetBundle _) async => <String>[
        'assets/dictionary/exam_words.json',
        'assets/dictionary/exam_words_2.json',
      ],
    );

    await seeder.ensureSeeded();
    expect(await ds.examCount(), 3, reason: 'alpha + beta + shared (deduped)');
    final ExamWordData? shared = await ds.examData('shared');
    expect(shared!.englishDefinition, 'FROM PACK B',
        reason: 'later pack (by path) overrides the same headword');
  });

  test('a missing or malformed pack is skipped without crashing', () async {
    final ExamWordsSeeder seeder = ExamWordsSeeder(
      ds,
      bundle: _MapAssetBundle(<String, String>{
        'assets/dictionary/good.json':
            jsonEncode(<Map<String, dynamic>>[_examMap('good1'), _examMap('good2')]),
        'assets/dictionary/bad.json': '{ this is : not valid json',
        // 'missing.json' is intentionally not in the bundle.
      }),
      listPacks: (AssetBundle _) async => <String>[
        'assets/dictionary/good.json',
        'assets/dictionary/bad.json',
        'assets/dictionary/missing.json',
      ],
    );

    await seeder.ensureSeeded();
    expect(await ds.examCount(), 2, reason: 'only the valid pack loads');
    expect(await ds.examData('good1'), isNotNull);
    expect(seeder.ready.value, isTrue);
  });

  test('adding a pack changes the seed signature and re-seeds automatically',
      () async {
    final String packA = jsonEncode(<Map<String, dynamic>>[_examMap('alpha')]);
    final String packB = jsonEncode(<Map<String, dynamic>>[_examMap('beta')]);
    final _MapAssetBundle bundle = _MapAssetBundle(<String, String>{
      'assets/dictionary/a.json': packA,
      'assets/dictionary/b.json': packB,
    });

    // First launch: only pack A is present.
    await ExamWordsSeeder(ds, bundle: bundle,
            listPacks: (AssetBundle _) async => <String>['assets/dictionary/a.json'])
        .ensureSeeded();
    expect(await ds.examCount(), 1);
    final String? v1 = await ds.examSeededVersion();

    // Next launch: a new pack was dropped in — a fresh seeder instance re-seeds.
    await ExamWordsSeeder(ds, bundle: bundle,
            listPacks: (AssetBundle _) async =>
                <String>['assets/dictionary/a.json', 'assets/dictionary/b.json'])
        .ensureSeeded();
    expect(await ds.examCount(), 2, reason: 'new pack merged in on next launch');
    final String? v2 = await ds.examSeededVersion();
    expect(v2, isNot(v1), reason: 'content signature changed → re-seed fired');
  });

  test('relatedWords returns same-family words and excludes look-alikes',
      () async {
    await ds.insertEntries(<DictionaryEntriesCompanion>[
      _entry('govern'),
      _entry('government'),
      _entry('governor'),
      _entry('governance'),
      _entry('governing'),
      _entry('inquire'),
      _entry('inquiry'),
      _entry('inquirer'),
      _entry('inquiring'),
      _entry('policy'),
      _entry('policies'),
      _entry('police'),
      _entry('apple'),
    ]);

    final List<String> govern = await repo.relatedWords('govern');
    expect(
      govern,
      containsAll(
        <String>['government', 'governor', 'governance', 'governing'],
      ),
    );
    expect(govern, isNot(contains('govern')), reason: 'excludes the word itself');

    // Trailing-"e" stem: inquire → inquir → inquiry / inquirer / inquiring.
    final List<String> inquire = await repo.relatedWords('inquire');
    expect(
      inquire,
      containsAll(<String>['inquiry', 'inquirer', 'inquiring']),
    );

    // Family only: policy shares only "polic" with policies AND police, so the
    // precise (full-root) rule includes neither — critically, the look-alike
    // "police" is excluded. Curated wordForms supply "policies" for such words.
    final List<String> policy = await repo.relatedWords('policy');
    expect(policy, isNot(contains('police')),
        reason: 'police is a different root, not a related form');
    // policyholder DOES start with the full root "policy" → it is in-family.
    await ds.insertEntries(<DictionaryEntriesCompanion>[_entry('policyholder')]);
    expect(await repo.relatedWords('policy'), contains('policyholder'));

    expect(await repo.relatedWords('cat'), isEmpty,
        reason: 'too short to derive a family');
  });

  test('search history keeps most-recent-first and caps at the maximum',
      () async {
    const int cap = SearchHistoryConstants.maxEntries;
    // Ordering/pruning is by monotonic rowid, so rapid inserts are fine.
    for (int i = 0; i < cap + 3; i++) {
      await ds.addSearchHistory('w$i');
    }

    final List<String> recent = await ds.watchRecentSearches(limit: 500).first;
    expect(recent.length, cap, reason: 'older entries are pruned to the cap');
    expect(recent.first, 'w${cap + 2}', reason: 'most recent first');
    expect(recent.contains('w0'), isFalse, reason: 'oldest was pruned');

    await ds.clearSearchHistory();
    expect(await ds.watchRecentSearches().first, isEmpty);
  });

  test('GetWordProfile aggregates exam data, base senses and related words',
      () async {
    await ds.insertExamEntries(<DictionaryExamEntriesCompanion>[
      DictionaryExamEntriesCompanion.insert(
        wordLower: 'policy',
        word: 'policy',
        contentJson: jsonEncode(_examMap('policy')),
      ),
    ]);
    await ds.insertEntries(<DictionaryEntriesCompanion>[
      _entry('policy', meaning: 'a base definition'),
      _entry('policyholder'),
      _entry('policymaker'),
    ]);

    final Result<WordProfile> result =
        await GetWordProfile(repo).call('policy');
    expect(result.isOk, isTrue);
    final WordProfile p = result.valueOrNull!;
    expect(p.exam, isNotNull);
    expect(p.base, isNotNull);
    expect(p.englishDefinition, 'A plan or course of action.',
        reason: 'curated definition is preferred over the base one');
    expect(p.displayWord, 'policy');
    expect(p.relatedWords, isNotEmpty);
  });
}

DictionaryEntriesCompanion _entry(String word, {String meaning = 'meaning'}) =>
    DictionaryEntriesCompanion.insert(
      word: word,
      wordLower: word.toLowerCase(),
      meaning: meaning,
    );

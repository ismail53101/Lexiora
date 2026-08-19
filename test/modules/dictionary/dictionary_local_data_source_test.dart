import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/database/tables.dart';
import 'package:lexiora/modules/dictionary/data/datasources/dictionary_local_data_source.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';

/// Verifies the offline dictionary engine end-to-end against a real in-memory
/// SQLite database (via Drift), exercising the grouped prefix search, word
/// details, lookup and the favorites lifecycle.
void main() {
  late AppDatabase db;
  late DictionaryLocalDataSource ds;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ds = DictionaryLocalDataSource(db);
    await ds.insertEntries(<DictionaryEntriesCompanion>[
      _entry('Run', 'to move quickly on foot', pos: 'verb', example: 'I run.'),
      _entry('Run', 'a point scored in cricket', pos: 'noun'),
      _entry('Runner', 'a person who runs', pos: 'noun'),
      _entry('Running', 'the activity of a runner', pos: 'noun'),
      _entry('Apple', 'a round fruit with red or green skin', pos: 'noun'),
      _entry('Apply', 'to make a formal request', pos: 'verb'),
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  test('prefix search groups senses per headword, exact match first', () async {
    final List<DictionaryResult> results = await ds.search('run');
    final List<String> words = results.map((r) => r.word).toList();

    expect(words.first, 'Run', reason: 'exact match should rank first');
    expect(words, containsAll(<String>['Run', 'Runner', 'Running']));

    final DictionaryResult run =
        results.firstWhere((r) => r.wordLower == 'run');
    expect(run.senseCount, 2, reason: 'the two senses of "run" are grouped');
    expect(run.partOfSpeech, 'verb', reason: 'primary (first) sense is verb');
  });

  test('search is case-insensitive and strictly prefix-bounded', () async {
    final List<DictionaryResult> app = await ds.search('APP');
    expect(app.map((r) => r.wordLower), containsAll(<String>['apple', 'apply']));
    expect(app.every((r) => r.wordLower.startsWith('app')), isTrue);

    expect(await ds.search('zzz'), isEmpty);
    expect(await ds.search('   '), isEmpty);
  });

  test('pagination via limit/offset returns disjoint pages', () async {
    final List<DictionaryResult> page1 = await ds.search('', limit: 1);
    // Empty query returns nothing (search is prefix-based, not a full listing).
    expect(page1, isEmpty);

    final List<DictionaryResult> first = await ds.search('run', limit: 1);
    final List<DictionaryResult> second =
        await ds.search('run', limit: 1, offset: 1);
    expect(first.length, 1);
    expect(second.length, 1);
    expect(first.first.wordLower, isNot(second.first.wordLower));
  });

  test('wordDetails returns every sense in a stable order', () async {
    final WordDetails? details = await ds.wordDetails('run');
    expect(details, isNotNull);
    expect(details!.word, 'Run');
    expect(details.senses.length, 2);
    expect(details.senses.first.meaning, 'to move quickly on foot');
    expect(await ds.wordDetails('missing'), isNull);
  });

  test('lookup returns the primary sense with a sense count', () async {
    final DictionaryResult? r = await ds.lookup('run');
    expect(r, isNotNull);
    expect(r!.word, 'Run');
    expect(r.senseCount, 2);
    expect(await ds.lookup('missing'), isNull);
  });

  test('favorites: add reflects everywhere, remove clears it', () async {
    expect(await ds.isFavorite('run'), isFalse);

    await ds.addFavorite(
      wordLower: 'run',
      word: 'Run',
      meaning: 'to move quickly on foot',
      partOfSpeech: 'verb',
    );
    expect(await ds.isFavorite('run'), isTrue);

    final List<DictionaryResult> results = await ds.search('run');
    expect(
      results.firstWhere((r) => r.wordLower == 'run').isFavorite,
      isTrue,
      reason: 'search results reflect favorite state via the join',
    );

    final List<DictionaryResult> favs = await ds.watchFavorites().first;
    expect(favs.map((r) => r.wordLower), contains('run'));

    await ds.removeFavorite('run');
    expect(await ds.isFavorite('run'), isFalse);
    expect(await ds.watchFavorites().first, isEmpty);
  });

  test('entryCount reflects the number of inserted senses', () async {
    expect(await ds.entryCount(), 6);
  });

  test('search includes curated GRE-only words and deduplicates overlap', () async {
    await ds.insertExamEntries(<DictionaryExamEntriesCompanion>[
      _examEntry('abjure', urdu: 'ترک کرنا', definition: 'to renounce formally'),
      _examEntry('run', urdu: 'دوڑنا', definition: 'to move quickly on foot'),
    ]);

    final List<DictionaryResult> abjure = await ds.search('abjure');
    expect(abjure.map((r) => r.wordLower), contains('abjure'));
    expect(abjure.single.meaning, 'to renounce formally');
    expect(abjure.single.partOfSpeech, 'verb');

    final List<DictionaryResult> run = await ds.search('run');
    expect(run.where((r) => r.wordLower == 'run'), hasLength(1));
    expect(run.firstWhere((r) => r.wordLower == 'run').senseCount, 2);
  });

  test('search matches Urdu meanings in curated entries', () async {
    await ds.insertExamEntries(<DictionaryExamEntriesCompanion>[
      _examEntry('abjure', urdu: 'ترک کرنا', definition: 'to renounce formally'),
    ]);

    final List<DictionaryResult> results = await ds.search('ترک');
    expect(results.map((r) => r.wordLower), contains('abjure'));
  });
}

DictionaryExamEntriesCompanion _examEntry(
  String word, {
  required String urdu,
  required String definition,
}) =>
    DictionaryExamEntriesCompanion.insert(
      wordLower: word.toLowerCase(),
      word: word,
      contentJson: jsonEncode(<String, dynamic>{
        'word': word,
        'urduMeanings': <String>[urdu],
        'englishDefinition': definition,
        'partOfSpeech': 'verb',
        'synonyms': <String>['renounce'],
        'antonyms': <String>['accept'],
        'usage': <String, dynamic>{
          'english': '$word is used in an exam sentence.',
          'urdu': urdu,
        },
      }),
    );

DictionaryEntriesCompanion _entry(
  String word,
  String meaning, {
  String? pos,
  String? example,
}) =>
    DictionaryEntriesCompanion.insert(
      word: word,
      wordLower: word.toLowerCase(),
      meaning: meaning,
      partOfSpeech: Value<String?>(pos),
      exampleSentence: Value<String?>(example),
    );

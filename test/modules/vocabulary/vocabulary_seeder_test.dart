import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/vocabulary/data/datasources/vocabulary_local_data_source.dart';
import 'package:lexiora/modules/vocabulary/data/repositories/vocabulary_repository_impl.dart';
import 'package:lexiora/modules/vocabulary/data/vocabulary_seeder.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_list.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';

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

Map<String, dynamic> _w(String word, String urdu, String meaning,
        {String? ipa, String? pos}) =>
    <String, dynamic>{
      'word': word,
      'urdu': urdu,
      'meaning': meaning,
      'ipa': ?ipa,
      'pos': ?pos,
    };

String _pack(String id, String title, List<Map<String, dynamic>> words,
        {int order = 1, String? subtitle}) =>
    jsonEncode(<String, dynamic>{
      'list': <String, dynamic>{
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'order': order,
      },
      'words': words,
    });

void main() {
  late AppDatabase db;
  late VocabularyLocalDataSource ds;
  late VocabularyRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = VocabularyLocalDataSource(db);
    repo = VocabularyRepositoryImpl(ds);
  });

  tearDown(() async {
    await db.close();
  });

  test('merges multiple packs, derives letters, counts and ordering', () async {
    final String general = _pack(
      'general',
      'General Vocabulary',
      <Map<String, dynamic>>[
        _w('Banana', 'کیلا', 'a long yellow fruit', pos: 'noun'),
        _w('Apple', 'سیب', 'a round fruit', ipa: '/ˈæpəl/', pos: 'noun'),
        _w('Cat', 'بلی', 'a small pet animal', pos: 'noun'),
      ],
      subtitle: 'Everyday words',
    );
    final String business = _pack(
      'business',
      'Business Vocabulary',
      <Map<String, dynamic>>[
        _w('Asset', 'اثاثہ', 'something owned of value', pos: 'noun'),
      ],
      order: 2,
    );

    final VocabularySeeder seeder = VocabularySeeder(
      ds,
      bundle: _MapAssetBundle(<String, String>{
        'assets/vocabulary/general_vocabulary.json': general,
        'assets/vocabulary/business_vocabulary.json': business,
      }),
      listPacks: (AssetBundle _) async => <String>[
        'assets/vocabulary/business_vocabulary.json',
        'assets/vocabulary/general_vocabulary.json',
      ],
    );

    await seeder.ensureSeeded();
    expect(await ds.listCount(), 2);
    expect(await ds.wordCount(), 4);

    // Lists are ordered by order index; word counts are denormalized.
    final List<VocabularyListSummary> lists = await repo.watchLists().first;
    expect(lists.map((VocabularyListSummary l) => l.id),
        <String>['general', 'business']);
    expect(lists.first.wordCount, 3);
    expect(lists.first.subtitle, 'Everyday words');

    // Words come back A–Z; letters and fields are derived correctly.
    final List<VocabularyWord> gen = await repo.watchWords('general').first;
    expect(gen.map((VocabularyWord w) => w.word),
        <String>['Apple', 'Banana', 'Cat']);
    expect(gen.first.letter, 'A');
    expect(gen.first.ipa, '/ˈæpəl/');
    expect(gen.first.partOfSpeech, 'noun');
    expect(gen.first.id, 'general/apple');
  });

  test('skips missing and malformed packs without crashing', () async {
    final VocabularySeeder seeder = VocabularySeeder(
      ds,
      bundle: _MapAssetBundle(<String, String>{
        'assets/vocabulary/good.json': _pack('general', 'General',
            <Map<String, dynamic>>[_w('Apple', 'سیب', 'a fruit')]),
        'assets/vocabulary/bad.json': '{ not valid json',
      }),
      listPacks: (AssetBundle _) async => <String>[
        'assets/vocabulary/good.json',
        'assets/vocabulary/bad.json',
        'assets/vocabulary/missing.json',
      ],
    );

    await seeder.ensureSeeded();
    expect(await ds.wordCount(), 1, reason: 'only the valid pack loads');
    expect(seeder.ready.value, isTrue);
  });

  test('re-seeds automatically when a pack is added (signature change)',
      () async {
    final _MapAssetBundle bundle = _MapAssetBundle(<String, String>{
      'assets/vocabulary/a.json': _pack('general', 'General',
          <Map<String, dynamic>>[_w('Apple', 'سیب', 'a fruit')]),
      'assets/vocabulary/b.json': _pack('business', 'Business',
          <Map<String, dynamic>>[_w('Asset', 'اثاثہ', 'value owned')], order: 2),
    });

    await VocabularySeeder(ds,
            bundle: bundle,
            listPacks: (AssetBundle _) async =>
                <String>['assets/vocabulary/a.json'])
        .ensureSeeded();
    expect(await ds.wordCount(), 1);
    final String? v1 = await ds.seededVersion();

    await VocabularySeeder(ds,
            bundle: bundle,
            listPacks: (AssetBundle _) async => <String>[
                  'assets/vocabulary/a.json',
                  'assets/vocabulary/b.json',
                ])
        .ensureSeeded();
    expect(await ds.wordCount(), 2, reason: 'new pack merged on next launch');
    expect(await ds.listCount(), 2);
    expect(await ds.seededVersion(), isNot(v1));
  });

  test('the bundled packs seed the full A–Z vocabulary', () async {
    final Directory dir = Directory('assets/vocabulary');
    final Map<String, String> bundleMap = <String, String>{};
    final List<String> paths = <String>[];
    for (final File f in dir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.toLowerCase().endsWith('.json'))) {
      bundleMap[f.path] = f.readAsStringSync();
      paths.add(f.path);
    }
    expect(paths, isNotEmpty, reason: 'bundled vocabulary packs present');

    await VocabularySeeder(
      ds,
      bundle: _MapAssetBundle(bundleMap),
      listPacks: (AssetBundle _) async => paths,
    ).ensureSeeded();

    expect(await ds.listCount(), greaterThanOrEqualTo(5));
    expect(await ds.wordCount(), greaterThanOrEqualTo(1500));

    // The competitive-exam set spans the full alphabet across lists
    // (CSS/BPSC + GRE + One-Word Substitutions cover A–Y, Proverbs adds Z).
    final List<VocabularyListSummary> lists = await repo.watchLists().first;
    final Set<String> letters = <String>{};
    for (final VocabularyListSummary l in lists) {
      final List<VocabularyWord> words = await repo.watchWords(l.id).first;
      for (final VocabularyWord w in words) {
        letters.add(w.letter);
      }
    }
    for (final String ch in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      expect(letters, contains(ch), reason: 'letter $ch covered by some list');
    }
  });
}

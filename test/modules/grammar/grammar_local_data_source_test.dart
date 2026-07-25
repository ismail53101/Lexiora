import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/grammar/data/datasources/grammar_local_data_source.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_topic.dart';

String _leafContent() => jsonEncode(<String, dynamic>{
      'introduction': 'intro',
      'urduExplanation': 'اردو وضاحت',
      'englishExplanation': 'english explanation',
      'types': <Map<String, String>>[
        <String, String>{'name': 'Type A', 'description': 'desc a'},
      ],
      'rules': <String>['rule 1', 'rule 2'],
      'examples': <Map<String, String>>[
        <String, String>{'text': 'an example', 'note': 'note'},
      ],
      'commonMistakes': <Map<String, String>>[
        <String, String>{'wrong': 'w', 'right': 'r', 'note': ''},
      ],
      'practice': <Map<String, dynamic>>[
        <String, dynamic>{
          'question': 'q1',
          'options': <String>['a', 'b', 'c', 'd'],
          'answerIndex': 1,
          'explanation': 'because',
        },
      ],
      'quiz': <Map<String, dynamic>>[
        <String, dynamic>{
          'question': 'q2',
          'options': <String>['a', 'b', 'c', 'd'],
          'answerIndex': 0,
          'explanation': 'because2',
        },
      ],
      'summary': 'summary text',
    });

void main() {
  late AppDatabase db;
  late GrammarLocalDataSource ds;

  GrammarTopicsCompanion node(
    String id,
    String title, {
    String? parent,
    int order = 0,
    bool leaf = false,
    String search = '',
    String? content,
  }) =>
      GrammarTopicsCompanion.insert(
        id: id,
        title: title,
        parentId: Value<String?>(parent),
        orderIndex: Value<int>(order),
        isLeaf: Value<bool>(leaf),
        searchText: Value<String>(search),
        contentJson: Value<String?>(content),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ds = GrammarLocalDataSource(db);
    await ds.insertTopics(<GrammarTopicsCompanion>[
      node('cat1', 'Parts of Speech', order: 1),
      node('cat1/noun', 'Noun',
          parent: 'cat1', order: 1, leaf: true, search: 'noun naming word',
          content: _leafContent()),
      node('cat1/verb', 'Verb',
          parent: 'cat1', order: 2, leaf: true, search: 'verb action',
          content: _leafContent()),
      node('cat1/sub', 'Sub Group', parent: 'cat1', order: 3),
      node('cat1/sub/x', 'Deep Leaf',
          parent: 'cat1/sub', order: 1, leaf: true, content: _leafContent()),
      node('cat2', 'Articles', order: 2, leaf: true, content: _leafContent()),
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  test('children(null) returns ordered top-level nodes', () async {
    final List<GrammarTopicSummary> top = await ds.children(null);
    expect(top.map((GrammarTopicSummary t) => t.id), <String>['cat1', 'cat2']);
    expect(top.first.isLeaf, isFalse);
    expect(top[1].isLeaf, isTrue);
  });

  test('children(id) returns that node\'s children in order', () async {
    final List<GrammarTopicSummary> kids = await ds.children('cat1');
    expect(kids.map((GrammarTopicSummary t) => t.id),
        <String>['cat1/noun', 'cat1/verb', 'cat1/sub']);
  });

  test('leaf decodes full content; a branch returns null', () async {
    final GrammarLesson? noun = await ds.leaf('cat1/noun');
    expect(noun, isNotNull);
    expect(noun!.title, 'Noun');
    expect(noun.urduExplanation, 'اردو وضاحت');
    expect(noun.types.single.name, 'Type A');
    expect(noun.rules.length, 2);
    expect(noun.practice.single.answer, 'b');
    expect(noun.quiz.single.answer, 'a');
    expect(noun.summary, 'summary text');

    expect(await ds.leaf('cat1'), isNull, reason: 'branch is not a leaf');
  });

  test('search matches leaf search text only', () async {
    final List<GrammarTopicSummary> hits = await ds.search('naming');
    expect(hits.single.id, 'cat1/noun');
    expect(await ds.search('parts of speech'),
        isEmpty, reason: 'branches are not searchable leaves');
  });

  test('markViewed and setCompleted drive status + continue feed', () async {
    expect(await ds.watchStatus('cat1/noun').first,
        GrammarProgressStatus.notStarted);

    await ds.markViewed('cat1/noun');
    expect(await ds.watchStatus('cat1/noun').first,
        GrammarProgressStatus.inProgress);
    final List<GrammarTopicSummary> cont =
        await ds.watchContinueLearning().first;
    expect(cont.map((GrammarTopicSummary t) => t.id), contains('cat1/noun'));

    await ds.setCompleted('cat1/noun', completed: true);
    expect(await ds.watchStatus('cat1/noun').first,
        GrammarProgressStatus.completed);
    final List<GrammarTopicSummary> cont2 =
        await ds.watchContinueLearning().first;
    expect(cont2.any((GrammarTopicSummary t) => t.id == 'cat1/noun'), isFalse);
  });

  test('favorites lifecycle', () async {
    expect(await ds.isFavorite('cat1/noun'), isFalse);
    await ds.addFavorite(leafId: 'cat1/noun', title: 'Noun');
    expect(await ds.isFavorite('cat1/noun'), isTrue);
    expect(await ds.watchIsFavorite('cat1/noun').first, isTrue);
    final List<GrammarTopicSummary> favs = await ds.watchFavorites().first;
    expect(favs.map((GrammarTopicSummary t) => t.id), <String>['cat1/noun']);
    await ds.removeFavorite('cat1/noun');
    expect(await ds.watchFavorites().first, isEmpty);
  });

  test('topicCount reflects inserted nodes', () async {
    expect(await ds.topicCount(), 6);
  });
}

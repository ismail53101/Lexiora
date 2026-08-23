import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/grammar/data/datasources/grammar_local_data_source.dart';
import 'package:lexiora/modules/grammar/data/grammar_seeder.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_topic.dart';

class _FileBundle extends CachingAssetBundle {
  _FileBundle(this._raw);
  final String _raw;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(_raw)));
}

void main() {
  late AppDatabase db;
  late GrammarLocalDataSource ds;
  late String raw;

  setUp(() async {
    raw = File(GrammarConstants.topicsAssetPath).readAsStringSync();
    db = AppDatabase(NativeDatabase.memory());
    ds = GrammarLocalDataSource(db);
    await GrammarSeeder(ds, bundle: _FileBundle(raw)).ensureSeeded();
  });

  tearDown(() async {
    await db.close();
  });

  test('the bundled tree is valid JSON with unique node ids', () {
    final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
    final Set<String> ids = data
        .map((dynamic e) => (e as Map<String, dynamic>)['id'] as String)
        .toSet();
    expect(ids.length, data.length, reason: 'node ids must be unique');
  });

  test('the hierarchy has the expected shape', () async {
    expect(await ds.topicCount(), greaterThanOrEqualTo(35));

    final List<GrammarTopicSummary> categories = await ds.children(null);
    expect(categories.length, greaterThanOrEqualTo(14));

    // Parts of Speech → 9 grammar leaves plus the dedicated Quiz item.
    final List<GrammarTopicSummary> pos = await ds.children('parts-of-speech');
    expect(pos.length, 10);
    expect(pos.every((GrammarTopicSummary t) => t.isLeaf), isTrue);

    // Tenses → overview + 3 time branches; legacy Introduction and Master Table are removed.
    final List<GrammarTopicSummary> tenses = await ds.children('tenses');
    expect(tenses.length, 4);
    expect(tenses.where((GrammarTopicSummary t) => !t.isLeaf).length, 3);
    expect(tenses.where((GrammarTopicSummary t) => t.isLeaf).length, 1);
    expect(tenses.singleWhere((GrammarTopicSummary t) => t.isLeaf).title,
        'Tense Overview');
    final List<GrammarTopicSummary> present =
        await ds.children('tenses/present');
    expect(present.length, 4);
    expect(present.every((GrammarTopicSummary t) => t.isLeaf), isTrue);

    // Clauses → Independent (leaf) + Dependent (branch) → 3 clause types.
    final List<GrammarTopicSummary> clauses = await ds.children('clauses');
    expect(clauses.length, 2);
    expect(clauses.where((GrammarTopicSummary t) => t.isLeaf).length, 1,
        reason: 'Independent Clause is the only direct leaf under Clauses');
    expect(clauses.where((GrammarTopicSummary t) => !t.isLeaf).length, 1,
        reason: 'Dependent Clause is a sub-branch');
    final List<GrammarTopicSummary> dependent =
        await ds.children('clauses/dependent');
    expect(dependent.length, 3);
    expect(dependent.every((GrammarTopicSummary t) => t.isLeaf), isTrue);

    // Phrases → 8 leaf types.
    final List<GrammarTopicSummary> phrases = await ds.children('phrases');
    expect(phrases.length, 8);
    expect(phrases.every((GrammarTopicSummary t) => t.isLeaf), isTrue);

    // Active & Passive Voice → 8 leaf sections.
    final List<GrammarTopicSummary> voice =
        await ds.children('active-passive-voice');
    expect(voice.length, 8);
    expect(voice.every((GrammarTopicSummary t) => t.isLeaf), isTrue);

    // Narration → 6 leaf sections.
    final List<GrammarTopicSummary> narration =
        await ds.children('direct-indirect-speech');
    expect(narration.length, 6);
    expect(narration.every((GrammarTopicSummary t) => t.isLeaf), isTrue);

    // Final split: the six remaining multi-type categories each became a
    // branch with a dedicated leaf per type.
    final Map<String, int> expectedChildren = <String, int>{
      'articles': 4,
      'prepositions': 4,
      'conjunctions': 3,
      'modals': 10,
      'conditional-sentences': 5,
      'punctuation': 9,
    };
    for (final MapEntry<String, int> e in expectedChildren.entries) {
      final List<GrammarTopicSummary> kids = await ds.children(e.key);
      expect(kids.length, e.value, reason: '${e.key} must have ${e.value} lessons');
      expect(kids.every((GrammarTopicSummary t) => t.isLeaf), isTrue,
          reason: '${e.key} children are all leaf lessons');
    }

    // The three cohesive categories stay single lessons (not split).
    for (final String id in <String>[
      'sentence-structure',
      'subject-verb-agreement',
      'common-errors',
    ]) {
      final List<GrammarTopicSummary> top = await ds.children(null);
      final GrammarTopicSummary node =
          top.firstWhere((GrammarTopicSummary t) => t.id == id);
      expect(node.isLeaf, isTrue, reason: '$id must remain a single lesson');
    }
  });

  test('every leaf seeds and decodes with real content', () async {
    final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
    int leaves = 0;
    for (final dynamic e in data) {
      final Map<String, dynamic> o = e as Map<String, dynamic>;
      if (o['isLeaf'] != true) continue;
      leaves++;
      final GrammarLesson? lesson = await ds.leaf(o['id'] as String);
      expect(lesson, isNotNull, reason: 'leaf ${o['id']} must decode');
      expect(lesson!.englishExplanation, isNotEmpty,
          reason: '${o['id']} needs an English explanation');
    }
    expect(leaves, greaterThanOrEqualTo(80));

    // Flagship leaves across the split categories decode with full sections
    // (Urdu + rules + practice + quiz + summary), proving each type has its
    // own dedicated lesson rather than a merged page.
    for (final String id in <String>[
      'pos/noun',
      'clauses/dependent/adverb',
      'phrases/participial',
      'active-passive-voice/interrogative',
      'direct-indirect-speech/universal-truth',
      'articles/an',
      'prepositions/confusing',
      'conjunctions/correlative',
      'modals/must',
      'conditional-sentences/third',
      'punctuation/semicolon',
    ]) {
      final GrammarLesson? lesson = await ds.leaf(id);
      expect(lesson, isNotNull, reason: '$id must decode');
      expect(lesson!.urduExplanation, isNotEmpty, reason: '$id needs Urdu');
      expect(lesson.rules, isNotEmpty, reason: '$id needs rules');
      expect(lesson.practice, isNotEmpty, reason: '$id needs practice');
      expect(lesson.quiz, isNotEmpty, reason: '$id needs a quiz');
      expect(lesson.summary, isNotEmpty, reason: '$id needs a summary');
    }

    // The expanded schema decodes: Exam Tips, Structure, and Urdu
    // translations on examples are all present on the new lessons.
    final GrammarLesson must = (await ds.leaf('modals/must'))!;
    expect(must.examTips, isNotEmpty, reason: 'modals/must needs exam tips');
    expect(must.structure, isNotEmpty, reason: 'modals/must needs a structure');
    expect(must.examples.any((GrammarExample e) => (e.urdu ?? '').isNotEmpty),
        isTrue,
        reason: 'examples carry Urdu translations');
    final GrammarLesson cond = (await ds.leaf('conditional-sentences/third'))!;
    expect(cond.structure, isNotEmpty,
        reason: 'conditionals carry the if/main-clause formula');
    expect(cond.examTips, isNotEmpty);
  });
}

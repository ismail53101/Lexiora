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
    expect(await ds.topicCount(), greaterThanOrEqualTo(22));

    final List<GrammarTopicSummary> categories = await ds.children(null);
    expect(categories.length, greaterThanOrEqualTo(10));

    // Parts of Speech → 9 grammar leaves plus the dedicated Quiz item.
    final List<GrammarTopicSummary> pos = await ds.children('parts-of-speech');
    expect(pos.length, 10);
    expect(pos.every((GrammarTopicSummary t) => t.isLeaf), isTrue);

    // Tenses retains only the root and its three time folders; all lessons are removed.
    final List<GrammarTopicSummary> tenses = await ds.children('tenses');
    expect(tenses.length, 3);
    expect(tenses.every((GrammarTopicSummary t) => !t.isLeaf), isTrue);
    final List<GrammarTopicSummary> present =
        await ds.children('tenses/present');
    expect(present.length, 4);
    expect(present.every((GrammarTopicSummary t) => t.isLeaf), isTrue);
    expect(
      present.map((GrammarTopicSummary t) => t.title),
      containsAll(<String>[
        'Present Indefinite Tense — حال سادہ',
        'Present Continuous Tense — حال جاری',
        'Present Perfect Tense — حال مکمل',
        'Present Perfect Continuous Tense — حال مکمل جاری',
      ]),
    );

    // Clauses → two independence/function branches and the Phrase vs Clause
    // lesson; the Introduction folder was intentionally removed.
    final List<GrammarTopicSummary> clauses = await ds.children('clauses');
    expect(clauses.length, 3);
    expect(clauses.where((GrammarTopicSummary t) => t.isLeaf).length, 1,
        reason: 'Phrase vs Clause is the only direct leaf');
    expect(clauses.where((GrammarTopicSummary t) => !t.isLeaf).length, 2,
        reason: 'By Independence and By Function are branches');
    final List<GrammarTopicSummary> byIndependence =
        await ds.children('clauses/by-independence');
    expect(byIndependence.length, 2);
    expect(byIndependence.every((GrammarTopicSummary t) => t.isLeaf), isTrue);
    final List<GrammarTopicSummary> byFunction =
        await ds.children('clauses/by-function');
    expect(byFunction.length, 3);
    expect(byFunction.every((GrammarTopicSummary t) => t.isLeaf), isTrue);

    // Phrases → the nine requested Phrase lessons; the separate Overview
    // entry was intentionally removed.
    final List<GrammarTopicSummary> phrases = await ds.children('phrases');
    expect(phrases.length, 9);
    expect(phrases.every((GrammarTopicSummary t) => t.isLeaf), isTrue);
    expect(phrases.map((GrammarTopicSummary t) => t.title),
        contains('Absolute Phrase'));

    // Comparison is the only new top-level folder and has seven comparisons
    // plus two reference topics.
    final List<GrammarTopicSummary> comparison =
        await ds.children('comparison');
    expect(comparison.length, 9);
    expect(comparison.every((GrammarTopicSummary t) => t.isLeaf), isTrue);

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

    // Final split: the remaining multi-type categories each became a
    // branch with a dedicated leaf per type. Articles, Prepositions, and
    // Conjunctions were intentionally removed from the Grammar hierarchy.
    final Map<String, int> expectedChildren = <String, int>{
      'modals': 10,
      'conditional-sentences': 5,
      'punctuation': 11,
    };
    for (final MapEntry<String, int> e in expectedChildren.entries) {
      final List<GrammarTopicSummary> kids = await ds.children(e.key);
      expect(kids.length, e.value, reason: '${e.key} must have ${e.value} lessons');
      expect(kids.every((GrammarTopicSummary t) => t.isLeaf), isTrue,
          reason: '${e.key} children are all leaf lessons');
    }

    // The three cohesive categories stay single lessons (not split).
    for (final String id in <String>[
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
      final String id = o['id'] as String;
      final GrammarLesson? lesson = await ds.leaf(id);
      expect(lesson, isNotNull, reason: 'leaf $id must decode');

      if (id != 'punctuation/parentheses') {
        expect(
          lesson!.englishExplanation.isNotEmpty ||
              lesson.introduction.isNotEmpty ||
              lesson.providedMaterial.isNotEmpty,
          isTrue,
          reason: '$id needs English lesson content',
        );
      }
    }
    expect(leaves, greaterThanOrEqualTo(86));

    // Flagship leaves across the split categories decode with full sections
    // (Urdu + rules + practice + quiz + summary), proving each type has its
    // own dedicated lesson rather than a merged page.
    for (final String id in <String>[
      'pos/noun',
      'active-passive-voice/interrogative',
      'direct-indirect-speech/universal-truth',
      'modals/must',
    ]) {
      final GrammarLesson? lesson = await ds.leaf(id);
      expect(lesson, isNotNull, reason: '$id must decode');
      expect(lesson!.urduExplanation, isNotEmpty, reason: '$id needs Urdu');
      expect(lesson.rules, isNotEmpty, reason: '$id needs rules');
      expect(lesson.practice, isNotEmpty, reason: '$id needs practice');
      expect(lesson.quiz, isNotEmpty, reason: '$id needs a quiz');
      expect(lesson.summary, isNotEmpty, reason: '$id needs a summary');
    }

    // Phrase material is preserved verbatim from the supplied TXT file. The
    // structured fields remain optional because the original source includes
    // its own headings, examples, explanations, and Urdu lines.
    for (final String id in <String>[
      'phrases/noun',
      'phrases/verb',
      'phrases/adjective',
      'phrases/adverb',
      'phrases/prepositional',
      'phrases/gerund',
      'phrases/infinitive',
      'phrases/participial',
      'phrases/absolute',
    ]) {
      final GrammarLesson? lesson = await ds.leaf(id);
      expect(lesson, isNotNull, reason: '$id must decode');
      expect(lesson!.providedMaterial, isNotEmpty,
          reason: '$id needs the supplied material verbatim');
    }
    // Clause lessons supplied by the user preserve the attached material
    // verbatim and intentionally do not require legacy practice/quiz sections.
    for (final String id in <String>[
      'clauses/by-independence/independent',
      'clauses/by-independence/dependent',
      'clauses/by-function/noun',
      'clauses/by-function/adjective',
      'clauses/by-function/adverb',
      'clauses/phrase-vs-clause',
    ]) {
      final GrammarLesson? lesson = await ds.leaf(id);
      expect(lesson, isNotNull, reason: '$id must decode');
      expect(lesson!.providedMaterial, isNotEmpty,
          reason: '$id needs the supplied material verbatim');
    }

    // The expanded schema decodes: Exam Tips, Structure, and Urdu
    // translations on the established structured lessons.
    final GrammarLesson must = (await ds.leaf('modals/must'))!;
    expect(must.examTips, isNotEmpty, reason: 'modals/must needs exam tips');
    expect(must.structure, isNotEmpty, reason: 'modals/must needs a structure');
    expect(must.examples.any((GrammarExample e) => (e.urdu ?? '').isNotEmpty),
        isTrue,
        reason: 'examples carry Urdu translations');
    // Conditional lessons preserve the supplied source material verbatim,
    // including formulas and exam tips inside the source-material field.
    for (final String id in <String>[
      'conditional-sentences/zero',
      'conditional-sentences/first',
      'conditional-sentences/second',
      'conditional-sentences/third',
      'conditional-sentences/mixed',
    ]) {
      final GrammarLesson? cond = await ds.leaf(id);
      expect(cond, isNotNull, reason: '$id must decode');
      expect(cond!.providedMaterial, isNotEmpty,
          reason: '$id needs the supplied material verbatim');
    }
  });
}

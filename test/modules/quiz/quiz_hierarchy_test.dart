import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:lexiora/modules/quiz/data/quiz_seeder.dart';
import 'package:lexiora/modules/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_bank.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_subject.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_topic.dart';
import 'package:lexiora/modules/quiz/domain/quiz_json.dart';
import 'package:lexiora/modules/quiz/domain/repositories/question_provider.dart';

/// Serves a tiny in-memory manifest + banks, standing in for the bundled
/// `assets/quiz/` content the real LocalJsonQuestionProvider reads (assets
/// are not available inside unit tests).
class _FakeBundledProvider implements QuestionProvider {
  const _FakeBundledProvider(this.banks);

  final List<QuizBankManifest> banks;

  @override
  QuizContentSource get source => QuizContentSource.localJson;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<QuizBankManifest>> listBanks() async => banks;

  @override
  Future<QuizImportPayload> fetchBank(String ref) async =>
      QuizJsonParser.parse(
        '{ "bank": { "name": "$ref" }, "questions": ['
        ' { "type": "mcq", "prompt": "q1 of $ref",'
        '   "options": ["A", "B", "C"], "answer": 0 },'
        ' { "type": "mcq", "prompt": "q2 of $ref",'
        '   "options": ["A", "B", "C"], "answer": 1 } ] }',
        fallbackName: ref,
      );
}

void main() {
  late AppDatabase db;
  late QuizLocalDataSource local;
  late QuizRepositoryImpl repo;
  final DateTime now = DateTime.now();

  QuizSubject subject(String id, {String? name, int order = 0}) => QuizSubject(
      id: id, name: name ?? 'S$id', orderIndex: order, createdAt: now, updatedAt: now);

  QuizTopic topic(String id, String subjectId, {int order = 0}) => QuizTopic(
      id: id,
      subjectId: subjectId,
      name: 'T$id',
      orderIndex: order,
      createdAt: now,
      updatedAt: now);

  QuizBank bank(String id, {String? subjectId, String? topicId}) => QuizBank(
      id: id,
      name: 'B$id',
      subjectId: subjectId,
      topicId: topicId,
      createdAt: now,
      updatedAt: now);

  QuizQuestion q(String id, String bankId,
          {String? subjectId, String? topicId}) =>
      QuizQuestion(
        id: id,
        bankId: bankId,
        type: QuestionType.mcqSingle,
        prompt: 'p$id',
        options: const <String>['A', 'B'],
        answerIndex: 0,
        subjectId: subjectId,
        topicId: topicId,
        createdAt: now,
        updatedAt: now,
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = QuizLocalDataSource(db);
    repo = QuizRepositoryImpl(local);
  });

  tearDown(() async {
    await db.close();
  });

  test('subject/topic hierarchy with computed counts', () async {
    await repo.saveSubject(subject('s1', name: 'Pakistan Affairs'));
    await repo.saveTopic(topic('t1', 's1'));
    await repo.saveBank(bank('b1', subjectId: 's1', topicId: 't1'));
    await repo.saveBank(bank('b2', subjectId: 's1')); // topic-less
    await repo.saveQuestion(q('q1', 'b1', subjectId: 's1', topicId: 't1'));
    await repo.saveQuestion(q('q2', 'b2', subjectId: 's1'));

    final List<QuizSubjectSummary> subs = await repo.watchSubjects().first;
    expect(subs.single.subject.name, 'Pakistan Affairs');
    expect(subs.single.topicCount, 1);
    expect(subs.single.questionCount, 2);

    final List<QuizTopicSummary> topics = await repo.watchTopics('s1').first;
    expect(topics.single.quizCount, 1);
    expect(topics.single.questionCount, 1);

    expect((await repo.watchBanksIn(topicId: 't1').first).length, 1);
    expect(
        (await repo.watchBanksIn(subjectId: 's1', topicless: true).first).length,
        1);
    expect((await repo.watchBanksIn(subjectId: 's1').first).length, 2);
  });

  test('deleting a subject cascades topics, quizzes and questions', () async {
    await repo.saveSubject(subject('s1'));
    await repo.saveTopic(topic('t1', 's1'));
    await repo.saveBank(bank('b1', subjectId: 's1', topicId: 't1'));
    await repo.saveQuestion(q('q1', 'b1', subjectId: 's1', topicId: 't1'));

    await repo.deleteSubject('s1');
    expect(await repo.watchSubjects().first, isEmpty);
    expect(await repo.watchTopics('s1').first, isEmpty);
    expect(await repo.countQuestions(const QuizFilter()), 0);
  });

  test('reorderSubjects changes display order', () async {
    await repo.saveSubject(subject('s1', name: 'Alpha'));
    await repo.saveSubject(subject('s2', name: 'Beta'));
    await repo.reorderSubjects(<String>['s2', 's1']);
    final List<QuizSubjectSummary> subs = await repo.watchSubjects().first;
    expect(subs.map((QuizSubjectSummary s) => s.subject.id), <String>['s2', 's1']);
  });

  test('import files questions under a subject/topic', () async {
    await repo.saveSubject(subject('s1'));
    await repo.saveTopic(topic('t1', 's1'));
    const String json =
        '{ "bank": { "name": "Imported" }, "questions": [ { "type": "tf", "prompt": "x", "answer": true } ] }';
    await repo.importPayload(QuizJsonParser.parse(json), ImportStrategy.merge,
        subjectId: 's1', topicId: 't1');
    final List<QuizQuestion> qs =
        await repo.questions(const QuizFilter(subjectId: 's1'));
    expect(qs.single.subjectId, 's1');
    expect(qs.single.topicId, 't1');
  });

  test('bundled seeder installs manifest subjects, idempotently', () async {
    final _FakeBundledProvider provider = _FakeBundledProvider(
      const <QuizBankManifest>[
        const QuizBankManifest(
          ref: 'pakistan_affairs/economy.json',
          name: 'Economy',
          subject: 'Pakistan Affairs',
          topic: 'Economy',
        ),
        QuizBankManifest(
          ref: 'english/grammar.json',
          name: 'Grammar',
          subject: 'English',
        ),
      ],
    );
    final QuizSeeder seeder = QuizSeeder(repo, local, provider);
    await seeder.ensureSeeded();

    final List<QuizSubjectSummary> subs = await repo.watchSubjects().first;
    expect(subs.length, 2, reason: 'one subject per manifest subject name');

    // Pakistan Affairs demonstrates the topic hierarchy from the manifest.
    expect((await repo.watchTopics('pakistan-affairs').first).length, 1);
    expect((await repo.watchBanksIn(subjectId: 'pakistan-affairs').first).length,
        1);

    // Every seeded subject has content.
    for (final QuizSubjectSummary s in subs) {
      expect(s.questionCount, greaterThan(0),
          reason: '${s.subject.name} should have bundled questions');
    }

    // Running again does not duplicate (stable slugs + version guard).
    await seeder.ensureSeeded();
    expect((await repo.watchSubjects().first).length, 2);
  });
}

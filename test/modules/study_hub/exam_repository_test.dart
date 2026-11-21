import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/database/raw_sql.dart';
import 'package:lexiora/modules/study_hub/data/datasources/study_hub_local_data_source.dart';
import 'package:lexiora/modules/study_hub/data/planner_extras_schema.dart';
import 'package:lexiora/modules/study_hub/data/repositories/exam_repository_impl.dart';
import 'package:lexiora/modules/study_hub/data/repositories/study_hub_repository_impl.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';

void main() {
  final DateTime now = DateTime(2026, 3, 10, 12);
  final List<AppDatabase> dbs = <AppDatabase>[];

  Future<(AppDatabase, ExamRepositoryImpl)> fresh() async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    dbs.add(db);
    final ExamRepositoryImpl repo =
        ExamRepositoryImpl(DriftRawSql(db), clock: () => now);
    return (db, repo);
  }

  tearDownAll(() async {
    for (final AppDatabase d in dbs) {
      await d.close();
    }
  });

  test('the tables exist as soon as the app database opens', () async {
    final (AppDatabase db, ExamRepositoryImpl _) = await fresh();
    final RawSql sql = DriftRawSql(db);
    await PlannerExtrasSchema.ensure(sql); // idempotent
    expect(await sql.select('SELECT COUNT(*) AS n FROM sp_exams'), hasLength(1));
    expect(await sql.select('SELECT COUNT(*) AS n FROM sp_topics'), hasLength(1));
  });

  group('exams', () {
    test('create, update keeps created time, delete', () async {
      final (AppDatabase _, ExamRepositoryImpl repo) = await fresh();
      final StudyExam e = await repo.saveExam(
          subject: ' Maths ', title: 'Midterm', day: '2026-03-25', notes: '  chapters 1-5 ');
      expect(e.subject, 'Maths');
      expect(e.notes, 'chapters 1-5');
      final StudyExam u =
          await repo.saveExam(id: e.id, subject: 'Maths', title: 'Final', day: '2026-04-01');
      expect(u.id, e.id);
      expect(u.createdAt, e.createdAt);
      final List<StudyExam> all = await repo.watchExams().first;
      expect(all, hasLength(1));
      expect(all.single.title, 'Final');
      expect(all.single.notes, isNull);
      await repo.deleteExam(e.id);
      expect(await repo.watchExams().first, isEmpty);
    });

    test('blank title becomes "Exam"; bad input is rejected', () async {
      final (AppDatabase _, ExamRepositoryImpl repo) = await fresh();
      expect((await repo.saveExam(subject: 'A', title: '  ', day: '2026-03-25')).title, 'Exam');
      await expectLater(repo.saveExam(subject: ' ', title: 'x', day: '2026-03-25'), throwsA(isA<ArgumentError>()));
      await expectLater(repo.saveExam(subject: 'A', title: 'x', day: 'nope'), throwsA(isA<ArgumentError>()));
    });

    test('listed by date, then subject', () async {
      final (AppDatabase _, ExamRepositoryImpl repo) = await fresh();
      await repo.saveExam(subject: 'B', title: 'x', day: '2026-04-01');
      await repo.saveExam(subject: 'a', title: 'x', day: '2026-04-01');
      await repo.saveExam(subject: 'C', title: 'x', day: '2026-03-20');
      expect((await repo.watchExams().first).map((StudyExam e) => e.subject).toList(), <String>['C', 'a', 'B']);
    });
  });

  group('syllabus', () {
    test('add topics: trims, skips blanks and duplicates (any case), keeps order', () async {
      final (AppDatabase _, ExamRepositoryImpl repo) = await fresh();
      expect(await repo.addTopics('Maths', <String>['Algebra', ' calculus ', '', 'ALGEBRA', 'Geometry']), 3);
      expect(await repo.addTopics('maths', <String>['geometry', 'Probability']), 1);
      final List<SubjectSyllabus> s = await repo.watchSyllabi().first;
      expect(s, hasLength(1));
      expect(s.single.subject, 'Maths');
      expect(s.single.topics.map((SyllabusTopic t) => t.title).toList(),
          <String>['Algebra', 'calculus', 'Geometry', 'Probability']);
    });

    test('the same title in different subjects is allowed', () async {
      final (AppDatabase _, ExamRepositoryImpl repo) = await fresh();
      await repo.addTopics('Maths', <String>['Introduction']);
      await repo.addTopics('Physics', <String>['Introduction']);
      expect(await repo.watchSyllabi().first, hasLength(2));
    });

    test('toggle done records and clears the completion time', () async {
      final (AppDatabase _, ExamRepositoryImpl repo) = await fresh();
      await repo.addTopics('Maths', <String>['A', 'B']);
      final String id = (await repo.watchSyllabi().first).single.topics.first.id;
      await repo.setTopicDone(id, true);
      SubjectSyllabus s = (await repo.watchSyllabi().first).single;
      expect((s.done, s.remaining, s.percent), (1, 1, 50));
      expect(s.topics.first.completedAt, now);
      await repo.setTopicDone(id, false);
      s = (await repo.watchSyllabi().first).single;
      expect(s.done, 0);
      expect(s.topics.first.completedAt, isNull);
    });

    test('rename (not onto an existing title) and delete', () async {
      final (AppDatabase _, ExamRepositoryImpl repo) = await fresh();
      await repo.addTopics('Maths', <String>['A', 'B']);
      final List<SyllabusTopic> t = (await repo.watchSyllabi().first).single.topics;
      await repo.renameTopic(t[0].id, 'B'); // would duplicate: ignored
      await repo.renameTopic(t[0].id, 'Algebra');
      await repo.renameTopic(t[1].id, '   '); // blank: ignored
      expect((await repo.watchSyllabi().first).single.topics.map((SyllabusTopic x) => x.title).toList(),
          <String>['Algebra', 'B']);
      await repo.deleteTopic(t[0].id);
      await repo.deleteTopic(t[1].id);
      expect(await repo.watchSyllabi().first, isEmpty);
    });

    test('import topics you already planned sessions for', () async {
      final (AppDatabase db, ExamRepositoryImpl repo) = await fresh();
      final StudyHubRepositoryImpl planner = StudyHubRepositoryImpl(StudyHubLocalDataSource(db));
      StudyTask session(String id, String subject, String? topic, {SessionKind kind = SessionKind.session}) =>
          StudyTask(
            id: id, day: '2026-03-10', title: subject, subject: subject, topic: topic,
            kind: kind, createdAt: now, updatedAt: now,
          );
      await planner.saveTask(session('1', 'Maths', 'Algebra'));
      await planner.saveTask(session('2', 'maths', 'Calculus'));
      await planner.saveTask(session('3', 'Maths', 'algebra '));
      await planner.saveTask(session('4', 'Maths', null));
      await planner.saveTask(session('5', 'Physics', 'Optics'));
      await planner.saveTask(session('6', 'Maths', 'Tea', kind: SessionKind.breakTime));
      expect(await repo.topicsFromSessions('MATHS'), <String>['Algebra', 'Calculus']);
      await repo.addTopics('Maths', <String>['algebra']);
      expect(await repo.topicsFromSessions('Maths'), <String>['Calculus']);
      expect(await repo.topicsFromSessions('Chemistry'), isEmpty);
      expect(await repo.topicsFromSessions(' '), isEmpty);
    });
  });

  group('countdowns', () {
    test('combine exams with syllabus progress and the clock', () async {
      final (AppDatabase _, ExamRepositoryImpl repo) = await fresh();
      await repo.saveExam(subject: 'Maths', title: 'Midterm', day: '2026-03-20');
      await repo.saveExam(subject: 'Physics', title: 'Quiz', day: '2026-03-11');
      await repo.saveExam(subject: 'Old', title: 'Done', day: '2026-03-01');
      await repo.addTopics('maths', <String>['A', 'B', 'C', 'D']);
      final String first = (await repo.watchSyllabi().first).single.topics.first.id;
      await repo.setTopicDone(first, true);

      final List<ExamCountdown> c = await repo.watchCountdowns().first;
      expect(c.map((ExamCountdown e) => e.exam.subject).toList(), <String>['Physics', 'Maths', 'Old']);
      expect(c[0].label, 'Tomorrow');
      expect(c[0].urgency, ExamUrgency.critical);
      expect(c[0].syllabus, isNull);
      expect(c[1].daysLeft, 10);
      expect((c[1].syllabus?.done, c[1].syllabus?.total), (1, 4));
      expect(c[1].paceText, '≈ 0.3 topics/day to finish');
      expect(c[2].isUpcoming, false);
    });

    test('the stream re-emits when data changes', () async {
      final (AppDatabase _, ExamRepositoryImpl repo) = await fresh();
      final List<int> sizes = <int>[];
      final sub = repo.watchCountdowns().listen((List<ExamCountdown> c) => sizes.add(c.length));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.saveExam(subject: 'A', title: 'x', day: '2026-03-20');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(sizes, <int>[0, 1]);
    });
  });
}

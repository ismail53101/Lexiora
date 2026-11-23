import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';
import 'package:lexiora/modules/study_hub/domain/planning/day_planner.dart';
import 'package:lexiora/modules/study_hub/domain/planning/plan_inputs.dart';

void main() {
  final DateTime now = DateTime(2026, 3, 10, 14);

  StudyExam exam(String subject, String day) =>
      StudyExam(id: subject, subject: subject, title: 'Exam', day: day, createdAt: now, updatedAt: now);

  SubjectSyllabus syllabus(String subject, int done, int total) => SubjectSyllabus(subject, <SyllabusTopic>[
        for (int i = 0; i < total; i++)
          SyllabusTopic(id: '$subject$i', subject: subject, title: 'T$i', createdAt: now, done: i < done, sortOrder: i),
      ]);

  List<ExamCountdown> countdowns(List<StudyExam> exams) =>
      buildCountdowns(exams, const <String, SubjectSyllabus>{}, now);

  PlanCandidate by(List<PlanCandidate> l, String name) => l.firstWhere((PlanCandidate c) => c.subject.name == name);

  test('an exam-bound subject outranks the rest and is listed first', () {
    final List<PlanCandidate> c = buildPlanCandidates(
      subjectNames: <String>['English', 'Maths', 'Urdu'],
      countdowns: countdowns(<StudyExam>[exam('Maths', '2026-03-15')]),
      syllabi: <SubjectSyllabus>[syllabus('Maths', 2, 10)],
      lastStudiedDay: <String, String>{'maths': '2026-03-04', 'english': '2026-03-09', 'urdu': '2026-03-10'},
      now: now,
    );
    expect(c.first.subject.name, 'Maths');
    expect(c.first.subject.weight, greaterThan(by(c, 'English').subject.weight * 2));
  });

  test('topics are the unfinished ones, in order; reasons explain the weight', () {
    final List<PlanCandidate> c = buildPlanCandidates(
      subjectNames: <String>['Maths'],
      countdowns: countdowns(<StudyExam>[exam('maths', '2026-03-15')]),
      syllabi: <SubjectSyllabus>[syllabus('MATHS', 2, 5)],
      lastStudiedDay: <String, String>{'maths': '2026-03-04'},
      now: now,
    );
    final PlanSubject m = c.single.subject;
    expect(m.topics, <String>['T2', 'T3', 'T4']);
    expect(m.reason, 'Exam in 5 days · 3 topics left · not studied for 6 days');
  });

  test('past exams do not count; the nearest upcoming exam does', () {
    final List<PlanCandidate> c = buildPlanCandidates(
      subjectNames: <String>['A', 'B'],
      countdowns: countdowns(<StudyExam>[exam('A', '2026-03-01'), exam('B', '2026-04-20'), exam('B', '2026-03-20')]),
      syllabi: const <SubjectSyllabus>[],
      lastStudiedDay: <String, String>{'a': '2026-03-10', 'b': '2026-03-10'},
      now: now,
    );
    expect(by(c, 'A').subject.reason, '');
    expect(by(c, 'B').subject.reason, 'Exam in 10 days');
  });

  test('suggested = exam within 90 days, topics left, or studied in the last 14 days', () {
    final List<PlanCandidate> c = buildPlanCandidates(
      subjectNames: <String>['Exam', 'Topics', 'Recent', 'Old', 'FarExam'],
      countdowns: countdowns(<StudyExam>[exam('Exam', '2026-04-20'), exam('FarExam', '2026-12-20')]),
      syllabi: <SubjectSyllabus>[syllabus('Topics', 0, 3)],
      lastStudiedDay: <String, String>{'recent': '2026-03-01', 'old': '2025-12-01', 'exam': '2026-01-01', 'topics': '2026-01-01', 'farexam': '2026-01-01'},
      now: now,
    );
    expect(c.where((PlanCandidate x) => x.suggested).map((PlanCandidate x) => x.subject.name).toSet(),
        <String>{'Exam', 'Topics', 'Recent'});
  });

  test('when nothing is relevant, every subject is suggested', () {
    final List<PlanCandidate> c = buildPlanCandidates(
      subjectNames: <String>['A', 'B'],
      countdowns: const <ExamCountdown>[],
      syllabi: const <SubjectSyllabus>[],
      lastStudiedDay: <String, String>{'a': '2025-01-01'},
      now: now,
    );
    expect(c.every((PlanCandidate x) => x.suggested), true);
  });

  test('blank and duplicate names (any case) are dropped; never-studied adds weight', () {
    final List<PlanCandidate> c = buildPlanCandidates(
      subjectNames: <String>['Maths', ' maths ', '', 'Physics'],
      countdowns: const <ExamCountdown>[],
      syllabi: const <SubjectSyllabus>[],
      lastStudiedDay: <String, String>{'maths': '2026-03-10'},
      now: now,
    );
    expect(c.map((PlanCandidate x) => x.subject.name).toList(), <String>['Physics', 'Maths']);
    expect(by(c, 'Physics').subject.reason, 'not studied yet');
    expect(subjectWeight(daysSinceStudied: 0), by(c, 'Maths').subject.weight);
  });

  test('end to end: the planner gives the exam subject the most time', () {
    final List<PlanCandidate> c = buildPlanCandidates(
      subjectNames: <String>['Maths', 'English', 'Urdu'],
      countdowns: countdowns(<StudyExam>[exam('Maths', '2026-03-14')]),
      syllabi: <SubjectSyllabus>[syllabus('Maths', 1, 8)],
      lastStudiedDay: <String, String>{'maths': '2026-03-05', 'english': '2026-03-09', 'urdu': '2026-03-09'},
      now: now,
    );
    final DayPlan p = planDay(
      window: const MinuteRange(16 * 60, 22 * 60),
      subjects: <PlanSubject>[for (final PlanCandidate x in c) x.subject],
    );
    final Map<String, int> m = p.minutesBySubject;
    expect(m['Maths']!, greaterThan(m['English']!));
    expect(m['Maths']!, greaterThan(m['Urdu']!));
    expect(p.blocks.first.topic, isNotNull);
  });
}

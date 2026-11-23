import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';

void main() {
  final DateTime now = DateTime(2026, 3, 10, 22, 30);

  StudyExam exam(String id, String subject, String day) => StudyExam(
        id: id, subject: subject, title: 'Exam $id', day: day,
        createdAt: now, updatedAt: now,
      );

  SyllabusTopic topic(String id, String subject, {bool done = false}) => SyllabusTopic(
        id: id, subject: subject, title: 'T$id', createdAt: now, done: done,
      );

  group('days and urgency', () {
    test('daysUntil counts calendar days regardless of the time of day', () {
      expect(daysUntil(now, '2026-03-10'), 0);
      expect(daysUntil(now, '2026-03-11'), 1);
      expect(daysUntil(now, '2026-04-09'), 30);
      expect(daysUntil(now, '2026-03-09'), -1);
      expect(daysUntil(DateTime(2026, 3, 10, 0, 1), '2026-03-11'), 1);
    });

    test('crosses month and year boundaries', () {
      expect(daysUntil(DateTime(2026, 12, 30), '2027-01-02'), 3);
      expect(daysUntil(DateTime(2028, 2, 28), '2028-03-01'), 2);
    });

    test('malformed dates are treated as far away', () {
      expect(daysUntil(now, 'nonsense'), greaterThan(100000));
    });

    test('urgency buckets', () {
      expect(ExamUrgency.forDaysLeft(-1), ExamUrgency.passed);
      expect(ExamUrgency.forDaysLeft(0), ExamUrgency.today);
      expect(ExamUrgency.forDaysLeft(3), ExamUrgency.critical);
      expect(ExamUrgency.forDaysLeft(4), ExamUrgency.soon);
      expect(ExamUrgency.forDaysLeft(7), ExamUrgency.soon);
      expect(ExamUrgency.forDaysLeft(8), ExamUrgency.near);
      expect(ExamUrgency.forDaysLeft(30), ExamUrgency.near);
      expect(ExamUrgency.forDaysLeft(31), ExamUrgency.far);
    });
  });

  group('countdowns', () {
    test('upcoming soonest first, passed last (most recent first)', () {
      final List<ExamCountdown> c = buildCountdowns(
        <StudyExam>[
          exam('far', 'A', '2026-06-01'),
          exam('old', 'B', '2026-03-01'),
          exam('soon', 'C', '2026-03-12'),
          exam('older', 'D', '2026-02-01'),
          exam('today', 'E', '2026-03-10'),
        ],
        const <String, SubjectSyllabus>{},
        now,
      );
      expect(c.map((ExamCountdown e) => e.exam.id).toList(),
          <String>['today', 'soon', 'far', 'old', 'older']);
    });

    test('labels', () {
      String l(String day) => buildCountdowns(<StudyExam>[exam('x', 'A', day)],
          const <String, SubjectSyllabus>{}, now).single.label;
      expect(l('2026-03-10'), 'Today');
      expect(l('2026-03-11'), 'Tomorrow');
      expect(l('2026-03-20'), '10 days left');
      expect(l('2026-03-09'), 'Passed yesterday');
      expect(l('2026-03-05'), 'Passed 5 days ago');
    });

    test('syllabus is matched by subject ignoring case and spacing', () {
      final SubjectSyllabus s = SubjectSyllabus('Maths', <SyllabusTopic>[
        topic('1', 'Maths', done: true), topic('2', 'Maths'), topic('3', 'Maths'),
      ]);
      final ExamCountdown c = buildCountdowns(
        <StudyExam>[exam('m', '  MATHS ', '2026-03-20')],
        <String, SubjectSyllabus>{'maths': s},
        now,
      ).single;
      expect(c.syllabus?.done, 1);
      expect(c.syllabus?.remaining, 2);
      expect(c.syllabus?.percent, 33);
    });

    test('pace: topics per day to finish', () {
      SubjectSyllabus syl(int done, int total) => SubjectSyllabus('M', <SyllabusTopic>[
            for (int i = 0; i < total; i++) topic('$i', 'M', done: i < done),
          ]);
      ExamCountdown c(int days, SubjectSyllabus? s) => ExamCountdown(
            exam: exam('x', 'M', '2026-03-20'), daysLeft: days,
            urgency: ExamUrgency.forDaysLeft(days), syllabus: s);
      expect(c(10, syl(0, 20)).topicsPerDay, 2);
      expect(c(10, syl(0, 20)).paceText, '≈ 2 topics/day to finish');
      expect(c(10, syl(8, 20)).paceText, '≈ 1.2 topics/day to finish');
      expect(c(12, syl(11, 12)).paceText, '≈ 0.1 topics/day to finish');
      expect(c(20, syl(19, 20)).paceText, '≈ 0.1 topics/day to finish');
      expect(c(0, syl(5, 10)).topicsPerDay, 5);
      expect(c(5, syl(10, 10)).paceText, 'Syllabus complete');
      expect(c(5, null).paceText, isNull);
      expect(c(5, syl(0, 0)).paceText, isNull);
      expect(c(-2, syl(1, 4)).paceText, isNull);
    });
  });

  group('parseTopicLines', () {
    test('strips bullets and numbers, trims, removes blanks and duplicates', () {
      expect(
        parseTopicLines('  1. Algebra\n- Calculus\n• Trigonometry \n\n2) algebra\n* Geometry\nProbability'),
        <String>['Algebra', 'Calculus', 'Trigonometry', 'Geometry', 'Probability'],
      );
    });

    test('keeps numbers that belong to the title', () {
      expect(parseTopicLines('2024 Budget\nChapter 5: Waves'), <String>['2024 Budget', 'Chapter 5: Waves']);
    });

    test('handles CRLF and empty input', () {
      expect(parseTopicLines('a\r\nb\r\n'), <String>['a', 'b']);
      expect(parseTopicLines('   \n \n'), isEmpty);
    });
  });
}

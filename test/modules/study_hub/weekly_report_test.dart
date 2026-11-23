import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';
import 'package:lexiora/modules/study_hub/domain/report/weekly_report.dart';

void main() {
  // Monday 2026-03-09 … Sunday 2026-03-15. "Now" is Wednesday evening.
  final DateTime monday = DateTime(2026, 3, 9);
  final DateTime now = DateTime(2026, 3, 11, 20);

  EffortRow e(String day, String subject, int minutes, {int? at}) =>
      EffortRow(day: day, subject: subject, minutes: minutes, startMinuteOfDay: at);

  TaskRow task(String id, String day, String subject, int planned, {bool done = false, int? at}) =>
      TaskRow(id: id, day: day, subject: subject, plannedMinutes: planned, completed: done, startMinuteOfDay: at);

  WeeklyReport report({
    List<EffortRow> thisWeek = const <EffortRow>[],
    List<EffortRow> lastWeek = const <EffortRow>[],
    List<TaskRow> planned = const <TaskRow>[],
    List<ExamCountdown> exams = const <ExamCountdown>[],
  }) =>
      buildWeeklyReport(
        weekStart: monday, thisWeek: thisWeek, lastWeek: lastWeek,
        plannedThisWeek: planned, exams: exams, now: now,
      );

  ExamCountdown exam(String subject, int daysLeft) => ExamCountdown(
        exam: StudyExam(id: subject, subject: subject, title: 'Exam', day: '2026-03-20', createdAt: now, updatedAt: now),
        daysLeft: daysLeft,
        urgency: ExamUrgency.forDaysLeft(daysLeft),
      );

  group('mergeEffort', () {
    test('timer logs are counted; a completed session WITH logs is not counted twice', () {
      final List<EffortRow> r = mergeEffort(
        <TimerLog>[
          const TimerLog(day: '2026-03-09', minutes: 25, subject: 'Maths', taskId: 't1', startMinuteOfDay: 540),
          const TimerLog(day: '2026-03-09', minutes: 25, subject: 'Maths', taskId: 't1', startMinuteOfDay: 570),
        ],
        <TaskRow>[task('t1', '2026-03-09', 'Maths', 60, done: true)],
      );
      expect(r.fold(0, (int s, EffortRow x) => s + x.minutes), 50);
      expect(r, hasLength(2));
    });

    test('a completed session without timer logs counts at its planned length', () {
      final List<EffortRow> r = mergeEffort(
        const <TimerLog>[],
        <TaskRow>[
          task('t1', '2026-03-09', 'Maths', 60, done: true, at: 600),
          task('t2', '2026-03-09', 'Physics', 45), // not done: no study time
        ],
      );
      expect(r, hasLength(1));
      expect((r.single.subject, r.single.minutes, r.single.startMinuteOfDay), ('Maths', 60, 600));
    });

    test('a free timer log without subject or task becomes "Other"; the task subject is used when linked', () {
      final List<EffortRow> r = mergeEffort(
        <TimerLog>[
          const TimerLog(day: '2026-03-10', minutes: 20),
          const TimerLog(day: '2026-03-10', minutes: 30, subject: '  ', taskId: 't9'),
        ],
        <TaskRow>[task('t9', '2026-03-10', 'Urdu', 30)],
      );
      expect(r.map((EffortRow x) => x.subject).toList(), <String>['Other', 'Urdu']);
    });

    test('zero-minute logs and zero-length tasks are ignored', () {
      expect(
        mergeEffort(<TimerLog>[const TimerLog(day: 'd', minutes: 0)], <TaskRow>[task('t', 'd', 'A', 0, done: true)]),
        isEmpty,
      );
    });

    test('a log with 0 minutes does not hide the completed session', () {
      final List<EffortRow> r = mergeEffort(
        <TimerLog>[const TimerLog(day: '2026-03-09', minutes: 0, taskId: 't1')],
        <TaskRow>[task('t1', '2026-03-09', 'Maths', 40, done: true)],
      );
      expect(r.single.minutes, 40);
    });
  });

  group('week numbers', () {
    test('mondayOf', () {
      expect(mondayOf(DateTime(2026, 3, 11, 15)), monday);
      expect(mondayOf(DateTime(2026, 3, 9)), monday);
      expect(mondayOf(DateTime(2026, 3, 15, 23, 59)), monday);
      expect(mondayOf(DateTime(2026, 3, 1)), DateTime(2026, 2, 23));
    });

    test('totals, per-day bars, today and future flags', () {
      final WeeklyReport r = report(thisWeek: <EffortRow>[
        e('2026-03-09', 'Maths', 60),
        e('2026-03-09', 'Physics', 30),
        e('2026-03-11', 'Maths', 45),
      ]);
      expect(r.totalMinutes, 135);
      expect(r.days.map((DayStat d) => d.minutes).toList(), <int>[90, 0, 45, 0, 0, 0, 0]);
      expect(r.days[2].isToday, true);
      expect(r.days[3].isFuture, true);
      expect(r.days[1].isFuture, false);
      expect(r.activeDays, 2);
      expect(r.averagePerActiveDay, 68);
      expect(r.weekEnd, DateTime(2026, 3, 15));
    });

    test('subjects: case-insensitive merge, sorted, percentages', () {
      final WeeklyReport r = report(thisWeek: <EffortRow>[
        e('2026-03-09', 'Maths', 60),
        e('2026-03-10', 'maths', 30),
        e('2026-03-10', 'Urdu', 30),
      ]);
      expect(r.subjects.map((SubjectShare s) => (s.subject, s.minutes, s.percent)).toList(),
          <(String, int, int)>[('Maths', 90, 75), ('Urdu', 30, 25)]);
    });

    test('week-over-week change', () {
      final WeeklyReport up = report(
        thisWeek: <EffortRow>[e('2026-03-09', 'A', 150)],
        lastWeek: <EffortRow>[e('2026-03-02', 'A', 100)],
      );
      expect((up.deltaMinutes, up.deltaPercent), (50, 50));
      final WeeklyReport none = report(thisWeek: <EffortRow>[e('2026-03-09', 'A', 60)]);
      expect(none.deltaPercent, isNull);
    });

    test('planned vs completed', () {
      final WeeklyReport r = report(planned: <TaskRow>[
        task('1', '2026-03-09', 'A', 60, done: true),
        task('2', '2026-03-10', 'A', 30),
        task('3', '2026-03-11', 'B', 30, done: true),
        task('4', '2026-03-12', 'B', 60),
      ]);
      expect((r.plannedSessions, r.completedSessions, r.plannedMinutes, r.completionPercent), (4, 2, 180, 50));
      expect(report().completionPercent, isNull);
    });

    test('an empty week is empty', () {
      expect(report().isEmpty, true);
      expect(report(thisWeek: <EffortRow>[e('2026-03-09', 'A', 10)]).isEmpty, false);
    });
  });

  group('time of day', () {
    test('parts of the day', () {
      expect(DayPart.of(5 * 60), DayPart.morning);
      expect(DayPart.of(11 * 60 + 59), DayPart.morning);
      expect(DayPart.of(12 * 60), DayPart.afternoon);
      expect(DayPart.of(17 * 60), DayPart.evening);
      expect(DayPart.of(21 * 60), DayPart.night);
      expect(DayPart.of(2 * 60), DayPart.night);
      expect(DayPart.of(4 * 60 + 59), DayPart.night);
    });

    test('best part needs enough data and picks the largest', () {
      expect(report(thisWeek: <EffortRow>[e('2026-03-09', 'A', 20, at: 600)]).bestPart, isNull);
      expect(report(thisWeek: <EffortRow>[e('2026-03-09', 'A', 60, at: 600), e('2026-03-10', 'A', 90, at: 19 * 60)]).bestPart, DayPart.evening);
      expect(report(thisWeek: <EffortRow>[e('2026-03-09', 'A', 90)]).bestPart, isNull); // no start times
    });
  });

  group('insights', () {
    String all(WeeklyReport r) => r.insights.map((ReportInsight i) => i.text).join('\n');

    test('an upcoming exam subject with almost no study time is flagged first', () {
      final WeeklyReport r = report(
        thisWeek: <EffortRow>[e('2026-03-09', 'English', 120), e('2026-03-09', 'Maths', 10)],
        exams: <ExamCountdown>[exam('maths', 6), exam('Urdu', 30), exam('English', 5)],
      );
      expect(r.insights.first.kind, InsightKind.exam);
      expect(r.insights.first.text, 'maths exam is in 6 days, but you studied it only 10 min this week.');
      expect(r.insights.first.positive, false);
      expect(all(r), isNot(contains('English exam'))); // studied enough
      expect(all(r), isNot(contains('Urdu exam'))); // too far away
    });

    test('an exam subject with zero minutes says so; "tomorrow" and "today" wording', () {
      final WeeklyReport r = report(
        thisWeek: <EffortRow>[e('2026-03-09', 'A', 60)],
        exams: <ExamCountdown>[exam('Maths', 1), exam('Physics', 0)],
      );
      expect(all(r), contains('Maths exam is tomorrow, but you studied it only zero minutes this week.'));
      expect(all(r), contains('Physics exam is today'));
    });

    test('completion: encouragement at 80%+, a nudge below 50%, nothing for few sessions', () {
      WeeklyReport withDone(int done, int total) => report(planned: <TaskRow>[
            for (int i = 0; i < total; i++) task('$i', '2026-03-09', 'A', 30, done: i < done),
          ]);
      expect(all(withDone(5, 6)), contains('5 of 6 planned sessions done'));
      expect(all(withDone(2, 6)), contains('finished 2 of 6'));
      expect(all(withDone(2, 6)), contains('Plan my day'));
      expect(all(withDone(3, 6)), isNot(contains('planned sessions')));
      expect(withDone(1, 2).insights.where((ReportInsight i) => i.kind == InsightKind.plan), isEmpty);
    });

    test('trend: up, down, about the same, and no trend without last week', () {
      WeeklyReport vs(int now_, int last) => report(
            thisWeek: <EffortRow>[e('2026-03-09', 'A', now_)],
            lastWeek: <EffortRow>[e('2026-03-02', 'A', last)],
          );
      expect(all(vs(150, 100)), contains('Up 50% on last week (50 min more)'));
      expect(all(vs(60, 120)), contains('Down 50% on last week (1 h less)'));
      expect(all(vs(105, 100)), contains('About the same as last week'));
      expect(report(thisWeek: <EffortRow>[e('2026-03-09', 'A', 60)]).insights.where((ReportInsight i) => i.kind == InsightKind.trend), isEmpty);
    });

    test('focus and habit insights', () {
      final WeeklyReport r = report(thisWeek: <EffortRow>[
        e('2026-03-09', 'Maths', 100), e('2026-03-10', 'Maths', 60), e('2026-03-11', 'Maths', 40),
        e('2026-03-12', 'Urdu', 20), e('2026-03-13', 'Urdu', 20),
      ]);
      expect(all(r), contains('Maths'));
      expect(all(r), contains('5 of 7 days'));
    });

    test('at most four insights, exam warnings first', () {
      final WeeklyReport r = report(
        thisWeek: <EffortRow>[
          for (int i = 0; i < 5; i++) e('2026-03-${9 + i}', i < 4 ? 'Maths' : 'Urdu', 70, at: 19 * 60),
        ],
        lastWeek: <EffortRow>[e('2026-03-02', 'Maths', 100)],
        planned: <TaskRow>[for (int i = 0; i < 4; i++) task('$i', '2026-03-09', 'Maths', 30, done: true)],
        exams: <ExamCountdown>[exam('Physics', 4)],
      );
      expect(r.insights.length, 4);
      expect(r.insights.first.kind, InsightKind.exam);
    });

    test('a week that has not started yet gives no exam warnings', () {
      final WeeklyReport r = buildWeeklyReport(
        weekStart: DateTime(2026, 3, 16),
        thisWeek: const <EffortRow>[], lastWeek: const <EffortRow>[],
        plannedThisWeek: const <TaskRow>[], exams: <ExamCountdown>[exam('Maths', 5)], now: now,
      );
      expect(r.insights, isEmpty);
      expect(r.days.every((DayStat d) => d.isFuture), true);
    });
  });

  group('formatting and sharing', () {
    test('formatMinutes', () {
      expect(formatMinutes(0), '0 min');
      expect(formatMinutes(45), '45 min');
      expect(formatMinutes(60), '1 h');
      expect(formatMinutes(135), '2 h 15 min');
      expect(formatMinutes(-90), '1 h 30 min');
    });

    test('share text has the headline numbers', () {
      final WeeklyReport r = report(
        thisWeek: <EffortRow>[e('2026-03-09', 'Maths', 120), e('2026-03-10', 'Urdu', 30)],
        lastWeek: <EffortRow>[e('2026-03-02', 'Maths', 100)],
        planned: <TaskRow>[task('1', '2026-03-09', 'Maths', 60, done: true), task('2', '2026-03-10', 'Urdu', 30)],
      );
      final String t = r.toShareText();
      expect(t, contains('My study week (9 Mar – 15 Mar)'));
      expect(t, contains('Total: 2 h 30 min · 2/7 days'));
      expect(t, contains('vs last week: +50 min (50%)'));
      expect(t, contains('Sessions: 1 of 2 done (50%)'));
      expect(t, contains('• Maths: 2 h (80%)'));
    });
  });

  group('plannedForReport', () {
    test('earlier days count; today only when done; the future never', () {
      final List<TaskRow> r = plannedForReport(<TaskRow>[
        task('past-done', '2026-03-09', 'A', 30, done: true),
        task('past-open', '2026-03-10', 'A', 30),
        task('today-done', '2026-03-11', 'A', 30, done: true),
        task('today-open', '2026-03-11', 'A', 30),
        task('future', '2026-03-12', 'A', 30),
      ], '2026-03-11');
      expect(r.map((TaskRow t) => t.id).toList(), <String>['past-done', 'past-open', 'today-done']);
    });
  });
}

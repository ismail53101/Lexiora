import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/planning/day_planner.dart';

void main() {
  const int h = 60;

  PlanSubject sub(String name, double w, {List<String> topics = const <String>[]}) =>
      PlanSubject(name: name, weight: w, topics: topics, reason: 'r-$name');

  List<String> subjects(DayPlan p) => p.blocks.map((PlannedItem i) => i.subject!).toList();

  group('free gaps', () {
    test('the whole window when nothing is planned', () {
      final List<MinuteRange> g = freeGaps(const MinuteRange(16 * h, 21 * h), const <MinuteRange>[]);
      expect(g.map((MinuteRange r) => (r.start, r.end)).toList(), <(int, int)>[(960, 1260)]);
    });

    test('busy ranges are cut out, clipped to the window and merged', () {
      final List<MinuteRange> g = freeGaps(
        const MinuteRange(9 * h, 17 * h),
        const <MinuteRange>[
          MinuteRange(8 * h, 10 * h), // starts before the window
          MinuteRange(12 * h, 13 * h),
          MinuteRange(12 * h + 30, 14 * h), // overlaps the previous one
          MinuteRange(16 * h, 18 * h), // runs past the window
          MinuteRange(5 * h, 6 * h), // outside
        ],
      );
      expect(g.map((MinuteRange r) => (r.start, r.end)).toList(),
          <(int, int)>[(10 * h, 12 * h), (14 * h, 16 * h)]);
    });

    test('a fully busy window has no gaps', () {
      expect(freeGaps(const MinuteRange(9 * h, 10 * h), const <MinuteRange>[MinuteRange(8 * h, 11 * h)]), isEmpty);
    });
  });

  group('subject weight', () {
    test('base weight for a subject with nothing special', () {
      expect(subjectWeight(daysSinceStudied: 0), 1);
    });

    test('closer exams weigh more, and nothing beyond 60 days', () {
      expect(subjectWeight(daysToExam: 0, daysSinceStudied: 0), 5);
      expect(subjectWeight(daysToExam: 30, daysSinceStudied: 0), 3);
      expect(subjectWeight(daysToExam: 60, daysSinceStudied: 0), 1);
      expect(subjectWeight(daysToExam: 90, daysSinceStudied: 0), 1);
      expect(subjectWeight(daysToExam: -3, daysSinceStudied: 0), 1);
    });

    test('syllabus left and neglect add weight (capped)', () {
      expect(subjectWeight(syllabusRemaining: 1, daysSinceStudied: 0), 3);
      expect(subjectWeight(syllabusRemaining: 0.5, daysSinceStudied: 0), 2);
      expect(subjectWeight(daysSinceStudied: 14), 2.5);
      expect(subjectWeight(daysSinceStudied: 100), 2.5);
      expect(subjectWeight(daysSinceStudied: null), 2); // never studied
    });

    test('an urgent, half-finished, neglected subject outranks a relaxed one', () {
      final double urgent = subjectWeight(daysToExam: 5, syllabusRemaining: 0.8, daysSinceStudied: 6);
      final double relaxed = subjectWeight(daysToExam: 50, syllabusRemaining: 0.2, daysSinceStudied: 1);
      expect(urgent, greaterThan(relaxed * 2));
    });

    test('explanations', () {
      expect(explainSubject(daysToExam: 5, topicsLeft: 12, daysSinceStudied: 6),
          'Exam in 5 days · 12 topics left · not studied for 6 days');
      expect(explainSubject(daysToExam: 1, topicsLeft: 1, daysSinceStudied: 0), 'Exam tomorrow · 1 topic left');
      expect(explainSubject(daysSinceStudied: null), 'not studied yet');
      expect(explainSubject(daysToExam: 120, daysSinceStudied: 1), '');
    });
  });

  group('planDay', () {
    test('lays out focus blocks with breaks between them, never a trailing break', () {
      final DayPlan p = planDay(
        window: const MinuteRange(16 * h, 19 * h),
        subjects: <PlanSubject>[sub('Maths', 1)],
      );
      expect(p.items.map((PlannedItem i) => (i.isFocus ? 'F' : 'B', i.start, i.end)).toList(), <(String, int, int)>[
        ('F', 960, 1010),
        ('B', 1010, 1020),
        ('F', 1020, 1070),
        ('B', 1070, 1080),
        ('F', 1080, 1130),
      ]);
      expect(p.items.last.isFocus, true);
      expect(p.freeMinutesLeft, 1140 - 1130);
    });

    test('items never overlap, stay inside the window and avoid busy time', () {
      final DayPlan p = planDay(
        window: const MinuteRange(9 * h, 21 * h),
        busy: const <MinuteRange>[MinuteRange(12 * h, 13 * h + 30), MinuteRange(17 * h, 18 * h)],
        subjects: <PlanSubject>[sub('A', 3), sub('B', 2), sub('C', 1)],
      );
      for (int i = 0; i < p.items.length; i++) {
        final PlannedItem it = p.items[i];
        expect(it.start >= 9 * h && it.end <= 21 * h, true, reason: 'inside window');
        expect(it.end > it.start, true);
        for (final MinuteRange b in const <MinuteRange>[MinuteRange(12 * h, 13 * h + 30), MinuteRange(17 * h, 18 * h)]) {
          expect(it.end <= b.start || it.start >= b.end, true, reason: 'avoids busy time');
        }
        if (i > 0) expect(p.items[i - 1].end <= it.start, true, reason: 'no overlap');
      }
    });

    test('a break is always followed by a focus block', () {
      final DayPlan p = planDay(
        window: const MinuteRange(9 * h, 12 * h + 5),
        subjects: <PlanSubject>[sub('A', 1), sub('B', 1)],
      );
      for (int i = 0; i < p.items.length; i++) {
        if (!p.items[i].isFocus) {
          expect(i + 1 < p.items.length && p.items[i + 1].isFocus, true);
          expect(i > 0 && p.items[i - 1].isFocus, true);
        }
      }
    });

    test('minutes follow the weights', () {
      final DayPlan p = planDay(
        window: const MinuteRange(8 * h, 20 * h),
        subjects: <PlanSubject>[sub('Big', 3), sub('Small', 1)],
      );
      final Map<String, int> m = p.minutesBySubject;
      expect(m['Big']!, greaterThan(m['Small']! * 2));
      expect(m['Big']! + m['Small']!, p.focusMinutes);
    });

    test('similar weights alternate: no subject twice in a row', () {
      final DayPlan p = planDay(
        window: const MinuteRange(8 * h, 20 * h),
        subjects: <PlanSubject>[sub('A', 2), sub('B', 2), sub('C', 1.5)],
      );
      final List<String> s = subjects(p);
      for (int i = 1; i < s.length; i++) {
        expect(s[i], isNot(s[i - 1]));
      }
    });

    test('a much heavier subject may run back to back, but others still get time', () {
      final DayPlan p = planDay(
        window: const MinuteRange(8 * h, 20 * h),
        subjects: <PlanSubject>[sub('Big', 10), sub('Small', 1)],
      );
      final Map<String, int> m = p.minutesBySubject;
      expect(m['Big']!, greaterThan(m['Small']! * 4));
      expect(m['Small']!, greaterThan(0));
      expect(m.containsKey('Small'), true);
    });

    test('a single subject may repeat', () {
      final DayPlan p = planDay(
        window: const MinuteRange(9 * h, 12 * h),
        subjects: <PlanSubject>[sub('Only', 1)],
      );
      expect(subjects(p).toSet(), <String>{'Only'});
      expect(p.blocks.length, greaterThan(1));
    });

    test('suggests the next unfinished topic of each subject, in order', () {
      final DayPlan p = planDay(
        window: const MinuteRange(9 * h, 21 * h),
        subjects: <PlanSubject>[
          sub('Maths', 1, topics: <String>['Algebra', 'Calculus']),
          sub('Physics', 1, topics: <String>['Optics']),
        ],
      );
      final List<String?> maths = p.blocks.where((PlannedItem i) => i.subject == 'Maths').map((PlannedItem i) => i.topic).toList();
      expect(maths.take(2).toList(), <String?>['Algebra', 'Calculus']);
      expect(maths.skip(2).every((String? t) => t == null), true);
      expect(p.blocks.where((PlannedItem i) => i.subject == 'Physics').first.topic, 'Optics');
    });

    test('reasons are carried onto the blocks', () {
      final DayPlan p = planDay(window: const MinuteRange(9 * h, 11 * h), subjects: <PlanSubject>[sub('A', 1)]);
      expect(p.blocks.first.reason, 'r-A');
    });

    test('zero-weight subjects are ignored', () {
      final DayPlan p = planDay(
        window: const MinuteRange(9 * h, 12 * h),
        subjects: <PlanSubject>[sub('A', 1), sub('Never', 0)],
      );
      expect(subjects(p).contains('Never'), false);
    });

    test('short gaps are used for one shorter block; tiny ones are skipped', () {
      final DayPlan p = planDay(
        window: const MinuteRange(9 * h, 12 * h),
        busy: const <MinuteRange>[MinuteRange(9 * h + 40, 11 * h + 55)],
        subjects: <PlanSubject>[sub('A', 1)],
      );
      // 09:00-09:40 (40 min) is used; 11:55-12:00 (5 min) is skipped.
      expect(p.items.map((PlannedItem i) => (i.start, i.end)).toList(), <(int, int)>[(540, 580)]);
      expect(p.freeMinutesLeft, 5);
    });

    test('no subjects, a full day, or a too-small window give an empty plan', () {
      expect(planDay(window: const MinuteRange(9 * h, 12 * h), subjects: const <PlanSubject>[]).isEmpty, true);
      expect(planDay(window: const MinuteRange(9 * h, 12 * h), busy: const <MinuteRange>[MinuteRange(0, 24 * h)], subjects: <PlanSubject>[sub('A', 1)]).isEmpty, true);
      expect(planDay(window: const MinuteRange(9 * h, 9 * h + 10), subjects: <PlanSubject>[sub('A', 1)]).isEmpty, true);
    });

    test('custom block and break lengths are respected', () {
      final DayPlan p = planDay(
        window: const MinuteRange(9 * h, 11 * h),
        subjects: <PlanSubject>[sub('A', 1)],
        settings: const PlanSettings(focusMinutes: 25, breakMinutes: 5),
      );
      expect(p.items.first.minutes, 25);
      expect(p.items[1].minutes, 5);
      expect(p.items.last.isFocus, true);
    });

    test('it is deterministic', () {
      final List<PlanSubject> subs = <PlanSubject>[sub('A', 2), sub('B', 2), sub('C', 1)];
      final DayPlan a = planDay(window: const MinuteRange(9 * h, 20 * h), subjects: subs);
      final DayPlan b = planDay(window: const MinuteRange(9 * h, 20 * h), subjects: subs);
      expect(subjects(a), subjects(b));
    });
  });

  group('missed sessions', () {
    final DateTime t = DateTime(2026, 3, 10);
    StudyTask task(String id, String day, {int? start, int? end, bool done = false, bool isBreak = false}) => StudyTask(
          id: id, day: day, title: id, subject: id,
          kind: isBreak ? SessionKind.breakTime : SessionKind.session,
          startMinute: start, endMinute: end,
          status: done ? TaskStatus.completed : TaskStatus.pending,
          createdAt: t, updatedAt: t,
        );

    test('past days, and today only once the end time has passed', () {
      final List<StudyTask> m = findMissedSessions(
        <StudyTask>[
          task('old-timed', '2026-03-08', start: 9 * h, end: 10 * h),
          task('old-untimed', '2026-03-09'),
          task('today-past', '2026-03-10', start: 9 * h, end: 10 * h),
          task('today-running', '2026-03-10', start: 11 * h, end: 13 * h),
          task('today-later', '2026-03-10', start: 15 * h, end: 16 * h),
          task('today-untimed', '2026-03-10'),
          task('future', '2026-03-11', start: 9 * h, end: 10 * h),
        ],
        today: '2026-03-10',
        nowMinute: 12 * h,
      );
      expect(m.map((StudyTask x) => x.id).toList(), <String>['old-timed', 'old-untimed', 'today-past']);
    });

    test('completed sessions and breaks are never missed', () {
      final List<StudyTask> m = findMissedSessions(
        <StudyTask>[
          task('done', '2026-03-09', start: 9 * h, end: 10 * h, done: true),
          task('break', '2026-03-09', start: 10 * h, end: 10 * h + 10, isBreak: true),
        ],
        today: '2026-03-10',
        nowMinute: 12 * h,
      );
      expect(m, isEmpty);
    });
  });
}

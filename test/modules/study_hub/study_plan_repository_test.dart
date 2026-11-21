import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/study_hub/data/datasources/study_hub_local_data_source.dart';
import 'package:lexiora/modules/study_hub/data/repositories/study_hub_repository_impl.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/scheduling/study_schedule_service.dart';

void main() {
  const int h = 60;
  const String today = '2026-03-10';
  const String tomorrow = '2026-03-11';
  final List<AppDatabase> dbs = <AppDatabase>[];

  Future<StudyHubRepositoryImpl> repo() async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    dbs.add(db);
    return StudyHubRepositoryImpl(StudyHubLocalDataSource(db));
  }

  tearDownAll(() async {
    for (final AppDatabase d in dbs) {
      await d.close();
    }
  });

  StudyTask task(
    String id,
    String day,
    String subject, {
    int? start,
    int? end,
    bool done = false,
    bool isBreak = false,
    String? topic,
    bool auto = false,
    int? duration,
  }) {
    final DateTime t = DateTime(2026, 3, 1);
    return StudyTask(
      id: id,
      day: day,
      title: isBreak ? 'Break' : subject,
      subject: isBreak ? null : subject,
      topic: topic,
      kind: isBreak ? SessionKind.breakTime : SessionKind.session,
      startMinute: start,
      endMinute: end,
      durationMinutes: duration,
      autoScheduled: auto,
      status: done ? TaskStatus.completed : TaskStatus.pending,
      completedAt: done ? t : null,
      createdAt: t,
      updatedAt: t,
    );
  }

  Future<List<StudyTask>> dayRows(StudyHubRepositoryImpl r, String day) async {
    final List<StudyTask> t = await r.watchTasks(day).first;
    t.sort((StudyTask a, StudyTask b) => (a.startMinute ?? 99999).compareTo(b.startMinute ?? 99999));
    return t;
  }

  String line(StudyTask t) => '${t.isBreak ? 'B' : 'S'} ${t.title} ${t.startMinute}-${t.endMinute}';

  group('saveGeneratedPlan', () {
    test('saves the plan with fixed times', () async {
      final StudyHubRepositoryImpl r = await repo();
      final int n = await r.saveGeneratedPlan(day: today, items: <StudyTask>[
        task('p1', today, 'Maths', start: 16 * h, end: 16 * h + 50, topic: 'Algebra'),
        task('p2', today, '', start: 16 * h + 50, end: 17 * h, isBreak: true),
        task('p3', today, 'English', start: 17 * h, end: 17 * h + 50),
      ]);
      expect(n, 3);
      final List<StudyTask> rows = await dayRows(r, today);
      expect(rows.map(line).toList(), <String>['S Maths 960-1010', 'B Break 1010-1020', 'S English 1020-1070']);
      expect(rows.first.topic, 'Algebra');
      expect(rows.every((StudyTask t) => !t.autoScheduled), true);
    });

    test('saving the same plan again never duplicates', () async {
      final StudyHubRepositoryImpl r = await repo();
      final List<StudyTask> plan = <StudyTask>[
        task('p1', today, 'Maths', start: 16 * h, end: 17 * h),
        task('p2', today, 'English', start: 17 * h + 10, end: 18 * h),
      ];
      await r.saveGeneratedPlan(day: today, items: plan);
      await r.saveGeneratedPlan(day: today, items: plan);
      expect(await dayRows(r, today), hasLength(2));
    });

    test('an overlap with existing items saves nothing', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(task('fixed', today, 'Chemistry', start: 17 * h, end: 18 * h));
      await expectLater(
        r.saveGeneratedPlan(day: today, items: <StudyTask>[
          task('p1', today, 'Maths', start: 16 * h, end: 16 * h + 50),
          task('p2', today, 'English', start: 17 * h + 30, end: 18 * h + 30),
        ]),
        throwsA(isA<StudyScheduleOverlapException>()),
      );
      expect((await dayRows(r, today)).map((StudyTask t) => t.id).toList(), <String>['fixed']);
    });

    test('invalid times are rejected and nothing is saved', () async {
      final StudyHubRepositoryImpl r = await repo();
      await expectLater(
        r.saveGeneratedPlan(day: today, items: <StudyTask>[
          task('p1', today, 'Maths', start: 16 * h, end: 17 * h),
          task('p2', today, 'English', start: 23 * h, end: 25 * h),
        ]),
        throwsA(isA<StudyScheduleInvalidTimeException>()),
      );
      expect(await dayRows(r, today), isEmpty);
      expect(await r.saveGeneratedPlan(day: today, items: const <StudyTask>[]), 0);
    });

    test('the plan goes around items that were already there', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(task('fixed', today, 'Chemistry', start: 17 * h, end: 18 * h));
      await r.saveGeneratedPlan(day: today, items: <StudyTask>[
        task('p1', today, 'Maths', start: 16 * h, end: 17 * h),
        task('p2', today, 'English', start: 18 * h, end: 19 * h),
      ]);
      expect((await dayRows(r, today)).map(line).toList(),
          <String>['S Maths 960-1020', 'S Chemistry 1020-1080', 'S English 1080-1140']);
    });
  });

  group('lastStudiedDays', () {
    test('latest completed session per subject, case-insensitive, no breaks', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(task('1', '2026-03-01', 'Maths', start: 9 * h, end: 10 * h, done: true));
      await r.saveTask(task('2', '2026-03-05', 'maths', start: 9 * h, end: 10 * h, done: true));
      await r.saveTask(task('3', '2026-03-08', 'Maths', start: 9 * h, end: 10 * h)); // not done
      await r.saveTask(task('4', '2026-03-07', 'Physics', start: 9 * h, end: 10 * h, done: true));
      await r.saveTask(task('5', '2026-03-09', '', start: 10 * h, end: 10 * h + 10, isBreak: true, done: true));
      final Map<String, String> m = await r.lastStudiedDays();
      expect(m, <String, String>{'maths': '2026-03-05', 'physics': '2026-03-07'});
    });

    test('empty when nothing is completed', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(task('1', today, 'Maths', start: 9 * h, end: 10 * h));
      expect(await r.lastStudiedDays(), isEmpty);
    });
  });

  group('missed sessions', () {
    test('finds unfinished sessions from the last week and earlier today', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(task('old', '2026-03-09', 'Maths', start: 9 * h, end: 10 * h));
      await r.saveTask(task('done', '2026-03-09', 'Maths', start: 10 * h, end: 11 * h, done: true));
      await r.saveTask(task('today-past', today, 'English', start: 8 * h, end: 9 * h));
      await r.saveTask(task('today-later', today, 'Urdu', start: 15 * h, end: 16 * h));
      await r.saveTask(task('too-old', '2026-02-20', 'Physics', start: 9 * h, end: 10 * h));
      await r.saveTask(task('a-break', '2026-03-09', '', start: 12 * h, end: 12 * h + 10, isBreak: true));
      final List<StudyTask> m = await r.missedSessions(today: today, nowMinute: 12 * h);
      expect(m.map((StudyTask t) => t.id).toList(), <String>['old', 'today-past']);
    });
  });

  group('move to another day', () {
    test('missed timed sessions preserve their original clock time', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(task('tmrw', tomorrow, 'Chemistry', start: 13 * h, end: 14 * h));
      await r.saveTask(task('m1', '2026-03-09', 'Maths', start: 9 * h, end: 10 * h + 30, topic: 'Algebra'));
      await r.saveTask(task('m2', today, 'English', start: 8 * h, end: 8 * h + 45));
      final List<StudyTask> missed = await r.missedSessions(today: today, nowMinute: 12 * h);
      expect(await r.moveSessionsToDay(tasks: missed, toDay: tomorrow), 2);

      expect((await dayRows(r, tomorrow)).map(line).toList(),
          <String>['S Maths 540-630', 'S English 480-525', 'S Chemistry 780-840']);
      final StudyTask maths = (await dayRows(r, tomorrow)).firstWhere((StudyTask t) => t.id == 'm1');
      expect(maths.topic, 'Algebra');
      expect(maths.autoScheduled, false);
      expect(maths.status, TaskStatus.pending);
      expect(await dayRows(r, '2026-03-09'), isEmpty);
      expect(await dayRows(r, today), isEmpty);
      expect(await r.missedSessions(today: today, nowMinute: 12 * h), isEmpty);
    });

    test('untimed sessions get the default duration; breaks and same-day items are skipped', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(task('u', '2026-03-09', 'Maths'));
      final StudyTask br = task('b', '2026-03-09', '', start: 9 * h, end: 9 * h + 10, isBreak: true);
      final StudyTask same = task('s', tomorrow, 'Same', start: 9 * h, end: 10 * h);
      await r.saveTask(same);
      final StudyTask untimed = (await dayRows(r, '2026-03-09')).firstWhere((StudyTask t) => t.id == 'u');
      expect(await r.moveSessionsToDay(tasks: <StudyTask>[untimed, br, same], toDay: tomorrow), 1);
      final List<StudyTask> rows = await dayRows(r, tomorrow);
      expect(rows.map((StudyTask t) => t.id).toSet(), <String>{'u', 's'});
      final StudyTask u = rows.firstWhere((StudyTask t) => t.id == 'u');
      expect(u.endMinute! - u.startMinute!, StudyScheduleService.defaultSessionMinutes);
      expect(u.startMinute, 10 * h); // untimed items still use the next available slot
    });

    test('moving nothing does nothing', () async {
      final StudyHubRepositoryImpl r = await repo();
      expect(await r.moveSessionsToDay(tasks: const <StudyTask>[], toDay: tomorrow), 0);
    });

    test('moving the same sessions twice does not duplicate them', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(task('m1', '2026-03-09', 'Maths', start: 9 * h, end: 10 * h));
      final List<StudyTask> missed = await r.missedSessions(today: today, nowMinute: 12 * h);
      await r.moveSessionsToDay(tasks: missed, toDay: tomorrow);
      await r.moveSessionsToDay(tasks: missed, toDay: tomorrow);
      expect(await dayRows(r, tomorrow), hasLength(1));
    });
  });
}

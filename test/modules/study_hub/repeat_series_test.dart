import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/study_hub/data/datasources/study_hub_local_data_source.dart';
import 'package:lexiora/modules/study_hub/data/repositories/study_hub_repository_impl.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/recurrence/repeat_series.dart';
import 'package:lexiora/modules/study_hub/domain/scheduling/study_schedule_service.dart';

void main() {
  const int h = 60;
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

  final DateTime t0 = DateTime(2026, 3, 1);

  StudyTask template({String subject = 'Maths', int start = 18 * h, int duration = h, String? topic}) => StudyTask(
        id: 'tpl', day: '2026-03-09', title: subject, subject: subject, topic: topic,
        startMinute: start, endMinute: start + duration, createdAt: t0, updatedAt: t0,
      );

  // 2026-03-09 is a Monday.
  Future<RepeatSaveResult> create(
    StudyHubRepositoryImpl r, {
    String id = 's1',
    StudyTask? tpl,
    Set<int> weekdays = const <int>{1, 3},
    String start = '2026-03-09',
    String until = '2026-04-05', // 4 weeks
    int? breakMinutes,
  }) =>
      r.createRepeatingSessions(
        seriesId: id, template: tpl ?? template(), weekdays: weekdays,
        startDay: start, untilDay: until, breakMinutes: breakMinutes,
      );

  Future<List<StudyTask>> day(StudyHubRepositoryImpl r, String d) async {
    final List<StudyTask> t = await r.watchTasks(d).first;
    t.sort((StudyTask a, StudyTask b) => (a.startMinute ?? 0).compareTo(b.startMinute ?? 0));
    return t;
  }

  Future<RepeatSeries> only(StudyHubRepositoryImpl r, String today) async =>
      (await r.watchSeries(today: today).first).single;

  group('create', () {
    test('one session per matching day with the chosen time, subject and topic', () async {
      final StudyHubRepositoryImpl r = await repo();
      final RepeatSaveResult res = await create(r, tpl: template(topic: 'Algebra'));
      expect(res.created, 8);
      expect(res.skippedDays, isEmpty);
      for (final String d in <String>['2026-03-09', '2026-03-11', '2026-03-16', '2026-04-01']) {
        final StudyTask s = (await day(r, d)).single;
        expect((s.title, s.subject, s.topic, s.startMinute, s.endMinute), ('Maths', 'Maths', 'Algebra', 18 * h, 19 * h));
        expect(s.autoScheduled, false);
        expect(s.status, TaskStatus.pending);
      }
      expect(await day(r, '2026-03-10'), isEmpty); // a Tuesday
      expect(await day(r, '2026-04-06'), isEmpty); // after the end
    });

    test('with a break: a break follows every session', () async {
      final StudyHubRepositoryImpl r = await repo();
      await create(r, breakMinutes: 10, weekdays: <int>{1}, until: '2026-03-22');
      final List<StudyTask> d = await day(r, '2026-03-16');
      expect(d.map((StudyTask t) => (t.isBreak, t.startMinute, t.endMinute)).toList(),
          <(bool, int?, int?)>[(false, 18 * h, 19 * h), (true, 19 * h, 19 * h + 10)]);
    });

    test('saving again with the same series id never duplicates', () async {
      final StudyHubRepositoryImpl r = await repo();
      await create(r, breakMinutes: 10);
      final RepeatSaveResult again = await create(r, breakMinutes: 10);
      expect(again.created, 8);
      expect(await day(r, '2026-03-09'), hasLength(2));
      expect((await r.watchSeries(today: '2026-03-01').first), hasLength(1));
    });

    test('a day whose time is taken is skipped and reported, the rest are created', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(StudyTask(
        id: 'clash', day: '2026-03-11', title: 'Chemistry', subject: 'Chemistry',
        startMinute: 18 * h + 30, endMinute: 19 * h + 30, createdAt: t0, updatedAt: t0,
      ));
      final RepeatSaveResult res = await create(r);
      expect(res.created, 7);
      expect(res.skippedDays, <String>['2026-03-11']);
      expect((await day(r, '2026-03-11')).map((StudyTask t) => t.id).toList(), <String>['clash']);
    });

    test('if every day clashes, nothing is created and no series is stored', () async {
      final StudyHubRepositoryImpl r = await repo();
      for (final String d in <String>['2026-03-09', '2026-03-16']) {
        await r.saveTask(StudyTask(
          id: 'c$d', day: d, title: 'X', subject: 'X', startMinute: 18 * h, endMinute: 19 * h, createdAt: t0, updatedAt: t0,
        ));
      }
      final RepeatSaveResult res = await create(r, weekdays: <int>{1}, until: '2026-03-22');
      expect((res.created, res.skippedDays.length), (0, 2));
      expect(await r.watchSeries(today: '2026-03-01').first, isEmpty);
    });

    test('automatic sessions on that day move out of the way', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(StudyTask(
        id: 'auto', day: '2026-03-09', title: 'Reading', subject: 'Reading', autoScheduled: true,
        startMinute: 18 * h, endMinute: 19 * h, durationMinutes: h, createdAt: t0, updatedAt: t0,
      ));
      // The manual weekly session at 18:00 would collide with the automatic one:
      // the automatic one is re-flowed after it, so the day has no overlap.
      final RepeatSaveResult res = await create(r, weekdays: <int>{1}, until: '2026-03-15');
      expect(res.created, 1);
      final List<StudyTask> d = await day(r, '2026-03-09');
      expect(StudyScheduleService.conflicts(d), isEmpty);
    });

    test('invalid input is rejected and nothing is saved', () async {
      final StudyHubRepositoryImpl r = await repo();
      await expectLater(create(r, weekdays: const <int>{}), throwsA(isA<StudyScheduleInvalidTimeException>()));
      await expectLater(create(r, tpl: template(start: 23 * h, duration: 2 * h)), throwsA(isA<StudyScheduleInvalidTimeException>()));
      await expectLater(create(r, tpl: template(start: 22 * h + 30, duration: 45), breakMinutes: 60), throwsA(isA<StudyScheduleInvalidTimeException>()));
      await expectLater(create(r, weekdays: <int>{2}, start: '2026-03-09', until: '2026-03-09'), throwsA(isA<StudyScheduleInvalidTimeException>()));
      await expectLater(
        r.createRepeatingSessions(
          seriesId: 'x',
          template: template().copyWith(clearTimes: true),
          weekdays: <int>{1}, startDay: '2026-03-09', untilDay: '2026-04-05',
        ),
        throwsA(isA<StudyScheduleInvalidTimeException>()),
      );
      expect(await r.watchSeries(today: '2026-03-01').first, isEmpty);
    });
  });

  group('watchSeries', () {
    test('describes the series with upcoming sessions and the next one not done yet', () async {
      final StudyHubRepositoryImpl r = await repo();
      await create(r, breakMinutes: 10);
      RepeatSeries s = await only(r, '2026-03-01');
      expect((s.subject, s.startMinute, s.endMinute, s.breakMinutes), ('Maths', 18 * h, 19 * h, 10));
      expect(s.weekdays, <int>{1, 3});
      expect((s.startDay, s.untilDay, s.upcoming, s.nextDay), ('2026-03-09', '2026-04-01', 8, '2026-03-09'));

      s = await only(r, '2026-03-12'); // 9 and 11 Mar are already in the past
      expect((s.upcoming, s.nextDay), (6, '2026-03-16'));

      // finishing the next one moves "next" on
      await r.setTaskCompleted('s1:2026-03-16', completed: true);
      s = await only(r, '2026-03-12');
      expect(s.nextDay, '2026-03-18');
      expect(s.isFinished, false);
      expect((await only(r, '2026-06-01')).isFinished, true);
    });
  });

  group('endSeries', () {
    test('deletes upcoming sessions and their breaks, keeps past and completed ones', () async {
      final StudyHubRepositoryImpl r = await repo();
      await create(r, breakMinutes: 10);
      await r.setTaskCompleted('s1:2026-03-18', completed: true); // upcoming but already done
      final int removed = await r.endSeries(seriesId: 's1', fromDay: '2026-03-16');
      // Upcoming from 16 Mar: 16, 18, 23, 25, 30, 1 Apr = 6, one is done -> 5 removed.
      expect(removed, 5);
      expect((await day(r, '2026-03-09')).where((StudyTask t) => !t.isBreak), hasLength(1)); // past
      expect((await day(r, '2026-03-18')).where((StudyTask t) => !t.isBreak), hasLength(1)); // completed stays
      expect(await day(r, '2026-03-16'), isEmpty);
      expect(await day(r, '2026-04-01'), isEmpty);
      final RepeatSeries s = await only(r, '2026-03-01');
      expect(s.untilDay, '2026-03-15');
    });

    test('ending a series with nothing left to keep removes it entirely', () async {
      final StudyHubRepositoryImpl r = await repo();
      await create(r);
      expect(await r.endSeries(seriesId: 's1', fromDay: '2026-03-01'), 8);
      expect(await r.watchSeries(today: '2026-03-01').first, isEmpty);
      expect(await day(r, '2026-03-09'), isEmpty);
    });

    test('a session deleted by hand does not break ending the series', () async {
      final StudyHubRepositoryImpl r = await repo();
      await create(r);
      await r.deleteTask('s1:2026-03-11');
      expect(await r.endSeries(seriesId: 's1', fromDay: '2026-03-01'), 7);
      expect(await r.watchSeries(today: '2026-03-01').first, isEmpty);
    });

    test('other series are untouched', () async {
      final StudyHubRepositoryImpl r = await repo();
      await create(r);
      await create(r, id: 's2', tpl: template(subject: 'Physics', start: 20 * h), weekdays: <int>{2});
      await r.endSeries(seriesId: 's1', fromDay: '2026-03-01');
      final List<RepeatSeries> left = await r.watchSeries(today: '2026-03-01').first;
      expect(left.map((RepeatSeries s) => s.subject).toList(), <String>['Physics']);
      expect(await day(r, '2026-03-10'), hasLength(1));
    });
  });

  group('extendSeries', () {
    test('adds more weeks after the last day', () async {
      final StudyHubRepositoryImpl r = await repo();
      await create(r); // until 5 Apr
      final RepeatSaveResult res = await r.extendSeries(seriesId: 's1', weeks: 2, today: '2026-03-10');
      expect(res.created, 4); // 6, 8, 13, 15 Apr
      expect((await day(r, '2026-04-08')).single.startMinute, 18 * h);
      final RepeatSeries s = await only(r, '2026-03-10');
      expect(s.untilDay, '2026-04-15'); // two weeks after the last session (1 Apr)
      expect(s.upcoming, 11);
    });

    test('a finished series restarts from today, not from the past', () async {
      final StudyHubRepositoryImpl r = await repo();
      await create(r, until: '2026-03-15'); // 9, 11
      final RepeatSaveResult res = await r.extendSeries(seriesId: 's1', weeks: 1, today: '2026-06-01'); // a Monday
      expect(res.created, 2); // 1 Jun and 3 Jun
      expect(await day(r, '2026-06-01'), hasLength(1));
      expect(await day(r, '2026-05-20'), isEmpty);
    });

    test('extending keeps breaks and skips clashes', () async {
      final StudyHubRepositoryImpl r = await repo();
      await create(r, breakMinutes: 10, weekdays: <int>{1}, until: '2026-03-15');
      await r.saveTask(StudyTask(
        id: 'clash', day: '2026-03-23', title: 'X', subject: 'X', startMinute: 18 * h, endMinute: 19 * h, createdAt: t0, updatedAt: t0,
      ));
      final RepeatSaveResult res = await r.extendSeries(seriesId: 's1', weeks: 2, today: '2026-03-10');
      expect(res.created, 1);
      expect(res.skippedDays, <String>['2026-03-23']);
      expect((await day(r, '2026-03-16')).where((StudyTask t) => t.isBreak), hasLength(1));
    });

    test('an unknown series or zero weeks does nothing', () async {
      final StudyHubRepositoryImpl r = await repo();
      await expectLater(r.extendSeries(seriesId: 'nope', weeks: 2, today: '2026-03-10'), throwsA(isA<ArgumentError>()));
      await create(r);
      expect((await r.extendSeries(seriesId: 's1', weeks: 0, today: '2026-03-10')).created, 0);
    });
  });

  test('the series stream updates when sessions change', () async {
    final StudyHubRepositoryImpl r = await repo();
    final List<int> counts = <int>[];
    final sub = r.watchSeries(today: '2026-03-01').listen((List<RepeatSeries> s) => counts.add(s.isEmpty ? 0 : s.single.upcoming));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await create(r);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await r.endSeries(seriesId: 's1', fromDay: '2026-03-01');
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await sub.cancel();
    expect(counts.first, 0);
    expect(counts.contains(8), true);
    expect(counts.last, 0);
  });
}

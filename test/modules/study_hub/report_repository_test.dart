import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/database/raw_sql.dart';
import 'package:lexiora/modules/study_hub/data/datasources/study_hub_local_data_source.dart';
import 'package:lexiora/modules/study_hub/data/repositories/report_repository_impl.dart';
import 'package:lexiora/modules/study_hub/data/repositories/study_hub_repository_impl.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/report_repository.dart';
import 'package:lexiora/modules/study_hub/domain/report/weekly_report.dart';

/// Reads real rows written through the planner's own repository, so the SQL
/// column names are checked against the actual tables.
void main() {
  final List<AppDatabase> dbs = <AppDatabase>[];

  Future<(StudyHubRepositoryImpl, ReportRepositoryImpl)> fresh() async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    dbs.add(db);
    return (StudyHubRepositoryImpl(StudyHubLocalDataSource(db)), ReportRepositoryImpl(DriftRawSql(db)));
  }

  tearDownAll(() async {
    for (final AppDatabase d in dbs) {
      await d.close();
    }
  });

  final DateTime t = DateTime(2026, 3, 1);
  StudyTask task(
    String id,
    String day, {
    String? subject,
    String title = 'Task',
    int? start,
    int? end,
    int? duration,
    bool done = false,
    bool isBreak = false,
  }) =>
      StudyTask(
        id: id, day: day, title: title, subject: subject,
        kind: isBreak ? SessionKind.breakTime : SessionKind.session,
        startMinute: start, endMinute: end, durationMinutes: duration,
        status: done ? TaskStatus.completed : TaskStatus.pending,
        completedAt: done ? t : null, createdAt: t, updatedAt: t,
      );

  StudySession log(String id, String day, DateTime startedAt, int minutes, {String? subject, String? taskId, String kind = 'pomodoro'}) =>
      StudySession(id: id, day: day, startedAt: startedAt, durationMinutes: minutes, subject: subject, taskId: taskId, kind: kind, createdAt: startedAt);

  test('reads timer logs with subject, task link and local start time', () async {
    final (StudyHubRepositoryImpl planner, ReportRepositoryImpl report) = await fresh();
    await planner.addSession(log('l1', '2026-03-10', DateTime(2026, 3, 10, 18, 30), 25, subject: 'Maths', taskId: 't1'));
    await planner.addSession(log('l2', '2026-03-12', DateTime(2026, 3, 12, 7, 5), 40, kind: 'manual'));
    await planner.addSession(log('outside', '2026-04-01', DateTime(2026, 4, 1, 9), 99));
    final ReportSource src = await report.load(startDay: '2026-03-09', endDay: '2026-03-15');
    expect(src.logs, hasLength(2));
    final TimerLog l1 = src.logs.firstWhere((TimerLog l) => l.taskId == 't1');
    expect((l1.day, l1.minutes, l1.subject, l1.startMinuteOfDay), ('2026-03-10', 25, 'Maths', 18 * 60 + 30));
    final TimerLog l2 = src.logs.firstWhere((TimerLog l) => l.taskId == null);
    expect((l2.minutes, l2.subject, l2.startMinuteOfDay), (40, null, 7 * 60 + 5));
  });

  test('reads planned sessions only (no breaks) with planned length and completion', () async {
    final (StudyHubRepositoryImpl planner, ReportRepositoryImpl report) = await fresh();
    await planner.saveTask(task('a', '2026-03-09', subject: 'Maths', start: 540, end: 600, duration: 60, done: true));
    await planner.saveTask(task('b', '2026-03-10', subject: '', title: 'Read news', start: 600, end: 645)); // length from end-start, subject from title
    await planner.saveTask(task('c', '2026-03-11', subject: 'Urdu')); // untimed
    await planner.saveTask(task('brk', '2026-03-09', title: 'Break', start: 600, end: 610, isBreak: true));
    await planner.saveTask(task('late', '2026-03-30', subject: 'X', start: 540, end: 600));
    final ReportSource src = await report.load(startDay: '2026-03-09', endDay: '2026-03-15');
    final Map<String, TaskRow> byId = <String, TaskRow>{for (final TaskRow r in src.tasks) r.id: r};
    expect(byId.keys.toSet(), <String>{'a', 'b', 'c'});
    expect((byId['a']!.subject, byId['a']!.plannedMinutes, byId['a']!.completed, byId['a']!.startMinuteOfDay), ('Maths', 60, true, 540));
    expect((byId['b']!.subject, byId['b']!.plannedMinutes, byId['b']!.completed), ('Read news', 45, false));
    expect(byId['c']!.plannedMinutes, 0);
  });

  test('a full week: ticked sessions count without timers, timers are not double counted', () async {
    final (StudyHubRepositoryImpl planner, ReportRepositoryImpl report) = await fresh();
    await planner.saveTask(task('t1', '2026-03-09', subject: 'Maths', start: 540, end: 600, duration: 60, done: true)); // has logs
    await planner.addSession(log('l1', '2026-03-09', DateTime(2026, 3, 9, 9), 25, subject: 'Maths', taskId: 't1'));
    await planner.addSession(log('l2', '2026-03-09', DateTime(2026, 3, 9, 9, 30), 25, subject: 'Maths', taskId: 't1'));
    await planner.saveTask(task('t2', '2026-03-10', subject: 'Physics', start: 17 * 60, end: 18 * 60, duration: 60, done: true)); // no logs
    await planner.saveTask(task('t3', '2026-03-11', subject: 'Urdu', start: 600, end: 660, duration: 60)); // not done

    final ReportSource src = await report.load(startDay: '2026-03-02', endDay: '2026-03-15');
    final WeeklyReport r = buildWeeklyReport(
      weekStart: DateTime(2026, 3, 9),
      thisWeek: mergeEffort(src.logs, src.tasks),
      lastWeek: const <EffortRow>[],
      plannedThisWeek: plannedForReport(src.tasks, '2026-03-12'),
      now: DateTime(2026, 3, 12, 12),
    );
    expect(r.totalMinutes, 50 + 60);
    expect(r.subjects.map((SubjectShare s) => (s.subject, s.minutes)).toList(), <(String, int)>[('Physics', 60), ('Maths', 50)]);
    expect((r.plannedSessions, r.completedSessions), (3, 2));
    expect(r.days[0].minutes, 50);
    expect(r.days[1].minutes, 60);
    expect(r.bestPart, isNotNull);
  });

  test('an empty range gives empty lists', () async {
    final (StudyHubRepositoryImpl _, ReportRepositoryImpl report) = await fresh();
    final ReportSource src = await report.load(startDay: '2026-03-09', endDay: '2026-03-15');
    expect(src.logs, isEmpty);
    expect(src.tasks, isEmpty);
  });
}

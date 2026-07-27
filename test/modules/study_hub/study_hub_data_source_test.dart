import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/study_hub/data/datasources/study_hub_local_data_source.dart';
import 'package:lexiora/modules/study_hub/data/repositories/study_hub_repository_impl.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_goal.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_template.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';

void main() {
  late AppDatabase db;
  late StudyHubRepositoryImpl repo;
  final String today = todayKey();
  final String yesterday =
      dayKey(DateTime.now().subtract(const Duration(days: 1)));

  StudyTask session(
    String id, {
    TaskStatus status = TaskStatus.pending,
    String? subject,
    String? topic,
    String? day,
    int? start,
    int? end,
  }) {
    final DateTime now = DateTime.now();
    return StudyTask(
      id: id,
      day: day ?? today,
      title: subject ?? 'Session $id',
      subject: subject,
      topic: topic,
      status: status,
      startMinute: start,
      endMinute: end,
      completedAt: status == TaskStatus.completed ? now : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  StudyTask brk(String id, {required int start, required int end, String? day}) {
    final DateTime now = DateTime.now();
    return StudyTask(
      id: id,
      day: day ?? today,
      title: 'Tea Break',
      kind: SessionKind.breakTime,
      startMinute: start,
      endMinute: end,
      createdAt: now,
      updatedAt: now,
    );
  }

  StudyGoal goal(String id,
      {required int target, required int current, GoalType type = GoalType.custom}) {
    final DateTime now = DateTime.now();
    return StudyGoal(
      id: id,
      day: today,
      title: 'Goal $id',
      type: type,
      targetCount: target,
      currentCount: current,
      createdAt: now,
      updatedAt: now,
    );
  }

  StudySession log(String id, {required int minutes, required String day}) {
    final DateTime now = DateTime.now();
    return StudySession(
      id: id,
      day: day,
      startedAt: now,
      durationMinutes: minutes,
      createdAt: now,
    );
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StudyHubRepositoryImpl(StudyHubLocalDataSource(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('session CRUD, status round-trip and completion mirror', () async {
    await repo.saveTask(session('a', subject: 'Physics', topic: 'Motion'));
    await repo.saveTask(session('b', subject: 'English'));
    expect((await repo.watchTasks(today).first).length, 2);

    await repo.setTaskStatus('a', TaskStatus.inProgress);
    StudyTask a =
        (await repo.watchTasks(today).first).firstWhere((StudyTask t) => t.id == 'a');
    expect(a.status, TaskStatus.inProgress);
    expect(a.completed, isFalse);
    expect(a.topic, 'Motion');

    await repo.setTaskCompleted('a', completed: true);
    a = (await repo.watchTasks(today).first).firstWhere((StudyTask t) => t.id == 'a');
    expect(a.status, TaskStatus.completed);
    expect(a.completed, isTrue);

    await repo.deleteTask('b');
    expect((await repo.watchTasks(today).first).length, 1);
  });

  test('subject & topic suggestions come from the user history', () async {
    await repo.saveTask(session('a', subject: 'Pakistan Affairs', topic: 'Economy'));
    await repo.saveTask(session('b', subject: 'English', topic: 'Essay'));
    expect(await repo.subjectSuggestions(),
        containsAll(<String>['English', 'Pakistan Affairs']));
    expect(await repo.topicSuggestions(), containsAll(<String>['Economy', 'Essay']));
  });

  test('breaks count as break time, not sessions', () async {
    await repo.saveTask(session('s', status: TaskStatus.completed, subject: 'Maths'));
    await repo.saveTask(brk('b', start: 11 * 60, end: 11 * 60 + 20)); // 20 min

    final StudyStats s = await repo.watchStats(StudyRange.weekly).first;
    expect(s.completedSessions, 1, reason: 'break excluded from sessions');
    expect(s.breakMinutes, 20);
  });

  test('weekly stats: subjects, topics, pending, completed', () async {
    await repo.saveTask(
        session('c1', status: TaskStatus.completed, subject: 'Physics', topic: 'Motion'));
    await repo.saveTask(
        session('c2', status: TaskStatus.completed, subject: 'English', topic: 'Essay'));
    await repo.saveTask(session('p1', subject: 'Physics')); // pending, same subject
    await repo.saveGoal(goal('gv', target: 10, current: 12, type: GoalType.vocabulary));
    await repo.addSession(log('L1', minutes: 50, day: today));

    final StudyStats s = await repo.watchStats(StudyRange.weekly).first;
    expect(s.completedSessions, 2);
    expect(s.pendingSessions, 1);
    expect(s.subjectsStudied, 2, reason: 'Physics + English (distinct)');
    expect(s.topicsCompleted, 2, reason: 'Motion + Essay');
    expect(s.vocabularyLearned, 12);
    expect(s.studyMinutes, 50);
  });

  test('templates: save a day, then apply to another day (editable copies)',
      () async {
    await repo.saveTask(session('a', subject: 'History', topic: 'Wars', start: 9 * 60, end: 10 * 60));
    await repo.saveTask(brk('b', start: 10 * 60, end: 10 * 60 + 15));

    await repo.saveTemplateFromDay('CSS Routine', today);
    final List<StudyTemplate> templates = await repo.watchTemplates().first;
    expect(templates.length, 1);
    expect(templates.single.name, 'CSS Routine');
    expect(templates.single.itemCount, 2);

    final List<StudyTemplateItem> items =
        await repo.templateItems(templates.single.id);
    expect(items.length, 2);

    final int added = await repo.applyTemplateToDay(templates.single.id, yesterday);
    expect(added, 2);
    final List<StudyTask> applied = await repo.watchTasks(yesterday).first;
    expect(applied.length, 2);
    // Applied entries are normal, editable rows on the target day.
    expect(applied.any((StudyTask t) => t.subject == 'History'), isTrue);
    expect(applied.any((StudyTask t) => t.isBreak), isTrue);
  });

  test('backward compatibility: a pre-v0.7.1 style row maps cleanly', () async {
    // Simulate an old row via a raw insert with only the original columns.
    await db.customStatement(
      'INSERT INTO study_tasks (id, day, title, priority, completed, '
      'order_index, created_at, updated_at) '
      "VALUES ('old', '$today', 'Legacy task', 1, 1, 0, 0, 0)",
    );
    final StudyTask t =
        (await repo.watchTasks(today).first).firstWhere((StudyTask e) => e.id == 'old');
    expect(t.completed, isTrue, reason: 'old completed flag honoured');
    expect(t.status, TaskStatus.completed);
    expect(t.isBreak, isFalse, reason: 'defaults to session');
    expect(t.displaySubject, 'Legacy task');
  });

  test('streak counts consecutive active days', () async {
    await repo.addSession(log('t', minutes: 25, day: today));
    await repo.addSession(log('y', minutes: 25, day: yesterday));
    final StudyStreak streak = await repo.watchStreak().first;
    expect(streak.current, 2);
    expect(streak.best, greaterThanOrEqualTo(2));
  });
}

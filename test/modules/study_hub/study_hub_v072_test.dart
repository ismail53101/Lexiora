import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/study_hub/data/datasources/study_hub_local_data_source.dart';
import 'package:lexiora/modules/study_hub/data/repositories/study_hub_repository_impl.dart';
import 'package:lexiora/modules/study_hub/domain/entities/session_filter.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_subject.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/study_hub_repository.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';

void main() {
  late AppDatabase db;
  late StudyHubRepositoryImpl repo;
  final String today = todayKey();

  StudyTask session(String id,
      {String? subject,
      String? topic,
      TaskStatus status = TaskStatus.pending,
      TaskPriority priority = TaskPriority.medium}) {
    final DateTime now = DateTime.now();
    return StudyTask(
      id: id,
      day: today,
      title: subject ?? id,
      subject: subject,
      topic: topic,
      status: status,
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
  }

  StudySubject subject(String id, String name, int color) {
    final DateTime now = DateTime.now();
    return StudySubject(
        id: id, name: name, color: color, createdAt: now, updatedAt: now);
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StudyHubRepositoryImpl(StudyHubLocalDataSource(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('subject colours: save, live map, and change', () async {
    await repo.saveSubject(subject('s1', 'Physics', 0xFF1E88E5));
    Map<String, int> colors = await repo.watchSubjectColors().first;
    expect(colors['physics'], 0xFF1E88E5);

    await repo.setSubjectColor('s1', 0xFFE53935);
    colors = await repo.watchSubjectColors().first;
    expect(colors['physics'], 0xFFE53935);
  });

  test('deleting a subject colour keeps study history', () async {
    await repo.saveTask(session('t1', subject: 'Maths'));
    await repo.saveSubject(subject('s1', 'Maths', 0xFF43A047));
    await repo.deleteSubject('s1');

    // Session remains…
    expect((await repo.watchTasks(today).first).length, 1);
    // …but the colour is gone.
    expect((await repo.watchSubjectColors().first).containsKey('maths'), isFalse);
  });

  test('rename subject updates history and keeps the colour', () async {
    await repo.saveTask(session('t1', subject: 'Physics'));
    await repo.saveTask(session('t2', subject: 'physics'));
    await repo.saveSubject(subject('s1', 'Physics', 0xFF1E88E5));

    await repo.renameSubject('s1', 'Phys');

    final List<StudyTask> tasks = await repo.watchTasks(today).first;
    expect(tasks.every((StudyTask t) => t.subject == 'Phys'), isTrue);
    final Map<String, int> colors = await repo.watchSubjectColors().first;
    expect(colors.containsKey('phys'), isTrue);
    expect(colors.containsKey('physics'), isFalse);
  });

  test('archive keeps colour usable; usage lists include session subjects',
      () async {
    await repo.saveTask(session('t1', subject: 'English'));
    await repo.saveSubject(subject('s1', 'English', 0xFF8E24AA));
    await repo.setSubjectArchived('s1', true);

    final active = await repo.allSubjectsWithUsage();
    expect(active.any((SubjectUsage u) => u.name == 'English'), isFalse,
        reason: 'archived excluded by default');
    final all = await repo.allSubjectsWithUsage(includeArchived: true);
    expect(all.any((SubjectUsage u) => u.name == 'English'), isTrue);
  });

  test('search: combined filters (query + status + priority)', () async {
    await repo.saveTask(session('a',
        subject: 'Physics', topic: 'Motion', status: TaskStatus.completed, priority: TaskPriority.high));
    await repo.saveTask(session('b',
        subject: 'Physics', topic: 'Optics', priority: TaskPriority.low));
    await repo.saveTask(session('c', subject: 'English', status: TaskStatus.completed));

    // Text search on subject.
    expect(
        (await repo.searchSessions(const SessionFilter(query: 'phys')).first).length, 2);
    // Text search on topic.
    expect(
        (await repo.searchSessions(const SessionFilter(query: 'optics')).first).single.id, 'b');
    // Status filter.
    expect(
        (await repo
                .searchSessions(const SessionFilter(status: SessionStatusFilter.completed))
                .first)
            .length,
        2);
    // Priority filter.
    expect(
        (await repo
                .searchSessions(const SessionFilter(priority: PriorityFilter.high))
                .first)
            .single
            .id,
        'a');
    // Subject filter.
    expect(
        (await repo.searchSessions(const SessionFilter(subject: 'English')).first).length, 1);
  });

  test('recent & frequent subjects', () async {
    await repo.saveTask(session('a', subject: 'Alpha'));
    await repo.saveTask(session('b', subject: 'Beta'));
    await repo.saveTask(session('c', subject: 'Beta'));
    final List<String> frequent = await repo.frequentSubjects(limit: 5);
    expect(frequent.first, 'Beta', reason: 'Beta used most');
    final List<String> recent = await repo.recentSubjects(limit: 5);
    expect(recent, containsAll(<String>['Alpha', 'Beta']));
  });

  test('backup export → wipe → restore round-trips', () async {
    await repo.saveTask(session('t1', subject: 'History', topic: 'Wars'));
    await repo.saveSubject(subject('s1', 'History', 0xFF6D4C41));
    final Map<String, dynamic> backup = await repo.exportBackup();

    // Wipe everything.
    await repo.importBackup(<String, dynamic>{});
    expect((await repo.watchTasks(today).first), isEmpty);
    expect((await repo.watchSubjectColors().first), isEmpty);

    // Restore.
    await repo.importBackup(backup);
    expect((await repo.watchTasks(today).first).single.topic, 'Wars');
    expect((await repo.watchSubjectColors().first)['history'], 0xFF6D4C41);
  });
}

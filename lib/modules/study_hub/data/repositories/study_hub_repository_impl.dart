import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/study_hub/data/datasources/study_hub_local_data_source.dart';
import 'package:lexiora/modules/study_hub/domain/entities/session_filter.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_goal.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_subject.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_template.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/study_hub_repository.dart';
import 'package:lexiora/modules/study_hub/domain/scheduling/study_schedule_service.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:uuid/uuid.dart';

/// Maps Drift rows to domain entities and computes the streak. Backward
/// compatible: pre-v0.7.1 rows (no topic/notes/status/kind) map cleanly.
class StudyHubRepositoryImpl implements StudyHubRepository {
  StudyHubRepositoryImpl(this._local, {this.onTasksChanged});

  final StudyHubLocalDataSource _local;
  final Future<void> Function()? onTasksChanged;
  static const Uuid _uuid = Uuid();

  // ── Planner ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<StudyTask>> watchTasks(String day) => _local
      .watchTasks(day)
      .map((List<StudyTaskRow> r) => r.map(_toTask).toList(growable: false));

  @override
  Stream<List<StudyTask>> watchTasksInRange(String startDay, String endDay) =>
      _local.watchTasksInRange(startDay, endDay).map(
          (List<StudyTaskRow> r) => r.map(_toTask).toList(growable: false));

  @override
  Future<void> saveTask(StudyTask t) async {
    final List<StudyTaskRow> storedRows = await _local.getTasks(t.day);
    final List<StudyTask> existing = storedRows.map(_toTask).toList();
    final StudyTask prepared = _prepareIncoming(t, existing);
    final List<StudyTask> all = <StudyTask>[
      ...existing.where((StudyTask row) => row.id != t.id),
      prepared,
    ];
    final List<StudyTask> recalculated = StudyScheduleService.recalculate(all);
    final List<StudyScheduleConflict> conflicts =
        StudyScheduleService.conflicts(recalculated);
    final List<StudyScheduleConflict> ownConflicts = conflicts
        .where((StudyScheduleConflict c) => c.item.id == prepared.id)
        .toList(growable: false);
    final StudyScheduleConflict? ownConflict =
        ownConflicts.isEmpty ? null : ownConflicts.first;
    if (ownConflict != null) {
      throw StudyScheduleOverlapException(ownConflict);
    }
    await _persistDay(t.day, all, recalculated);
    await onTasksChanged?.call();
  }

  @override
  Future<void> deleteTask(String id) async {
    final StudyTaskRow? row = await _local.getTask(id);
    if (row == null) return;
    await _local.deleteTask(id);
    final List<StudyTask> remaining =
        (await _local.getTasks(row.day)).map(_toTask).toList();
    final List<StudyTask> recalculated = StudyScheduleService.recalculate(remaining);
    await _persistDay(row.day, remaining, recalculated);
    await onTasksChanged?.call();
  }

  StudyTask _prepareIncoming(StudyTask task, List<StudyTask> existing) {
    if (!task.autoScheduled) return task;
    final int next = StudyScheduleService.nextAvailableMinute(
      existing,
      excludeId: task.id,
    );
    final int start = next;
    final int duration = StudyScheduleService.durationOf(task);
    return task.copyWith(
      startMinute: start,
      endMinute: start + duration,
      durationMinutes: duration,
    );
  }

  Future<void> _persistDay(
    String day,
    List<StudyTask> original,
    List<StudyTask> recalculated,
  ) {
    final Map<String, StudyTask> scheduled = <String, StudyTask>{
      for (final StudyTask task in recalculated) task.id: task,
    };
    final List<StudyTask> rows = <StudyTask>[
      ...original.where((StudyTask task) => !scheduled.containsKey(task.id)),
      ...scheduled.values,
    ];
    return _local.upsertTasks(rows.map(_taskCompanion).toList());
  }

  StudyTasksCompanion _taskCompanion(StudyTask t) {
    final int? duration = t.durationMinutes ??
        (t.startMinute != null && t.endMinute != null
            ? t.endMinute! - t.startMinute!
            : null);
    return StudyTasksCompanion.insert(
      id: t.id,
      day: t.day,
      title: t.title,
      subject: Value<String?>(t.subject),
      topic: Value<String?>(t.topic),
      notes: Value<String?>(t.notes),
      startMinute: Value<int?>(t.startMinute),
      endMinute: Value<int?>(t.endMinute),
      priority: Value<int>(t.priority.index),
      status: Value<int>(t.status.index),
      completed: Value<bool>(t.completed),
      kind: Value<String>(t.kind.key),
      durationMinutes: Value<int?>(duration),
      autoScheduled: Value<bool>(t.autoScheduled),
      orderIndex: Value<int>(t.orderIndex),
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
      completedAt: Value<DateTime?>(t.completedAt),
    );
  }

  @override
  Future<void> setTaskCompleted(String id, {required bool completed}) =>
      _local.setStatus(
          id, completed ? TaskStatus.completed.index : TaskStatus.pending.index,
          completed, DateTime.now());

  @override
  Future<void> setTaskStatus(String id, TaskStatus status) => _local.setStatus(
      id, status.index, status == TaskStatus.completed, DateTime.now());

  @override
  Future<List<String>> subjectSuggestions() => _local.subjectSuggestions();

  @override
  Future<List<String>> topicSuggestions() => _local.topicSuggestions();

  // ── Goals ───────────────────────────────────────────────────────────────────

  @override
  Stream<List<StudyGoal>> watchGoals(String day) => _local
      .watchGoals(day)
      .map((List<StudyGoalRow> r) => r.map(_toGoal).toList(growable: false));

  @override
  Future<void> saveGoal(StudyGoal g) => _local.upsertGoal(
        StudyGoalsCompanion.insert(
          id: g.id,
          day: g.day,
          title: g.title,
          type: Value<String>(g.type.key),
          targetCount: Value<int>(g.targetCount),
          currentCount: Value<int>(g.currentCount),
          unit: Value<String?>(g.unit),
          createdAt: g.createdAt,
          updatedAt: g.updatedAt,
        ),
      );

  @override
  Future<void> deleteGoal(String id) => _local.deleteGoal(id);

  @override
  Future<void> incrementGoal(String id, int delta) async {
    final StudyGoalRow? row = await _local.getGoal(id);
    if (row == null) return;
    final int next = row.currentCount + delta;
    await _local.updateGoalCount(id, next < 0 ? 0 : next, DateTime.now());
  }

  // ── Session log ─────────────────────────────────────────────────────────────

  @override
  Future<void> addSession(StudySession s) => _local.insertSession(
        StudySessionsCompanion.insert(
          id: s.id,
          day: s.day,
          startedAt: s.startedAt,
          durationMinutes: s.durationMinutes,
          kind: Value<String>(s.kind),
          createdAt: s.createdAt,
        ),
      );

  @override
  Stream<int> watchStudyMinutes(String day) => _local.watchStudyMinutes(day);

  // ── Templates ───────────────────────────────────────────────────────────────

  @override
  Stream<List<StudyTemplate>> watchTemplates() =>
      _local.watchTemplates().map((List<QueryRow> rows) => rows
          .map((QueryRow r) => StudyTemplate(
                id: r.read<String>('id'),
                name: r.read<String>('name'),
                itemCount: r.read<int>('item_count'),
                createdAt: _dt(r, 'created_at'),
                updatedAt: _dt(r, 'updated_at'),
              ))
          .toList(growable: false));

  @override
  Future<List<StudyTemplateItem>> templateItems(String templateId) async {
    final List<StudyTemplateItemRow> rows =
        await _local.templateItems(templateId);
    return rows
        .map((StudyTemplateItemRow r) => StudyTemplateItem(
              id: r.id,
              templateId: r.templateId,
              title: r.title,
              kind: SessionKind.fromKey(r.kind),
              subject: r.subject,
              topic: r.topic,
              startMinute: r.startMinute,
              endMinute: r.endMinute,
              priority: TaskPriority.fromIndex(r.priority),
              notes: r.notes,
              orderIndex: r.orderIndex,
            ))
        .toList(growable: false);
  }

  @override
  Future<void> saveTemplateFromDay(String name, String day) async {
    final List<StudyTaskRow> rows = await _local.getTasks(day);
    final DateTime now = DateTime.now();
    final String templateId = _uuid.v4();
    await _local.insertTemplate(StudyTemplatesCompanion.insert(
      id: templateId,
      name: name,
      createdAt: now,
      updatedAt: now,
    ));
    int i = 0;
    final List<StudyTemplateItemsCompanion> items = rows
        .map((StudyTaskRow r) => StudyTemplateItemsCompanion.insert(
              id: _uuid.v4(),
              templateId: templateId,
              kind: Value<String>(r.kind),
              title: r.title,
              subject: Value<String?>(r.subject),
              topic: Value<String?>(r.topic),
              startMinute: Value<int?>(r.startMinute),
              endMinute: Value<int?>(r.endMinute),
              priority: Value<int>(r.priority),
              notes: Value<String?>(r.notes),
              orderIndex: Value<int>(i++),
            ))
        .toList();
    if (items.isNotEmpty) await _local.insertTemplateItems(items);
  }

  @override
  Future<int> applyTemplateToDay(String templateId, String day) async {
    final List<StudyTemplateItemRow> items =
        await _local.templateItems(templateId);
    final DateTime now = DateTime.now();
    final List<StudyTasksCompanion> tasks = items.map((StudyTemplateItemRow i) {
      final int? duration = (i.kind == 'break' &&
              i.startMinute != null &&
              i.endMinute != null)
          ? i.endMinute! - i.startMinute!
          : null;
      return StudyTasksCompanion.insert(
        id: _uuid.v4(),
        day: day,
        title: i.title,
        subject: Value<String?>(i.subject),
        topic: Value<String?>(i.topic),
        notes: Value<String?>(i.notes),
        startMinute: Value<int?>(i.startMinute),
        endMinute: Value<int?>(i.endMinute),
        priority: Value<int>(i.priority),
        status: const Value<int>(0),
        completed: const Value<bool>(false),
        kind: Value<String>(i.kind),
        durationMinutes: Value<int?>(duration),
        orderIndex: Value<int>(i.orderIndex),
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
    if (tasks.isNotEmpty) await _local.insertTasks(tasks);
    return tasks.length;
  }

  @override
  Future<void> deleteTemplate(String id) => _local.deleteTemplate(id);

  // ── Streak & stats ──────────────────────────────────────────────────────────

  @override
  Stream<StudyStreak> watchStreak() =>
      _local.watchActiveDays().map(_streakFrom);

  @override
  Stream<StudyStats> watchStats(StudyRange range) {
    final (String start, String end) = rollingRange(range.days);
    return _local.watchStats(start, end).map((StatsAgg a) => StudyStats(
          rangeDays: range.days,
          tasksCompleted: a.tasksCompleted,
          pendingSessions: a.pendingSessions,
          goalsAchieved: a.goalsAchieved,
          vocabularyLearned: a.vocabularyLearned,
          studyMinutes: a.studyMinutes,
          breakMinutes: a.breakMinutes,
          subjectsStudied: a.subjectsStudied,
          topicsCompleted: a.topicsCompleted,
          activeDays: a.activeDays,
        ));
  }

  // ── Search & filter (v0.7.2) ────────────────────────────────────────────────

  @override
  Stream<List<StudyTask>> searchSessions(SessionFilter f) {
    final bool? completed = switch (f.status) {
      SessionStatusFilter.all => null,
      SessionStatusFilter.pending => false,
      SessionStatusFilter.completed => true,
    };
    final int? priority = switch (f.priority) {
      PriorityFilter.any => null,
      PriorityFilter.low => TaskPriority.low.index,
      PriorityFilter.medium => TaskPriority.medium.index,
      PriorityFilter.high => TaskPriority.high.index,
    };
    final (String, String)? range = f.dayRange;
    return _local
        .searchTasks(
          query: f.query,
          completed: completed,
          priority: priority,
          startDay: range?.$1,
          endDay: range?.$2,
          subject: f.subject,
          topic: f.topic,
        )
        .map((List<StudyTaskRow> r) => r.map(_toTask).toList(growable: false));
  }

  // ── Subjects & colours (v0.7.2) ─────────────────────────────────────────────

  @override
  Stream<List<StudySubject>> watchSubjects({bool includeArchived = false}) =>
      _local.watchSubjects(includeArchived).map((List<StudySubjectRow> r) =>
          r.map(_toSubject).toList(growable: false));

  @override
  Stream<Map<String, int>> watchSubjectColors() =>
      _local.watchSubjects(true).map((List<StudySubjectRow> rows) =>
          <String, int>{for (final StudySubjectRow r in rows) r.nameLower: r.color});

  @override
  Future<List<SubjectUsage>> allSubjectsWithUsage(
      {bool includeArchived = false}) async {
    final List<({String name, int count})> counts =
        await _local.sessionSubjectCounts();
    final List<StudySubjectRow> subs = await _local.allSubjects();
    final Map<String, StudySubject> colored = <String, StudySubject>{
      for (final StudySubjectRow r in subs) r.nameLower: _toSubject(r),
    };
    final Map<String, SubjectUsage> out = <String, SubjectUsage>{};
    for (final ({String name, int count}) c in counts) {
      final String nl = c.name.toLowerCase();
      final StudySubject? sub = colored[nl];
      if (sub != null && sub.archived && !includeArchived) continue;
      out[nl] = SubjectUsage(
          name: sub?.name ?? c.name, sessionCount: c.count, subject: sub);
    }
    for (final MapEntry<String, StudySubject> e in colored.entries) {
      if (out.containsKey(e.key)) continue;
      if (e.value.archived && !includeArchived) continue;
      out[e.key] =
          SubjectUsage(name: e.value.name, sessionCount: 0, subject: e.value);
    }
    final List<SubjectUsage> list = out.values.toList()
      ..sort((SubjectUsage a, SubjectUsage b) {
        if (a.hasColor != b.hasColor) return a.hasColor ? -1 : 1;
        final int byCount = b.sessionCount.compareTo(a.sessionCount);
        return byCount != 0
            ? byCount
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return list;
  }

  @override
  Future<void> saveSubject(StudySubject s) => _local.upsertSubject(
        StudySubjectsCompanion.insert(
          id: s.id,
          name: s.name,
          nameLower: s.name.toLowerCase(),
          color: s.color,
          archived: Value<bool>(s.archived),
          createdAt: s.createdAt,
          updatedAt: s.updatedAt,
        ),
      );

  @override
  Future<void> setSubjectColor(String id, int color) => _local.updateSubject(
      id, StudySubjectsCompanion(color: Value<int>(color), updatedAt: Value<DateTime>(DateTime.now())));

  @override
  Future<void> renameSubject(String id, String name) async {
    final List<StudySubjectRow> subs = await _local.allSubjects();
    String? oldLower;
    for (final StudySubjectRow r in subs) {
      if (r.id == id) {
        oldLower = r.nameLower;
        break;
      }
    }
    // Rename the label everywhere so history keeps its colour, then the row.
    await _local.bulkRenameSubject(oldLower ?? name.toLowerCase(), name);
    await _local.updateSubject(
        id,
        StudySubjectsCompanion(
          name: Value<String>(name),
          nameLower: Value<String>(name.toLowerCase()),
          updatedAt: Value<DateTime>(DateTime.now()),
        ));
  }

  @override
  Future<void> setSubjectArchived(String id, bool archived) =>
      _local.updateSubject(
          id,
          StudySubjectsCompanion(
              archived: Value<bool>(archived),
              updatedAt: Value<DateTime>(DateTime.now())));

  @override
  Future<void> deleteSubject(String id) => _local.deleteSubject(id);

  // ── Recent / frequent (v0.7.2) ──────────────────────────────────────────────

  @override
  Future<List<String>> recentSubjects({int limit = 8}) =>
      _local.recentSubjects(limit);
  @override
  Future<List<String>> frequentSubjects({int limit = 8}) =>
      _local.frequentSubjects(limit);
  @override
  Future<List<String>> recentTopics({int limit = 8}) =>
      _local.recentTopics(limit);

  // ── Backup / restore (v0.7.2) ───────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> exportBackup() async {
    return <String, dynamic>{
      'app': 'sapiora',
      'type': 'study_hub_backup',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': (await _local.allTasks())
          .map((StudyTaskRow r) => r.toJson())
          .toList(),
      'goals': (await _local.allGoals())
          .map((StudyGoalRow r) => r.toJson())
          .toList(),
      'logs': (await _local.allSessionLogs())
          .map((StudySessionRow r) => r.toJson())
          .toList(),
      'templates': (await _local.allTemplates())
          .map((StudyTemplateRow r) => r.toJson())
          .toList(),
      'templateItems': (await _local.allTemplateItems())
          .map((StudyTemplateItemRow r) => r.toJson())
          .toList(),
      'subjects': (await _local.allSubjects())
          .map((StudySubjectRow r) => r.toJson())
          .toList(),
    };
  }

  @override
  Future<void> importBackup(Map<String, dynamic> data) async {
    List<Map<String, dynamic>> rows(String key) =>
        ((data[key] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => (e as Map).cast<String, dynamic>())
            .toList();
    await _local.replaceAll(
      tasks: rows('tasks')
          .map((Map<String, dynamic> m) =>
              StudyTaskRow.fromJson(m).toCompanion(true))
          .toList(),
      goals: rows('goals')
          .map((Map<String, dynamic> m) =>
              StudyGoalRow.fromJson(m).toCompanion(true))
          .toList(),
      logs: rows('logs')
          .map((Map<String, dynamic> m) =>
              StudySessionRow.fromJson(m).toCompanion(true))
          .toList(),
      templates: rows('templates')
          .map((Map<String, dynamic> m) =>
              StudyTemplateRow.fromJson(m).toCompanion(true))
          .toList(),
      templateItems: rows('templateItems')
          .map((Map<String, dynamic> m) =>
              StudyTemplateItemRow.fromJson(m).toCompanion(true))
          .toList(),
      subjects: rows('subjects')
          .map((Map<String, dynamic> m) =>
              StudySubjectRow.fromJson(m).toCompanion(true))
          .toList(),
    );
  }

  // ── Mapping / computation ───────────────────────────────────────────────────

  StudySubject _toSubject(StudySubjectRow r) => StudySubject(
        id: r.id,
        name: r.name,
        color: r.color,
        archived: r.archived,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  static DateTime _dt(QueryRow r, String column) {
    final int seconds = r.read<int?>(column) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  StudyTask _toTask(StudyTaskRow r) => StudyTask(
        id: r.id,
        day: r.day,
        title: r.title,
        subject: r.subject,
        topic: r.topic,
        notes: r.notes,
        startMinute: r.startMinute,
        endMinute: r.endMinute,
        priority: TaskPriority.fromIndex(r.priority),
        // Old rows: completed=true but status=0 → treat as completed.
        status: r.completed
            ? TaskStatus.completed
            : TaskStatus.fromIndex(r.status),
        kind: SessionKind.fromKey(r.kind),
        durationMinutes: r.durationMinutes,
        autoScheduled: r.autoScheduled,
        orderIndex: r.orderIndex,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        completedAt: r.completedAt,
      );

  StudyGoal _toGoal(StudyGoalRow r) => StudyGoal(
        id: r.id,
        day: r.day,
        title: r.title,
        type: GoalType.fromKey(r.type),
        targetCount: r.targetCount,
        currentCount: r.currentCount,
        unit: r.unit,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  StudyStreak _streakFrom(List<String> daysDesc) {
    if (daysDesc.isEmpty) return StudyStreak.empty;
    final Set<int> days = daysDesc.map(epochDayFromKey).toSet();
    final int today = epochDay(DateTime.now());
    int? start;
    if (days.contains(today)) {
      start = today;
    } else if (days.contains(today - 1)) {
      start = today - 1;
    }
    int current = 0;
    if (start != null) {
      int e = start;
      while (days.contains(e)) {
        current++;
        e--;
      }
    }
    final List<int> sorted = days.toList()..sort();
    int best = 0;
    int run = 0;
    int? prev;
    for (final int e in sorted) {
      run = (prev != null && e == prev + 1) ? run + 1 : 1;
      if (run > best) best = run;
      prev = e;
    }
    if (current > best) best = current;
    return StudyStreak(current: current, best: best);
  }
}

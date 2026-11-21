import 'dart:async';

import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/study_hub/data/datasources/study_hub_local_data_source.dart';
import 'package:lexiora/modules/study_hub/domain/entities/session_filter.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_subject.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_template.dart';
import 'package:lexiora/modules/study_hub/domain/planning/day_planner.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/study_hub_repository.dart';
import 'package:lexiora/modules/study_hub/domain/scheduling/pomodoro_planner.dart';
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

  /// Refreshes reminders in the background. Rescheduling every notification is
  /// slow (many platform calls), so saving must not wait for it.
  void _notifyChanged() {
    final Future<void> Function()? callback = onTasksChanged;
    if (callback == null) return;
    unawaited(() async {
      try {
        await callback();
      } on Object {
        // Reminder refresh failures must never break saving.
      }
    }());
  }

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
    _notifyChanged();
  }

  @override
  Future<StudyTask> saveSessionWithBreak({
    required StudyTask session,
    required String breakId,
    int? breakMinutes,
  }) async {
    final List<StudyTask> stored =
        (await _local.getTasks(session.day)).map(_toTask).toList();
    final List<StudyTask> others = stored
        .where((StudyTask t) => t.id != session.id && t.id != breakId)
        .toList();
    final StudyTask? previous = _firstWhereOrNull(
        stored, (StudyTask t) => t.id == session.id);
    final StudyTask? oldBreak =
        _firstWhereOrNull(stored, (StudyTask t) => t.id == breakId);

    // Editing an automatic session keeps its place in the day; only a NEW
    // automatic session (or one that was manual) goes to the end of the day.
    final bool keepsPlace = session.autoScheduled &&
        previous != null &&
        previous.autoScheduled &&
        previous.startMinute != null;
    final StudyTask prepared;
    if (keepsPlace) {
      final int start = previous.startMinute!;
      final int duration = StudyScheduleService.durationOf(session);
      prepared = session.copyWith(
        startMinute: start,
        endMinute: start + duration,
        durationMinutes: duration,
      );
    } else {
      prepared = _prepareIncoming(session, others);
    }

    final String? problem = StudyScheduleService.validateSpan(
        prepared.startMinute, prepared.endMinute);
    if (problem != null) throw StudyScheduleInvalidTimeException(problem);

    final DateTime now = DateTime.now();
    StudyTask? breakTask;
    if (breakMinutes != null && breakMinutes > 0 && prepared.endMinute != null) {
      final int start = prepared.endMinute!;
      final int end = start + breakMinutes;
      final String? breakProblem = StudyScheduleService.validateSpan(start, end);
      if (breakProblem != null) {
        throw const StudyScheduleInvalidTimeException(
            'The break would run past midnight. Choose a shorter break.');
      }
      breakTask = (oldBreak ??
              StudyTask(
                id: breakId,
                day: session.day,
                title: 'Break',
                kind: SessionKind.breakTime,
                createdAt: now,
                updatedAt: now,
              ))
          .copyWith(
        startMinute: start,
        endMinute: end,
        durationMinutes: breakMinutes,
        // Anchored to this session's end so recalculation keeps it there.
        autoScheduled: false,
        updatedAt: now,
      );
    }

    final List<StudyTask> all = <StudyTask>[
      ...others,
      prepared,
      ?breakTask,
    ];
    final List<StudyTask> recalculated = StudyScheduleService.recalculate(all);
    final Set<String> mine = <String>{prepared.id, ?breakTask?.id};
    final StudyScheduleConflict? conflict = _firstWhereOrNull(
      StudyScheduleService.conflicts(recalculated),
      (StudyScheduleConflict c) =>
          mine.contains(c.item.id) || mine.contains(c.previous.id),
    );
    if (conflict != null) throw StudyScheduleOverlapException(conflict);

    await _local.applyChanges(
      upserts: recalculated.map(_taskCompanion).toList(),
      deleteIds: <String>[
        if (breakTask == null && oldBreak != null) oldBreak.id,
      ],
    );
    _notifyChanged();
    return recalculated.firstWhere((StudyTask t) => t.id == prepared.id);
  }

  @override
  Future<int> saveGeneratedPlan({
    required String day,
    required List<StudyTask> items,
  }) async {
    if (items.isEmpty) return 0;
    final List<StudyTask> stored =
        (await _local.getTasks(day)).map(_toTask).toList();
    final Set<String> mine = <String>{for (final StudyTask t in items) t.id};
    final List<StudyTask> others =
        stored.where((StudyTask t) => !mine.contains(t.id)).toList();
    final DateTime now = DateTime.now();
    final List<StudyTask> rows = <StudyTask>[
      for (final StudyTask t in items)
        t.copyWith(day: day, autoScheduled: false, updatedAt: now),
    ];
    for (final StudyTask r in rows) {
      final String? problem =
          StudyScheduleService.validateSpan(r.startMinute, r.endMinute);
      if (problem != null) throw StudyScheduleInvalidTimeException(problem);
    }
    final List<StudyTask> recalculated =
        StudyScheduleService.recalculate(<StudyTask>[...others, ...rows]);
    final StudyScheduleConflict? conflict = _firstWhereOrNull(
      StudyScheduleService.conflicts(recalculated),
      (StudyScheduleConflict c) =>
          mine.contains(c.item.id) || mine.contains(c.previous.id),
    );
    if (conflict != null) throw StudyScheduleOverlapException(conflict);
    await _local.applyChanges(
      upserts: recalculated.map(_taskCompanion).toList(),
    );
    _notifyChanged();
    return rows.length;
  }

  @override
  Future<Map<String, String>> lastStudiedDays() => _local.lastStudiedDays();

  @override
  Future<List<StudyTask>> missedSessions({
    required String today,
    required int nowMinute,
    int lookbackDays = 7,
  }) async {
    final DateTime end = DateTime.parse(today);
    final List<StudyTask> all = <StudyTask>[];
    for (int i = 0; i <= lookbackDays; i++) {
      final DateTime d = DateTime(end.year, end.month, end.day - i);
      final String key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      all.addAll((await _local.getTasks(key)).map(_toTask));
    }
    return findMissedSessions(all, today: today, nowMinute: nowMinute);
  }

  @override
  Future<int> moveSessionsToDay({
    required List<StudyTask> tasks,
    required String toDay,
  }) async {
    final List<StudyTask> movable =
        tasks.where((StudyTask t) => !t.isBreak && t.day != toDay).toList();
    if (movable.isEmpty) return 0;
    final List<StudyTask> target =
        (await _local.getTasks(toDay)).map(_toTask).toList();
    final Set<String> ids = <String>{for (final StudyTask t in movable) t.id};
    final List<StudyTask> placed = target
        .where((StudyTask t) => !ids.contains(t.id))
        .toList();
    final DateTime now = DateTime.now();
    final bool movingToToday = toDay == dayKey(now);
    final int nowMinute = now.hour * 60 + now.minute;

    for (final StudyTask t in movable) {
      final StudyTask incoming = t.copyWith(
        day: toDay,
        autoScheduled: true,
        clearTimes: true,
        durationMinutes: StudyScheduleService.durationOf(t),
        status: TaskStatus.pending,
        updatedAt: now,
      );
      placed.add(_prepareIncoming(incoming, placed));
    }

    // When moving missed work to Today, never put it back into a time that
    // has already passed. Start from the later of "now" and the end of the
    // existing timeline. Tomorrow/future dates keep the normal 9 AM behaviour.
    final List<StudyTask> recalculated = StudyScheduleService.recalculate(
      placed,
      minimumStartMinute: movingToToday ? nowMinute : null,
    );

    if (movingToToday) {
      final StudyTask? overflow = _firstWhereOrNull(
        recalculated,
        (StudyTask task) =>
            task.id.startsWith('') &&
            !task.isBreak &&
            task.id.isNotEmpty &&
            task.endMinute != null &&
            task.endMinute! > StudyScheduleService.minutesPerDay,
      );
      if (overflow != null) {
        throw const StudyScheduleInvalidTimeException(
          'There is not enough time left today for all missed sessions. '
          'Choose tomorrow or another date.',
        );
      }
    }

    await _local.applyChanges(
      upserts: recalculated.map(_taskCompanion).toList(),
    );
    _notifyChanged();
    return movable.length;
  }

  @override
  Future<List<StudyTask>> saveSessionAsBlocks({
    required StudyTask session,
    required int focusMinutes,
    required int breakMinutes,
  }) async {
    final List<StudyTask> stored =
        (await _local.getTasks(session.day)).map(_toTask).toList();
    final String prefix = '${session.id}:';
    final List<StudyTask> others = stored
        .where((StudyTask t) => t.id != session.id && !t.id.startsWith(prefix))
        .toList();
    final Map<String, StudyTask> oldBlocks = <String, StudyTask>{
      for (final StudyTask t in stored)
        if (t.id.startsWith(prefix)) t.id: t,
    };

    final int total = StudyScheduleService.durationOf(session);
    final int? start = session.autoScheduled
        ? StudyScheduleService.nextAvailableMinute(others)
        : session.startMinute;
    if (start == null) {
      throw const StudyScheduleInvalidTimeException(
          'Choose a start time for the focus blocks.');
    }
    if (focusMinutes <= 0 || breakMinutes < 0) {
      throw const StudyScheduleInvalidTimeException(
          'Focus blocks need a length of at least one minute.');
    }
    final PomodoroPlan plan = planPomodoro(
      totalFocusMinutes: total,
      focusMinutes: focusMinutes,
      breakMinutes: breakMinutes,
    );
    final String? problem =
        StudyScheduleService.validateSpan(start, start + plan.windowMinutes);
    if (problem != null) throw StudyScheduleInvalidTimeException(problem);

    final DateTime now = DateTime.now();
    int focusNo = 0, breakNo = 0;
    final List<StudyTask> rows = <StudyTask>[];
    for (final PlannedBlock block in plan.blocks) {
      final bool focus = block.kind == BlockKind.focus;
      final String id = focus ? '$prefix' 'f${++focusNo}' : '$prefix' 'b${++breakNo}';
      final StudyTask? previous = oldBlocks[id];
      final int s = start + block.offsetMinutes;
      rows.add(StudyTask(
        id: id,
        day: session.day,
        title: focus ? session.title : 'Break',
        subject: focus ? session.subject : null,
        topic: focus ? session.topic : null,
        notes: focus ? session.notes : null,
        priority: session.priority,
        status: focus ? session.status : TaskStatus.pending,
        kind: focus ? SessionKind.session : SessionKind.breakTime,
        startMinute: s,
        endMinute: s + block.minutes,
        durationMinutes: block.minutes,
        // Not automatic: the blocks keep their fixed times as one chain.
        completedAt: focus && session.status == TaskStatus.completed ? now : null,
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
      ));
    }

    final List<StudyTask> recalculated =
        StudyScheduleService.recalculate(<StudyTask>[...others, ...rows]);
    final Set<String> mine = <String>{for (final StudyTask r in rows) r.id};
    final StudyScheduleConflict? conflict = _firstWhereOrNull(
      StudyScheduleService.conflicts(recalculated),
      (StudyScheduleConflict c) =>
          mine.contains(c.item.id) || mine.contains(c.previous.id),
    );
    if (conflict != null) throw StudyScheduleOverlapException(conflict);

    await _local.applyChanges(
      upserts: recalculated.map(_taskCompanion).toList(),
      deleteIds: <String>[
        for (final String id in oldBlocks.keys)
          if (!mine.contains(id)) id,
      ],
    );
    _notifyChanged();
    return recalculated.where((StudyTask t) => mine.contains(t.id)).toList();
  }

  static T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final T item in items) {
      if (test(item)) return item;
    }
    return null;
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
    _notifyChanged();
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
  Future<void> setTaskCompleted(String id, {required bool completed}) async {
    await _local.setStatus(
      id,
      completed ? TaskStatus.completed.index : TaskStatus.pending.index,
      completed,
      DateTime.now(),
    );
    _notifyChanged();
  }

  @override
  Future<void> setTaskStatus(String id, TaskStatus status) async {
    await _local.setStatus(
      id,
      status.index,
      status == TaskStatus.completed,
      DateTime.now(),
    );
    _notifyChanged();
  }

  @override
  Future<List<String>> subjectSuggestions() => _local.subjectSuggestions();

  @override
  Future<List<String>> topicSuggestions() => _local.topicSuggestions();

  // ── Session log ─────────────────────────────────────────────────────────────

  @override
  Future<void> addSession(StudySession s) {
    if (s.durationMinutes <= 0) return Future<void>.value();
    return _local.insertSession(
      StudySessionsCompanion.insert(
        id: s.id,
        day: s.day,
        startedAt: s.startedAt,
        endedAt: Value<DateTime?>(s.endedAt),
        durationMinutes: s.durationMinutes,
        subject: Value<String?>(s.subject),
        taskId: Value<String?>(s.taskId),
        kind: Value<String>(s.kind),
        createdAt: s.createdAt,
      ),
    );
  }

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

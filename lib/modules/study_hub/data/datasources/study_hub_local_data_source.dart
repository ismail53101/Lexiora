import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';

/// Aggregated counts over a date range (raw values; the repository wraps these
/// in a [StudyStats] with the range size).
typedef StatsAgg = ({
  int tasksCompleted,
  int pendingSessions,
  int goalsAchieved,
  int vocabularyLearned,
  int studyMinutes,
  int breakMinutes,
  int subjectsStudied,
  int topicsCompleted,
  int activeDays,
});

/// All Drift queries for the Study Hub. Reads are reactive (`watch`); writes are
/// plain upserts/deletes. Only Study Hub tables are touched.
class StudyHubLocalDataSource {
  StudyHubLocalDataSource(this._db);

  final AppDatabase _db;

  // ── Planner entries (sessions + breaks) ─────────────────────────────────────

  List<OrderClauseGenerator<$StudyTasksTable>> get _plannerOrder =>
      <OrderClauseGenerator<$StudyTasksTable>>[
        (t) => OrderingTerm(expression: t.startMinute.isNull()),
        (t) => OrderingTerm(expression: t.startMinute),
        (t) => OrderingTerm(expression: t.orderIndex),
        (t) => OrderingTerm(expression: t.createdAt),
      ];

  Stream<List<StudyTaskRow>> watchTasks(String day) =>
      (_db.select(_db.studyTasks)
            ..where((t) => t.day.equals(day))
            ..orderBy(_plannerOrder))
          .watch();

  Stream<List<StudyTaskRow>> watchTasksInRange(String startDay, String endDay) =>
      (_db.select(_db.studyTasks)
            ..where((t) => t.day.isBetweenValues(startDay, endDay))
            ..orderBy(<OrderClauseGenerator<$StudyTasksTable>>[
              (t) => OrderingTerm(expression: t.day),
              (t) => OrderingTerm(expression: t.startMinute.isNull()),
              (t) => OrderingTerm(expression: t.startMinute),
              (t) => OrderingTerm(expression: t.createdAt),
            ]))
          .watch();

  Future<List<StudyTaskRow>> getTasks(String day) =>
      (_db.select(_db.studyTasks)
            ..where((t) => t.day.equals(day))
            ..orderBy(_plannerOrder))
          .get();

  Future<void> upsertTask(StudyTasksCompanion task) =>
      _db.into(_db.studyTasks).insertOnConflictUpdate(task);

  Future<void> deleteTask(String id) =>
      (_db.delete(_db.studyTasks)..where((t) => t.id.equals(id))).go();

  Future<void> setStatus(String id, int status, bool completed, DateTime at) {
    return (_db.update(_db.studyTasks)..where((t) => t.id.equals(id))).write(
      StudyTasksCompanion(
        status: Value(status),
        completed: Value(completed),
        completedAt: Value(completed ? at : null),
        updatedAt: Value(at),
      ),
    );
  }

  Future<List<String>> subjectSuggestions() =>
      distinctValues(_db.studyTasks.subject);
  Future<List<String>> topicSuggestions() =>
      distinctValues(_db.studyTasks.topic);

  Future<List<String>> distinctValues(GeneratedColumn<String> column) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT ${column.name} AS v FROM study_tasks '
          "WHERE ${column.name} IS NOT NULL AND ${column.name} != '' "
          'ORDER BY ${column.name} COLLATE NOCASE',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.studyTasks},
        )
        .get();
    return rows.map((QueryRow r) => r.read<String>('v')).toList();
  }

  // ── Goals ───────────────────────────────────────────────────────────────────

  Stream<List<StudyGoalRow>> watchGoals(String day) =>
      (_db.select(_db.studyGoals)
            ..where((t) => t.day.equals(day))
            ..orderBy(<OrderClauseGenerator<$StudyGoalsTable>>[
              (t) => OrderingTerm(expression: t.createdAt),
            ]))
          .watch();

  Future<void> upsertGoal(StudyGoalsCompanion goal) =>
      _db.into(_db.studyGoals).insertOnConflictUpdate(goal);

  Future<void> deleteGoal(String id) =>
      (_db.delete(_db.studyGoals)..where((t) => t.id.equals(id))).go();

  Future<StudyGoalRow?> getGoal(String id) => (_db.select(_db.studyGoals)
        ..where((t) => t.id.equals(id))
        ..limit(1))
      .getSingleOrNull();

  Future<void> updateGoalCount(String id, int count, DateTime at) =>
      (_db.update(_db.studyGoals)..where((t) => t.id.equals(id))).write(
        StudyGoalsCompanion(currentCount: Value(count), updatedAt: Value(at)),
      );

  // ── Session log ─────────────────────────────────────────────────────────────

  Future<void> insertSession(StudySessionsCompanion session) =>
      _db.into(_db.studySessions).insert(session);

  Stream<int> watchStudyMinutes(String day) {
    final Expression<int> total = _db.studySessions.durationMinutes.sum();
    final query = _db.selectOnly(_db.studySessions)
      ..addColumns(<Expression<Object>>[total])
      ..where(_db.studySessions.day.equals(day));
    return query.watchSingle().map((TypedResult r) => r.read(total) ?? 0);
  }

  // ── Templates ───────────────────────────────────────────────────────────────

  Stream<List<QueryRow>> watchTemplates() {
    return _db
        .customSelect(
          'SELECT t.id, t.name, t.created_at, t.updated_at, '
          '(SELECT COUNT(*) FROM study_template_items i '
          ' WHERE i.template_id = t.id) AS item_count '
          'FROM study_templates t ORDER BY t.name COLLATE NOCASE',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.studyTemplates,
            _db.studyTemplateItems,
          },
        )
        .watch();
  }

  Future<List<StudyTemplateItemRow>> templateItems(String templateId) =>
      (_db.select(_db.studyTemplateItems)
            ..where((t) => t.templateId.equals(templateId))
            ..orderBy(<OrderClauseGenerator<$StudyTemplateItemsTable>>[
              (t) => OrderingTerm(expression: t.orderIndex),
            ]))
          .get();

  Future<void> insertTemplate(StudyTemplatesCompanion template) =>
      _db.into(_db.studyTemplates).insert(template);

  Future<void> insertTemplateItems(List<StudyTemplateItemsCompanion> items) =>
      _db.batch((Batch b) => b.insertAll(_db.studyTemplateItems, items));

  Future<void> insertTasks(List<StudyTasksCompanion> tasks) =>
      _db.batch((Batch b) => b.insertAll(_db.studyTasks, tasks));

  Future<void> deleteTemplate(String id) async {
    await (_db.delete(_db.studyTemplateItems)
          ..where((t) => t.templateId.equals(id)))
        .go();
    await (_db.delete(_db.studyTemplates)..where((t) => t.id.equals(id))).go();
  }

  // ── Streak source: distinct active days (a session OR a completed task) ──────

  Stream<List<String>> watchActiveDays() {
    return _db
        .customSelect(
          'SELECT DISTINCT day FROM ('
          '  SELECT day FROM study_sessions'
          '  UNION SELECT day FROM study_tasks '
          "  WHERE completed = 1 AND kind = 'session'"
          ') ORDER BY day DESC',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.studySessions,
            _db.studyTasks,
          },
        )
        .watch()
        .map((List<QueryRow> rows) =>
            rows.map((QueryRow r) => r.read<String>('day')).toList());
  }

  // ── Reactive aggregate statistics over [startKey, endKey] ────────────────────

  Stream<StatsAgg> watchStats(String startKey, String endKey) {
    final List<Variable<Object>> vars = <Variable<Object>>[
      for (int i = 0; i < 10; i++) ...<Variable<Object>>[
        Variable.withString(startKey),
        Variable.withString(endKey),
      ],
    ];
    return _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM study_tasks WHERE completed = 1 '
          " AND kind = 'session' AND day BETWEEN ? AND ?) AS tasks_completed, "
          '(SELECT COUNT(*) FROM study_tasks WHERE completed = 0 '
          " AND kind = 'session' AND day BETWEEN ? AND ?) AS pending_sessions, "
          '(SELECT COUNT(*) FROM study_goals '
          ' WHERE current_count >= target_count AND target_count > 0 '
          ' AND day BETWEEN ? AND ?) AS goals_achieved, '
          '(SELECT COALESCE(SUM(current_count), 0) FROM study_goals '
          " WHERE type = 'vocabulary' AND day BETWEEN ? AND ?) AS vocab_learned, "
          '(SELECT COALESCE(SUM(duration_minutes), 0) FROM study_sessions '
          ' WHERE day BETWEEN ? AND ?) AS study_minutes, '
          '(SELECT COALESCE(SUM(duration_minutes), 0) FROM study_tasks '
          " WHERE kind = 'break' AND day BETWEEN ? AND ?) AS break_minutes, "
          '(SELECT COUNT(DISTINCT COALESCE(NULLIF(subject, \'\'), title)) '
          " FROM study_tasks WHERE kind = 'session' "
          ' AND day BETWEEN ? AND ?) AS subjects_studied, '
          '(SELECT COUNT(DISTINCT topic) FROM study_tasks '
          " WHERE kind = 'session' AND completed = 1 AND topic IS NOT NULL "
          " AND topic != '' AND day BETWEEN ? AND ?) AS topics_completed, "
          '(SELECT COUNT(DISTINCT day) FROM ('
          '   SELECT day FROM study_sessions WHERE day BETWEEN ? AND ? '
          '   UNION SELECT day FROM study_tasks '
          "     WHERE completed = 1 AND kind = 'session' "
          '     AND day BETWEEN ? AND ?'
          ' )) AS active_days',
          variables: vars,
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.studyTasks,
            _db.studyGoals,
            _db.studySessions,
          },
        )
        .watchSingle()
        .map((QueryRow r) => (
              tasksCompleted: r.read<int>('tasks_completed'),
              pendingSessions: r.read<int>('pending_sessions'),
              goalsAchieved: r.read<int>('goals_achieved'),
              vocabularyLearned: r.read<int>('vocab_learned'),
              studyMinutes: r.read<int>('study_minutes'),
              breakMinutes: r.read<int>('break_minutes'),
              subjectsStudied: r.read<int>('subjects_studied'),
              topicsCompleted: r.read<int>('topics_completed'),
              activeDays: r.read<int>('active_days'),
            ));
  }

  // ── Search & filter (v0.7.2) ────────────────────────────────────────────────

  /// Dynamic, indexed session search. Text matches subject/topic/notes/title;
  /// equality filters use indexed columns. Breaks are excluded.
  Stream<List<StudyTaskRow>> searchTasks({
    String query = '',
    bool? completed,
    int? priority,
    String? startDay,
    String? endDay,
    String? subject,
    String? topic,
  }) {
    final StringBuffer sql =
        StringBuffer("SELECT * FROM study_tasks WHERE kind = 'session'");
    final List<Variable<Object>> vars = <Variable<Object>>[];
    final String q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      sql.write(" AND LOWER(COALESCE(subject,'') || ' ' || COALESCE(topic,'') "
          "|| ' ' || COALESCE(notes,'') || ' ' || title) LIKE ?");
      vars.add(Variable.withString('%$q%'));
    }
    if (completed != null) {
      sql.write(' AND completed = ?');
      vars.add(Variable.withInt(completed ? 1 : 0));
    }
    if (priority != null) {
      sql.write(' AND priority = ?');
      vars.add(Variable.withInt(priority));
    }
    if (startDay != null && endDay != null) {
      sql.write(' AND day BETWEEN ? AND ?');
      vars..add(Variable.withString(startDay))..add(Variable.withString(endDay));
    }
    if (subject != null && subject.isNotEmpty) {
      sql.write(' AND LOWER(COALESCE(subject, title)) = ?');
      vars.add(Variable.withString(subject.toLowerCase()));
    }
    if (topic != null && topic.isNotEmpty) {
      sql.write(" AND LOWER(COALESCE(topic,'')) = ?");
      vars.add(Variable.withString(topic.toLowerCase()));
    }
    sql.write(' ORDER BY day DESC, (start_minute IS NULL), start_minute, '
        'created_at LIMIT 1000');

    return _db
        .customSelect(sql.toString(),
            variables: vars,
            readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.studyTasks})
        .watch()
        .map((List<QueryRow> rows) => rows
            .map((QueryRow r) => _db.studyTasks.map(r.data))
            .toList(growable: false));
  }

  // ── Subjects (v0.7.2) ───────────────────────────────────────────────────────

  Stream<List<StudySubjectRow>> watchSubjects(bool includeArchived) {
    final query = _db.select(_db.studySubjects)
      ..orderBy(<OrderClauseGenerator<$StudySubjectsTable>>[
        (t) => OrderingTerm(expression: t.name),
      ]);
    if (!includeArchived) query.where((t) => t.archived.equals(false));
    return query.watch();
  }

  Future<List<StudySubjectRow>> allSubjects() =>
      _db.select(_db.studySubjects).get();

  Future<void> upsertSubject(StudySubjectsCompanion c) =>
      _db.into(_db.studySubjects).insertOnConflictUpdate(c);

  Future<void> updateSubject(String id, StudySubjectsCompanion c) =>
      (_db.update(_db.studySubjects)..where((t) => t.id.equals(id))).write(c);

  Future<void> deleteSubject(String id) =>
      (_db.delete(_db.studySubjects)..where((t) => t.id.equals(id))).go();

  /// Renames a subject across all sessions + template items (keeps history &
  /// colour). [oldLower] is the lowercased current name.
  Future<void> bulkRenameSubject(String oldLower, String newName) async {
    final int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.customUpdate(
      'UPDATE study_tasks SET subject = ?, updated_at = ? '
      "WHERE kind = 'session' AND LOWER(COALESCE(subject, title)) = ?",
      variables: <Variable<Object>>[
        Variable.withString(newName),
        Variable.withInt(nowSec),
        Variable.withString(oldLower),
      ],
      updates: <ResultSetImplementation<dynamic, dynamic>>{_db.studyTasks},
    );
    await _db.customUpdate(
      'UPDATE study_template_items SET subject = ? '
      "WHERE kind = 'session' AND LOWER(COALESCE(subject, title)) = ?",
      variables: <Variable<Object>>[
        Variable.withString(newName),
        Variable.withString(oldLower),
      ],
      updates: <ResultSetImplementation<dynamic, dynamic>>{_db.studyTemplateItems},
    );
  }

  /// Distinct session subjects with usage counts (display name = latest casing).
  Future<List<({String name, int count})>> sessionSubjectCounts() async {
    final rows = await _db
        .customSelect(
          'SELECT COALESCE(subject, title) AS name, COUNT(*) AS cnt '
          "FROM study_tasks WHERE kind = 'session' "
          "AND COALESCE(subject, title) != '' "
          'GROUP BY LOWER(COALESCE(subject, title)) ORDER BY cnt DESC',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.studyTasks},
        )
        .get();
    return rows
        .map((QueryRow r) => (name: r.read<String>('name'), count: r.read<int>('cnt')))
        .toList();
  }

  // ── Recent / frequent (v0.7.2) ──────────────────────────────────────────────

  Future<List<String>> _distinctByExpr(String selectExpr, String orderExpr,
      int limit) async {
    final rows = await _db
        .customSelect(
          'SELECT $selectExpr AS v, $orderExpr AS o FROM study_tasks '
          "WHERE kind = 'session' AND $selectExpr IS NOT NULL AND $selectExpr != '' "
          'GROUP BY LOWER($selectExpr) ORDER BY o DESC LIMIT $limit',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.studyTasks},
        )
        .get();
    return rows.map((QueryRow r) => r.read<String>('v')).toList();
  }

  Future<List<String>> recentSubjects(int limit) =>
      _distinctByExpr('COALESCE(subject, title)', 'MAX(created_at)', limit);
  Future<List<String>> frequentSubjects(int limit) =>
      _distinctByExpr('COALESCE(subject, title)', 'COUNT(*)', limit);
  Future<List<String>> recentTopics(int limit) =>
      _distinctByExpr('topic', 'MAX(created_at)', limit);

  // ── Backup / restore (v0.7.2) ───────────────────────────────────────────────

  Future<List<StudyTaskRow>> allTasks() => _db.select(_db.studyTasks).get();
  Future<List<StudyGoalRow>> allGoals() => _db.select(_db.studyGoals).get();
  Future<List<StudySessionRow>> allSessionLogs() =>
      _db.select(_db.studySessions).get();
  Future<List<StudyTemplateRow>> allTemplates() =>
      _db.select(_db.studyTemplates).get();
  Future<List<StudyTemplateItemRow>> allTemplateItems() =>
      _db.select(_db.studyTemplateItems).get();

  /// Wipes and replaces all Study Hub data in one transaction (restore).
  Future<void> replaceAll({
    required List<StudyTasksCompanion> tasks,
    required List<StudyGoalsCompanion> goals,
    required List<StudySessionsCompanion> logs,
    required List<StudyTemplatesCompanion> templates,
    required List<StudyTemplateItemsCompanion> templateItems,
    required List<StudySubjectsCompanion> subjects,
  }) async {
    await _db.transaction(() async {
      await _db.delete(_db.studyTasks).go();
      await _db.delete(_db.studyGoals).go();
      await _db.delete(_db.studySessions).go();
      await _db.delete(_db.studyTemplateItems).go();
      await _db.delete(_db.studyTemplates).go();
      await _db.delete(_db.studySubjects).go();
      await _db.batch((Batch b) {
        b.insertAll(_db.studyTasks, tasks);
        b.insertAll(_db.studyGoals, goals);
        b.insertAll(_db.studySessions, logs);
        b.insertAll(_db.studyTemplates, templates);
        b.insertAll(_db.studyTemplateItems, templateItems);
        b.insertAll(_db.studySubjects, subjects);
      });
    });
  }
}

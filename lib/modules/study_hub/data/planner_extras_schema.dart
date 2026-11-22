import 'package:lexiora/core/database/raw_sql.dart';

/// Extra Study Planner tables (exams and syllabus), created with plain SQL so
/// the generated `app_database.g.dart` does not need regenerating. They sit
/// next to the existing study tables, which are left untouched.
class PlannerExtrasSchema {
  const PlannerExtrasSchema._();

  /// Idempotent DDL, run every time the database opens.
  static const List<String> ddl = <String>[
    '''
CREATE TABLE IF NOT EXISTS sp_exams (
  id TEXT NOT NULL PRIMARY KEY,
  subject TEXT NOT NULL,
  title TEXT NOT NULL,
  exam_date TEXT NOT NULL,
  notes TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''',
    'CREATE INDEX IF NOT EXISTS idx_sp_exams_date ON sp_exams (exam_date)',
    '''
CREATE TABLE IF NOT EXISTS sp_topics (
  id TEXT NOT NULL PRIMARY KEY,
  subject TEXT NOT NULL,
  subject_key TEXT NOT NULL,
  title TEXT NOT NULL,
  title_key TEXT NOT NULL,
  done INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0,
  completed_at INTEGER,
  created_at INTEGER NOT NULL
)''',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_sp_topics_unique '
        'ON sp_topics (subject_key, title_key)',
    '''
CREATE TABLE IF NOT EXISTS sp_series (
  id TEXT NOT NULL PRIMARY KEY,
  subject TEXT NOT NULL,
  topic TEXT,
  notes TEXT,
  weekdays INTEGER NOT NULL,
  start_minute INTEGER NOT NULL,
  duration_minutes INTEGER NOT NULL,
  break_minutes INTEGER NOT NULL DEFAULT 0,
  priority INTEGER NOT NULL DEFAULT 1,
  start_day TEXT NOT NULL,
  until_day TEXT NOT NULL,
  created_at INTEGER NOT NULL
)''',
    '''
CREATE TABLE IF NOT EXISTS sp_series_tasks (
  task_id TEXT NOT NULL PRIMARY KEY,
  break_id TEXT,
  series_id TEXT NOT NULL,
  day TEXT NOT NULL
)''',
    'CREATE INDEX IF NOT EXISTS idx_sp_series_tasks_series '
        'ON sp_series_tasks (series_id)',
  ];

  static Future<void> ensure(RawSql db) async {
    for (final String sql in ddl) {
      await db.execute(sql);
    }
  }
}

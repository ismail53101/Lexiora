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
  ];

  static Future<void> ensure(RawSql db) async {
    for (final String sql in ddl) {
      await db.execute(sql);
    }
  }
}

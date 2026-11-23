import 'package:lexiora/core/database/raw_sql.dart';
import 'package:lexiora/modules/study_hub/domain/report/weekly_report.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/report_repository.dart';

/// Reads the existing `study_sessions` (timer logs) and `study_tasks`
/// (planned sessions) tables. Never writes.
class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._sql);

  final RawSql _sql;

  static int _i(SqlRow r, String k) => (r[k] as num?)?.toInt() ?? 0;
  static int? _iN(SqlRow r, String k) => (r[k] as num?)?.toInt();

  @override
  Future<ReportSource> load({required String startDay, required String endDay}) async {
    final List<SqlRow> logRows = await _sql.select(
      'SELECT day, subject, duration_minutes, started_at, task_id '
      'FROM study_sessions WHERE day BETWEEN ? AND ?',
      <Object?>[startDay, endDay],
    );
    final List<SqlRow> taskRows = await _sql.select(
      "SELECT id, day, COALESCE(NULLIF(TRIM(subject), ''), title) AS subj, "
      'start_minute, end_minute, duration_minutes, completed '
      "FROM study_tasks WHERE kind = 'session' AND day BETWEEN ? AND ?",
      <Object?>[startDay, endDay],
    );

    return ReportSource(
      logs: <TimerLog>[
        for (final SqlRow r in logRows)
          TimerLog(
            day: r['day']! as String,
            minutes: _i(r, 'duration_minutes'),
            subject: r['subject'] as String?,
            taskId: r['task_id'] as String?,
            startMinuteOfDay: _minuteOfDay(_iN(r, 'started_at')),
          ),
      ],
      tasks: <TaskRow>[
        for (final SqlRow r in taskRows)
          TaskRow(
            id: r['id']! as String,
            day: r['day']! as String,
            subject: (r['subj'] as String?) ?? '',
            plannedMinutes: _planned(r),
            completed: _i(r, 'completed') != 0,
            startMinuteOfDay: _iN(r, 'start_minute'),
          ),
      ],
    );
  }

  /// A stored timestamp (unix seconds) as minutes after local midnight.
  static int? _minuteOfDay(int? seconds) {
    if (seconds == null) return null;
    final DateTime t = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return t.hour * 60 + t.minute;
  }

  /// The planned length: the stored duration, else end − start, else 0.
  static int _planned(SqlRow r) {
    final int duration = _i(r, 'duration_minutes');
    if (duration > 0) return duration;
    final int? start = _iN(r, 'start_minute');
    final int? end = _iN(r, 'end_minute');
    if (start != null && end != null && end > start) return end - start;
    return 0;
  }
}

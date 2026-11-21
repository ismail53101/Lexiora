import 'package:lexiora/modules/study_hub/domain/report/weekly_report.dart';

/// Raw study data for a date range, as plain rows for the report builder.
class ReportSource {
  const ReportSource({required this.logs, required this.tasks});

  final List<TimerLog> logs;
  final List<TaskRow> tasks;
}

abstract interface class ReportRepository {
  /// Timer logs and planned sessions between [startDay] and [endDay]
  /// (inclusive, `yyyy-MM-dd`). Read-only.
  Future<ReportSource> load({required String startDay, required String endDay});
}

import 'package:equatable/equatable.dart';

/// A recorded study session (a completed Pomodoro focus block or a manual log).
class StudySession extends Equatable {
  const StudySession({
    required this.id,
    required this.day,
    required this.startedAt,
    required this.durationMinutes,
    required this.createdAt,
    this.kind = 'pomodoro',
    this.subject,
    this.taskId,
    this.endedAt,
  });

  final String id;
  final String day;
  final DateTime startedAt;
  final int durationMinutes;
  final String kind;
  final String? subject;
  final String? taskId;
  final DateTime? endedAt;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[
        id, day, startedAt, durationMinutes, kind, subject, taskId, endedAt, createdAt
      ];
}

/// The user's study streak, in consecutive active days.
class StudyStreak extends Equatable {
  const StudyStreak({required this.current, required this.best});

  final int current;
  final int best;

  static const StudyStreak empty = StudyStreak(current: 0, best: 0);

  @override
  List<Object?> get props => <Object?>[current, best];
}

/// The reporting window for the Progress Tracker / Statistics.
enum StudyRange {
  daily,
  weekly,
  monthly;

  int get days => switch (this) {
        StudyRange.daily => 1,
        StudyRange.weekly => 7,
        StudyRange.monthly => 30,
      };
  String get label => switch (this) {
        StudyRange.daily => 'Today',
        StudyRange.weekly => 'Weekly',
        StudyRange.monthly => 'Monthly',
      };
}

/// Reactive study-time totals backed by the persisted study-session log.
class StudyStatistics extends Equatable {
  const StudyStatistics({
    required this.days,
    required this.weeklyMinutes,
    required this.monthlyMinutes,
  });

  /// Seven entries ordered oldest to newest; the last entry is today.
  final List<int> days;
  final int weeklyMinutes;
  final int monthlyMinutes;

  int get yesterdayMinutes => days.length < 2 ? 0 : days[days.length - 2];
  int get todayMinutes => days.isEmpty ? 0 : days.last;

  static const StudyStatistics empty = StudyStatistics(
    days: <int>[0, 0, 0, 0, 0, 0, 0],
    weeklyMinutes: 0,
    monthlyMinutes: 0,
  );

  @override
  List<Object?> get props => <Object?>[days, weeklyMinutes, monthlyMinutes];
}

/// Aggregated study statistics over a rolling range.
class StudyStats extends Equatable {
  const StudyStats({
    required this.rangeDays,
    required this.tasksCompleted,
    required this.pendingSessions,
    required this.studyMinutes,
    required this.breakMinutes,
    required this.subjectsStudied,
    required this.topicsCompleted,
    required this.activeDays,
  });

  final int rangeDays;

  /// Completed study sessions (breaks excluded).
  final int tasksCompleted;
  final int pendingSessions;
  final int studyMinutes;
  final int breakMinutes;
  final int subjectsStudied;
  final int topicsCompleted;
  final int activeDays;

  /// Alias — "Completed sessions" in the UI.
  int get completedSessions => tasksCompleted;

  double get studyHours => studyMinutes / 60.0;

  /// Average study minutes per day across the window.
  int get avgDailyMinutes =>
      rangeDays > 0 ? (studyMinutes / rangeDays).round() : 0;

  static StudyStats empty(int rangeDays) => StudyStats(
        rangeDays: rangeDays,
        tasksCompleted: 0,
        pendingSessions: 0,
        studyMinutes: 0,
        breakMinutes: 0,
        subjectsStudied: 0,
        topicsCompleted: 0,
        activeDays: 0,
      );

  @override
  List<Object?> get props => <Object?>[
        rangeDays,
        tasksCompleted,
        pendingSessions,
        studyMinutes,
        breakMinutes,
        subjectsStudied,
        topicsCompleted,
        activeDays,
      ];
}

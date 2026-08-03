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
  });

  final String id;
  final String day;
  final DateTime startedAt;
  final int durationMinutes;
  final String kind;
  final DateTime createdAt;

  @override
  List<Object?> get props =>
      <Object?>[id, day, startedAt, durationMinutes, kind, createdAt];
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

/// Aggregated study statistics over a rolling range.
class StudyStats extends Equatable {
  const StudyStats({
    required this.rangeDays,
    required this.tasksCompleted,
    required this.pendingSessions,
    required this.goalsAchieved,
    required this.vocabularyLearned,
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
  final int goalsAchieved;
  final int vocabularyLearned;
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
        goalsAchieved: 0,
        vocabularyLearned: 0,
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
        goalsAchieved,
        vocabularyLearned,
        studyMinutes,
        breakMinutes,
        subjectsStudied,
        topicsCompleted,
        activeDays,
      ];
}

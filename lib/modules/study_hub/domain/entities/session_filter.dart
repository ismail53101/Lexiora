import 'package:equatable/equatable.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';

enum SessionStatusFilter {
  all,
  pending,
  completed;

  String get label => switch (this) {
        SessionStatusFilter.all => 'All',
        SessionStatusFilter.pending => 'Pending',
        SessionStatusFilter.completed => 'Completed',
      };
}

enum PriorityFilter {
  any,
  low,
  medium,
  high;

  String get label => switch (this) {
        PriorityFilter.any => 'Any',
        PriorityFilter.low => 'Low',
        PriorityFilter.medium => 'Medium',
        PriorityFilter.high => 'High',
      };
}

/// Date scope — also covers the "planner type" shortcuts (Daily = today,
/// Weekly = this week, Monthly = this month).
enum DateScope {
  all,
  today,
  tomorrow,
  thisWeek,
  thisMonth,
  custom;

  String get label => switch (this) {
        DateScope.all => 'All dates',
        DateScope.today => 'Today',
        DateScope.tomorrow => 'Tomorrow',
        DateScope.thisWeek => 'This week',
        DateScope.thisMonth => 'This month',
        DateScope.custom => 'Custom range',
      };
}

/// A composable filter for study-session search. All fields combine (AND).
class SessionFilter extends Equatable {
  const SessionFilter({
    this.query = '',
    this.status = SessionStatusFilter.all,
    this.priority = PriorityFilter.any,
    this.dateScope = DateScope.all,
    this.subject,
    this.topic,
    this.customStart,
    this.customEnd,
  });

  final String query;
  final SessionStatusFilter status;
  final PriorityFilter priority;
  final DateScope dateScope;
  final String? subject;
  final String? topic;
  final DateTime? customStart;
  final DateTime? customEnd;

  bool get hasActiveFilters =>
      status != SessionStatusFilter.all ||
      priority != PriorityFilter.any ||
      dateScope != DateScope.all ||
      (subject != null && subject!.isNotEmpty) ||
      (topic != null && topic!.isNotEmpty);

  /// Inclusive (startKey, endKey) for the current scope, or null for "all".
  (String, String)? get dayRange {
    final DateTime now = DateTime.now();
    switch (dateScope) {
      case DateScope.all:
        return null;
      case DateScope.today:
        return (todayKey(), todayKey());
      case DateScope.tomorrow:
        final String k = dayKey(now.add(const Duration(days: 1)));
        return (k, k);
      case DateScope.thisWeek:
        final DateTime start =
            DateTime(now.year, now.month, now.day)
                .subtract(Duration(days: now.weekday - 1));
        return (dayKey(start), dayKey(start.add(const Duration(days: 6))));
      case DateScope.thisMonth:
        final DateTime start = DateTime(now.year, now.month);
        final DateTime end = DateTime(now.year, now.month + 1, 0);
        return (dayKey(start), dayKey(end));
      case DateScope.custom:
        if (customStart == null || customEnd == null) return null;
        final DateTime a =
            customStart!.isBefore(customEnd!) ? customStart! : customEnd!;
        final DateTime b =
            customStart!.isBefore(customEnd!) ? customEnd! : customStart!;
        return (dayKey(a), dayKey(b));
    }
  }

  SessionFilter copyWith({
    String? query,
    SessionStatusFilter? status,
    PriorityFilter? priority,
    DateScope? dateScope,
    String? subject,
    String? topic,
    DateTime? customStart,
    DateTime? customEnd,
    bool clearSubject = false,
    bool clearTopic = false,
  }) =>
      SessionFilter(
        query: query ?? this.query,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        dateScope: dateScope ?? this.dateScope,
        subject: clearSubject ? null : (subject ?? this.subject),
        topic: clearTopic ? null : (topic ?? this.topic),
        customStart: customStart ?? this.customStart,
        customEnd: customEnd ?? this.customEnd,
      );

  @override
  List<Object?> get props => <Object?>[
        query,
        status,
        priority,
        dateScope,
        subject,
        topic,
        customStart,
        customEnd,
      ];
}

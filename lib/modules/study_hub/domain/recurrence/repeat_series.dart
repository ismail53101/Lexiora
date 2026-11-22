/// A repeating study session ("every Mon and Wed, 6–7 PM, until 30 May").
/// Each occurrence is an ordinary planner session; the series only links them
/// so they can be extended or ended together.
class RepeatSeries {
  const RepeatSeries({
    required this.id,
    required this.subject,
    required this.weekdays,
    required this.startMinute,
    required this.durationMinutes,
    required this.startDay,
    required this.untilDay,
    this.topic,
    this.notes,
    this.breakMinutes = 0,
    this.priorityIndex = 1,
    this.upcoming = 0,
    this.nextDay,
  });

  final String id;
  final String subject;
  final String? topic;
  final String? notes;
  final Set<int> weekdays;
  final int startMinute;
  final int durationMinutes;
  final int breakMinutes;
  final int priorityIndex;
  final String startDay;
  final String untilDay;

  /// Occurrences from today onwards.
  final int upcoming;

  /// The next occurrence that is not done yet.
  final String? nextDay;

  int get endMinute => startMinute + durationMinutes;
  bool get isFinished => upcoming == 0;
}

/// What happened when a series was created or extended.
class RepeatSaveResult {
  const RepeatSaveResult({
    required this.seriesId,
    required this.created,
    required this.skippedDays,
  });

  final String seriesId;

  /// Sessions added.
  final int created;

  /// Days left out because the time was already taken (`yyyy-MM-dd`).
  final List<String> skippedDays;
}

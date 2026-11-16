import 'package:lexiora/modules/flashcards/domain/logic/fc_time.dart';

/// Pure aggregations over review history. Inputs come from SQL group-bys.

/// One cell of the activity heatmap.
class HeatCell {
  const HeatCell({required this.day, required this.count, required this.level});

  final DateTime day;
  final int count;

  /// 0 (no reviews) .. 4 (busiest).
  final int level;
}

/// Consecutive study days ending today. A streak is still alive if you have
/// not studied *yet* today but did yesterday.
int currentStreak(Set<String> studiedDays, DateTime now) {
  DateTime cursor = DateTime(now.year, now.month, now.day);
  if (!studiedDays.contains(dayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  int streak = 0;
  while (studiedDays.contains(dayKey(cursor))) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return streak;
}

int longestStreak(Set<String> studiedDays) {
  final List<DateTime> days = <DateTime>[
    for (final String k in studiedDays) ?parseDayKey(k),
  ]..sort();
  int best = 0, run = 0;
  DateTime? prev;
  for (final DateTime d in days) {
    run = (prev != null && daysBetween(prev, d) == 1) ? run + 1 : 1;
    if (run > best) best = run;
    prev = d;
  }
  return best;
}

/// A [weeks]-column grid (Monday first) ending with the week of [today].
/// Cells after [today] are null.
List<List<HeatCell?>> buildHeatmap(
  Map<String, int> countsByDay,
  DateTime today, {
  int weeks = 20,
}) {
  final DateTime t = DateTime(today.year, today.month, today.day);
  final DateTime thisMonday = DateTime(t.year, t.month, t.day - (t.weekday - 1));
  final DateTime first =
      DateTime(thisMonday.year, thisMonday.month, thisMonday.day - 7 * (weeks - 1));
  int maxCount = 0;
  for (final int c in countsByDay.values) {
    if (c > maxCount) maxCount = c;
  }
  int levelOf(int c) {
    if (c <= 0 || maxCount == 0) return 0;
    final double r = c / maxCount;
    if (r > 0.75) return 4;
    if (r > 0.5) return 3;
    if (r > 0.25) return 2;
    return 1;
  }

  return <List<HeatCell?>>[
    for (int w = 0; w < weeks; w++)
      <HeatCell?>[
        for (int d = 0; d < 7; d++)
          () {
            final DateTime day = DateTime(first.year, first.month, first.day + w * 7 + d);
            if (day.isAfter(t)) return null;
            final int c = countsByDay[dayKey(day)] ?? 0;
            return HeatCell(day: day, count: c, level: levelOf(c));
          }(),
      ],
  ];
}

/// Number of reviews due on each of the next [days] study days.
/// Overdue cards are counted on day 0.
List<int> buildForecast(List<DateTime> dueDates, DateTime now, {int days = 30}) {
  final List<int> out = List<int>.filled(days, 0);
  final DateTime today = studyDayStart(now);
  for (final DateTime due in dueDates) {
    int offset = daysBetween(today, studyDayStart(due));
    if (offset < 0) offset = 0;
    if (offset < days) out[offset]++;
  }
  return out;
}

/// Percentage 0..100; 0 when [total] is 0.
double percent(int part, int total) => total <= 0 ? 0 : part * 100 / total;

/// Pure date helpers for the Study Hub. Days are keyed as `YYYY-MM-DD` in the
/// device's local time so per-day and per-range queries are simple string
/// comparisons.
library;

String _p2(int n) => n.toString().padLeft(2, '0');
String _p4(int n) => n.toString().padLeft(4, '0');

/// `YYYY-MM-DD` for [d] (local date).
String dayKey(DateTime d) => '${_p4(d.year)}-${_p2(d.month)}-${_p2(d.day)}';

/// Today's key (local).
String todayKey() => dayKey(DateTime.now());

/// Parses a `YYYY-MM-DD` key back to a local [DateTime] at midnight.
DateTime parseDayKey(String key) {
  final List<String> parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// A DST-safe day number (days since the Unix epoch) for a `YYYY-MM-DD` key.
int epochDayFromKey(String key) {
  final List<String> p = key.split('-');
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]))
          .millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

/// DST-safe day number for a [DateTime].
int epochDay(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// Inclusive (startKey, endKey) for a rolling window of [days] ending today.
(String, String) rollingRange(int days) {
  final DateTime today = DateTime.now();
  final DateTime start = today.subtract(Duration(days: days - 1));
  return (dayKey(start), dayKey(today));
}

/// Formats minutes-from-midnight (0–1439) as `h:mm AM/PM`; null → empty.
String formatMinuteOfDay(int? minute) {
  if (minute == null) return '';
  final int h24 = (minute ~/ 60) % 24;
  final int m = minute % 60;
  final String period = h24 < 12 ? 'AM' : 'PM';
  final int h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:${_p2(m)} $period';
}

/// Formats a count of minutes as `Xh Ym` (or `Ym`).
String formatDuration(int minutes) {
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  if (h <= 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

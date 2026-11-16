/// Time helpers for the flashcards engine.
///
/// The "study day" rolls over at 04:00 local time (like Anki) so late-night
/// sessions still count towards the day you started them, and review cards
/// come due at the start of their due day rather than at a random hour.
library;

const int studyDayStartHour = 4;

String _p2(int n) => n.toString().padLeft(2, '0');

/// `yyyy-MM-dd` for the calendar date of [d] (no rollover shift).
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_p2(d.month)}-${_p2(d.day)}';

/// The study day [t] belongs to, as `yyyy-MM-dd`.
String studyDayKey(DateTime t) =>
    dayKey(t.subtract(const Duration(hours: studyDayStartHour)));

/// 04:00 on the study day that [t] belongs to.
DateTime studyDayStart(DateTime t) {
  final DateTime s = t.subtract(const Duration(hours: studyDayStartHour));
  return DateTime(s.year, s.month, s.day, studyDayStartHour);
}

/// Parses `yyyy-MM-dd` into a local midnight; null when malformed.
DateTime? parseDayKey(String key) {
  final List<String> p = key.split('-');
  if (p.length != 3) return null;
  final int? y = int.tryParse(p[0]);
  final int? m = int.tryParse(p[1]);
  final int? d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

int toUnix(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

DateTime fromUnix(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

/// Whole calendar days from [from] to [to] (negative when [to] is earlier).
int daysBetween(DateTime from, DateTime to) {
  final DateTime a = DateTime.utc(from.year, from.month, from.day);
  final DateTime b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// Compact human interval: `<1m`, `10m`, `3h`, `4d`, `2.5mo`, `1.3y`.
String formatInterval(Duration d) {
  final int mins = d.inMinutes;
  if (mins < 1) return '<1m';
  if (mins < 60) return '${mins}m';
  final int hours = d.inHours;
  if (hours < 24) return '${hours}h';
  final int days = d.inDays;
  if (days < 30) return '${days}d';
  if (days < 365) return '${_trim(days / 30)}mo';
  return '${_trim(days / 365)}y';
}

String _trim(double v) {
  final String s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

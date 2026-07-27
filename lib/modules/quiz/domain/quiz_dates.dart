/// Local date helpers for the Quiz Engine (kept independent of other modules).
library;

String _p2(int n) => n.toString().padLeft(2, '0');

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_p2(d.month)}-${_p2(d.day)}';

String todayKey() => dayKey(DateTime.now());

/// Monday-of-this-week key.
String weekStartKey() {
  final DateTime now = DateTime.now();
  final DateTime start = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  return dayKey(start);
}

/// First-of-this-month key.
String monthStartKey() {
  final DateTime now = DateTime.now();
  return dayKey(DateTime(now.year, now.month));
}

int nowUnixSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

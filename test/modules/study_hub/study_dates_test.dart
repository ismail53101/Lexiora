import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';

void main() {
  test('dayKey formats a local date as YYYY-MM-DD', () {
    expect(dayKey(DateTime(2026, 7, 5)), '2026-07-05');
    expect(dayKey(DateTime(2026, 12, 31)), '2026-12-31');
  });

  test('epochDayFromKey gives consecutive integers for consecutive days', () {
    final int a = epochDayFromKey('2026-07-05');
    final int b = epochDayFromKey('2026-07-06');
    expect(b - a, 1);
  });

  test('rollingRange ends today and spans the requested days', () {
    final (String start, String end) = rollingRange(7);
    expect(end, todayKey());
    expect(epochDayFromKey(end) - epochDayFromKey(start), 6);
  });

  test('formatMinuteOfDay renders 12-hour time', () {
    expect(formatMinuteOfDay(0), '12:00 AM');
    expect(formatMinuteOfDay(9 * 60 + 5), '9:05 AM');
    expect(formatMinuteOfDay(13 * 60 + 5), '1:05 PM');
    expect(formatMinuteOfDay(null), '');
  });

  test('formatDuration renders hours and minutes', () {
    expect(formatDuration(0), '0m');
    expect(formatDuration(45), '45m');
    expect(formatDuration(60), '1h');
    expect(formatDuration(90), '1h 30m');
  });
}

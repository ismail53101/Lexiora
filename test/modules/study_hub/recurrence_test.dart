import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/study_hub/domain/recurrence/recurrence.dart';

void main() {
  group('occurrenceDays', () {
    test('every Monday and Wednesday for four weeks', () {
      // 2026-03-09 is a Monday.
      final List<String> d = occurrenceDays(
        weekdays: <int>{1, 3}, startDay: '2026-03-09', untilDay: untilAfterWeeks('2026-03-09', 4),
      );
      expect(d, <String>[
        '2026-03-09', '2026-03-11', '2026-03-16', '2026-03-18',
        '2026-03-23', '2026-03-25', '2026-03-30', '2026-04-01',
      ]);
    });

    test('starts from the start day itself and ignores earlier weekdays of that week', () {
      // Starting on Wednesday: that week's Monday is NOT included.
      final List<String> d = occurrenceDays(
        weekdays: <int>{1, 3}, startDay: '2026-03-11', untilDay: '2026-03-18',
      );
      expect(d, <String>['2026-03-11', '2026-03-16', '2026-03-18']);
    });

    test('both ends are inclusive', () {
      expect(occurrenceDays(weekdays: <int>{3}, startDay: '2026-03-11', untilDay: '2026-03-11'), <String>['2026-03-11']);
      expect(occurrenceDays(weekdays: <int>{4}, startDay: '2026-03-11', untilDay: '2026-03-11'), isEmpty);
    });

    test('crosses month and year boundaries', () {
      expect(
        occurrenceDays(weekdays: <int>{1, 2, 3, 4, 5, 6, 7}, startDay: '2026-12-30', untilDay: '2027-01-02'),
        <String>['2026-12-30', '2026-12-31', '2027-01-01', '2027-01-02'],
      );
      expect(occurrenceDays(weekdays: <int>{7}, startDay: '2028-02-27', untilDay: '2028-03-06'), <String>['2028-02-27', '2028-03-05']);
    });

    test('empty or malformed input gives nothing', () {
      expect(occurrenceDays(weekdays: <int>{}, startDay: '2026-03-09', untilDay: '2026-04-09'), isEmpty);
      expect(occurrenceDays(weekdays: <int>{1}, startDay: 'nope', untilDay: '2026-04-09'), isEmpty);
      expect(occurrenceDays(weekdays: <int>{1}, startDay: '2026-04-09', untilDay: '2026-03-09'), isEmpty);
    });

    test('the number of occurrences is capped', () {
      final List<String> d = occurrenceDays(
        weekdays: <int>{1, 2, 3, 4, 5, 6, 7}, startDay: '2026-01-01', untilDay: '2030-12-31',
      );
      expect(d.length, maxSeriesOccurrences);
      expect(occurrenceDays(weekdays: <int>{1, 2, 3, 4, 5, 6, 7}, startDay: '2026-01-01', untilDay: '2030-12-31', maxOccurrences: 5), hasLength(5));
    });
  });

  test('untilAfterWeeks', () {
    expect(untilAfterWeeks('2026-03-01', 4), '2026-03-28');
    expect(untilAfterWeeks('2026-03-09', 1), '2026-03-15');
    expect(untilAfterWeeks('2026-12-28', 2), '2027-01-10');
  });

  test('describeWeekdays', () {
    expect(describeWeekdays(<int>{1, 3}), 'Mon, Wed');
    expect(describeWeekdays(<int>{3, 1}), 'Mon, Wed');
    expect(describeWeekdays(<int>{1, 2, 3, 4, 5, 6, 7}), 'Every day');
    expect(describeWeekdays(<int>{1, 2, 3, 4, 5}), 'Weekdays');
    expect(describeWeekdays(<int>{6, 7}), 'Weekends');
    expect(describeWeekdays(<int>{}), 'No days');
    expect(describeWeekdays(<int>{5}), 'Fri');
  });

  test('weekday masks round trip', () {
    expect(weekdaysToMask(<int>{1}), 1);
    expect(weekdaysToMask(<int>{1, 3}), 5);
    expect(weekdaysToMask(<int>{7}), 64);
    expect(weekdaysFromMask(5), <int>{1, 3});
    for (int mask = 0; mask < 128; mask++) {
      expect(weekdaysToMask(weekdaysFromMask(mask)), mask);
    }
    expect(weekdaysToMask(<int>{0, 8, 2}), 2);
  });
}

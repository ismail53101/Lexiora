import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/features/home/domain/services/word_of_day_service.dart';

void main() {
  test('same calendar date resolves to the same deterministic index', () {
    final DateTime first = DateTime(2026, 8, 21, 14);
    final DateTime second = DateTime(2026, 8, 21, 23, 59);

    expect(
      WordOfDayService.indexForDate(first, 4681),
      WordOfDayService.indexForDate(second, 4681),
    );
  });
}

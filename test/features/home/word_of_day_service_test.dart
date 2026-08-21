import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/features/home/domain/services/word_of_day_service.dart';

void main() {
  test('same calendar date resolves to the same Word of the Day', () async {
    final DateTime date = DateTime(2026, 8, 21, 14);
    final Map<String, dynamic>? first =
        await WordOfDayService.forDate(date);
    final Map<String, dynamic>? second =
        await WordOfDayService.forDate(DateTime(2026, 8, 21, 23, 59));

    expect(first?['word'], isNotEmpty);
    expect(second?['word'], first?['word']);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/translation/data/services/core_word_overrides.dart';
import 'package:lexiora/modules/vocabulary/data/base_forms.dart';

void main() {
  group('kCoreWordOverrides', () {
    test('every entry has meaning, part of speech, and Urdu', () {
      for (final MapEntry<String, List<String>> entry
          in kCoreWordOverrides.entries) {
        expect(entry.value.length, 3,
            reason: '${entry.key} must be [meaning, pos, urdu]');
        expect(entry.value[0].trim(), isNotEmpty);
        expect(entry.value[1].trim(), isNotEmpty);
        expect(entry.value[2].trim(), isNotEmpty);
      }
    });

    test('keys are lowercase headwords', () {
      for (final String key in kCoreWordOverrides.keys) {
        expect(key, key.toLowerCase(), reason: '$key must be lowercase');
      }
    });

    test('no duplicate keys (case-insensitive)', () {
      final Set<String> seen = <String>{};
      for (final String key in kCoreWordOverrides.keys) {
        expect(seen.add(key), isTrue, reason: '$key listed twice');
      }
    });

    test('screenshot problem words have exam-appropriate meanings', () {
      expect(kCoreWordOverrides['attention']![0],
          contains('focusing the mind'));
      expect(kCoreWordOverrides['tragedy']![0], contains('sad event'));
      expect(kCoreWordOverrides['contribute']![0], contains('cause or produce'));
    });

    test('inflected forms resolve to an override base form', () {
      // people's → people ; points → point ; meaning → mean
      for (final String form in <String>['people', 'point', 'mean']) {
        expect(kCoreWordOverrides.containsKey(form), isTrue);
      }
      expect(baseForms('people').first, 'people');
      expect(baseForms('points').contains('point'), isTrue);
      expect(baseForms('meaning').contains('mean'), isTrue);
      expect(baseForms('contributing').contains('contribute'), isTrue);
    });
  });
}

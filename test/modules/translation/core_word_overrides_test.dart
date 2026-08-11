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
      expect(kCoreWordOverrides['eventually']![0], contains('in the end'));
      expect(kCoreWordOverrides['eventually']![2], 'آخر کار');
      expect(kCoreWordOverrides['reputation']![0], contains('opinion'));
      expect(kCoreWordOverrides['reputation']![2], 'شہرت');
      expect(kCoreWordOverrides['exaggerate']![0], contains('seem larger'));
      expect(kCoreWordOverrides['exaggerate']![2], 'مبالغہ کرنا');
    });

    test('NEXA current-affairs screenshot words are pinned (wrong online translations)', () {
      // "insulated" → موصل (conductor) came from Google; "underlining" →
      // انڈر لائننگ was a transliteration; "communiqué" → بات چیت was wrong;
      // "internationalising" / "insulated" / "communiqu" showed no English
      // meaning at all. All must now resolve from the curated override layer.
      expect(kCoreWordOverrides['insulate']![0], contains('protect'));
      expect(kCoreWordOverrides['insulate']![2], 'محفوظ کرنا');
      expect(kCoreWordOverrides['underline']![0], contains('emphasize'));
      expect(kCoreWordOverrides['underline']![2], 'لکیر کھینچنا، زور دینا');
      expect(kCoreWordOverrides['wedge']![0], contains('tightly'));
      expect(kCoreWordOverrides['internationalise']![0], contains('many countries'));
      expect(kCoreWordOverrides['internationalize']![0], contains('many countries'));
      expect(kCoreWordOverrides['open-ended']![0], contains('fixed limit'));
      expect(kCoreWordOverrides['open-ended']![2], 'غیر محدود');
      expect(kCoreWordOverrides['de-escalation']![0], contains('less serious'));
      expect(kCoreWordOverrides['de-escalation']![2], 'شدت میں کمی');
      expect(kCoreWordOverrides['diplomatically']![2], 'سفارتی طور پر');
      expect(kCoreWordOverrides['communiqué']![2], 'سرکاری اعلامیہ');
      expect(kCoreWordOverrides['communiqu']![2], 'سرکاری اعلامیہ');
      // Inflected selections resolve to the pinned base forms.
      expect(baseForms('insulated').contains('insulate'), isTrue);
      expect(baseForms('underlining').contains('underline'), isTrue);
      expect(baseForms('wedged').contains('wedge'), isTrue);
      expect(baseForms('internationalising').contains('internationalise'),
          isTrue);
      expect(baseForms('internationalizing').contains('internationalize'),
          isTrue);
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

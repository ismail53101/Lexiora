import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/usage_relevance.dart';

void main() {
  group('usageContainsHeadword', () {
    test('rejects the elevate synonym sentence from the screenshot', () {
      expect(
        usageContainsHeadword(
          'elevate',
          'John was kicked upstairs when a replacement was hired',
        ),
        isFalse,
      );
    });

    test('accepts a normal inflected form of the searched word', () {
      expect(
        usageContainsHeadword(
          'elevate',
          'The company elevated her to a senior position.',
        ),
        isTrue,
      );
    });

    test('does not accept a related word that only shares a prefix', () {
      expect(
        usageContainsHeadword('elevate', 'The elevator stopped on floor three.'),
        isFalse,
      );
    });

    test('validatedUsage hides short or unrelated examples', () {
      const WordUsage unrelated = WordUsage(
        context: 'Usage',
        english: 'They got kicked upstairs last week.',
        urdu: '',
      );
      expect(validatedUsage('elevate', unrelated), isNull);
    });
  });
}

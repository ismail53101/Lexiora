import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/vocabulary/data/base_forms.dart';

void main() {
  group('baseForms', () {
    test('inflected verbs reduce to their base form', () {
      expect(baseForms('contributing'), contains('contribute'));
      expect(baseForms('contributed'), contains('contribute'));
      expect(baseForms('focused'), contains('focus'));
      expect(baseForms('running'), contains('run'));
      expect(baseForms('studied'), contains('study'));
      expect(baseForms('stopped'), contains('stop'));
    });

    test('plurals reduce to singular', () {
      expect(baseForms('books'), contains('book'));
      expect(baseForms('boxes'), contains('box'));
      expect(baseForms('contributes'), contains('contribute'));
    });

    test('adverbs reduce to adjectives', () {
      expect(baseForms('quickly'), contains('quick'));
    });

    test('the exact word is always the first candidate', () {
      expect(baseForms('attention').first, 'attention');
      expect(baseForms('policy').first, 'policy');
    });

    test('plain (uninflected) words are returned unchanged', () {
      expect(baseForms('attention'), <String>['attention']);
      expect(baseForms('policy'), <String>['policy']);
    });

    test('empty input is safe', () {
      expect(baseForms(''), isEmpty);
      expect(baseForms('  '), isEmpty);
    });
  });
}

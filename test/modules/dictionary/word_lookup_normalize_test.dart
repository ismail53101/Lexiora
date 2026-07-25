import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/dictionary/presentation/widgets/word_lookup_popup.dart';

/// Unit tests for the reader-popup word normalizer.
void main() {
  test('normalizeLookupWord lowercases and strips surrounding punctuation', () {
    expect(normalizeLookupWord('  Run, '), 'run');
    expect(normalizeLookupWord('"Apple."'), 'apple');
    expect(normalizeLookupWord('(dictionary)'), 'dictionary');
    expect(normalizeLookupWord('WORD!'), 'word');
  });

  test('normalizeLookupWord keeps internal hyphens and apostrophes', () {
    expect(normalizeLookupWord('well-being'), 'well-being');
    expect(normalizeLookupWord("don't"), "don't");
  });

  test('normalizeLookupWord yields empty for non-alphabetic tokens', () {
    expect(normalizeLookupWord('123'), '');
    expect(normalizeLookupWord('—'), '');
    expect(normalizeLookupWord(''), '');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/flashcards/domain/logic/typed_answer.dart';

void main() {
  test('normalise ignores case, punctuation and spacing', () {
    expect(normaliseAnswer('  Paris!  '), 'paris');
    expect(normaliseAnswer('Hello,   World.'), 'hello world');
  });

  test('levenshtein', () {
    expect(levenshtein('kitten', 'sitting'), 3);
    expect(levenshtein('', 'abc'), 3);
    expect(levenshtein('same', 'same'), 0);
  });

  test('exact (after normalising) is correct', () {
    expect(checkTypedAnswer('PARIS', 'Paris.'), TypedResult.correct);
    expect(checkTypedAnswer('new  york', 'New York'), TypedResult.correct);
  });

  test('small typos are close, longer words allow more', () {
    expect(checkTypedAnswer('mitochondira', 'mitochondria'), TypedResult.close);
    expect(checkTypedAnswer('colour', 'color'), TypedResult.close);
  });

  test('short answers must be exact', () {
    expect(checkTypedAnswer('cat', 'cut'), TypedResult.wrong);
  });

  test('empty and unrelated are wrong', () {
    expect(checkTypedAnswer('', 'Paris'), TypedResult.wrong);
    expect(checkTypedAnswer('London', 'Paris'), TypedResult.wrong);
  });

  test('works with Urdu text', () {
    expect(checkTypedAnswer('پاکستان', 'پاکستان'), TypedResult.correct);
    expect(checkTypedAnswer('لاہور', 'کراچی'), TypedResult.wrong);
  });
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';

/// Verifies the per-question option shuffling of the Quiz player: options are
/// re-ordered together with the correct-answer reference so the answer is not
/// predictably A, the display→original mapping is preserved for grading, and
/// the shuffle is deterministic for a given RNG (stable across rebuilds).
void main() {
  group('shuffleOptions', () {
    const List<String> options = <String>[
      'Lahore',
      'Islamabad',
      'Karachi',
      'Peshawar',
    ];

    test('correct answer mapping is preserved in every position', () {
      for (int correct = 0; correct < options.length; correct++) {
        for (int seed = 1; seed <= 12; seed++) {
          final ShuffledOptions s =
              shuffleOptions(options, correct, Random(seed));
          expect(s.options.length, options.length);
          expect(
            s.options[s.correctDisplayIndex],
            options[correct],
            reason: 'seed $seed, correct index $correct',
          );
        }
      }
    });

    test('the correct answer is NOT always A — all four positions occur', () {
      final Set<int> positions = <int>{};
      for (int seed = 1; seed <= 60; seed++) {
        final ShuffledOptions s =
            shuffleOptions(options, 0, Random(seed));
        positions.add(s.correctDisplayIndex);
      }
      expect(positions, containsAll(<int>[0, 1, 2, 3]),
          reason: 'correct answer landed in $positions across seeds');
    });

    test('display→original mapping recovers the real answer for grading', () {
      // A real question whose answer lives at original index 2 ("Karachi").
      final QuizQuestion q = QuizQuestion(
        id: 'q1',
        bankId: 'b1',
        type: QuestionType.mcqSingle,
        prompt: 'Capital of Sindh is?',
        options: options,
        answerIndex: 2,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      for (int seed = 1; seed <= 20; seed++) {
        final ShuffledOptions s =
            shuffleOptions(q.options, q.answerIndex, Random(seed));
        for (int display = 0; display < s.options.length; display++) {
          final int original = s.originalIndexOf(display);
          expect(
            q.isCorrect(QuizGivenAnswer.choice(original)),
            original == q.answerIndex,
            reason: 'seed $seed, display $display → original $original',
          );
        }
      }
    });

    test('same seed yields the same order (no reshuffle on rebuild)', () {
      final ShuffledOptions a = shuffleOptions(options, 0, Random(7));
      final ShuffledOptions b = shuffleOptions(options, 0, Random(7));
      expect(a.order, b.order);
      expect(a.options, b.options);
    });

    test('different seeds yield different orders', () {
      final ShuffledOptions a = shuffleOptions(options, 0, Random(1));
      final ShuffledOptions b = shuffleOptions(options, 0, Random(2));
      expect(a.order, isNot(equals(b.order)));
    });

    test('a null correct index never highlights anything', () {
      final ShuffledOptions s = shuffleOptions(options, null, Random(3));
      expect(s.correctDisplayIndex, -1);
    });

    test('degenerate option lists are safe (empty and two options)', () {
      final ShuffledOptions empty = shuffleOptions(<String>[], null, Random(1));
      expect(empty.options, isEmpty);
      expect(empty.correctDisplayIndex, -1);

      final ShuffledOptions tf =
          shuffleOptions(<String>['True', 'False'], 1, Random(2));
      expect(tf.options.length, 2);
      expect(tf.options[tf.correctDisplayIndex], 'False');
    });
  });
}

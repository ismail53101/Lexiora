import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';

/// Verifies the instant-feedback option states of the Quiz player. The state
/// is a pure function of (isAnswer, isSelected) — the answer index always
/// comes from the question data, never from a hardcoded position.
void main() {
  group('quizOptionStateAfterAnswer', () {
    test('CASE 1: correct answer A, user selects A → A is GREEN', () {
      expect(
        quizOptionStateAfterAnswer(isAnswer: true, isSelected: true),
        QuizOptionState.correct,
      );
      // Other options stay neutral.
      expect(
        quizOptionStateAfterAnswer(isAnswer: false, isSelected: false),
        QuizOptionState.normal,
      );
    });

    test('CASE 2: correct answer B, user selects A → A RED, B GREEN', () {
      expect(
        quizOptionStateAfterAnswer(isAnswer: false, isSelected: true),
        QuizOptionState.wrong,
      );
      expect(
        quizOptionStateAfterAnswer(isAnswer: true, isSelected: false),
        QuizOptionState.correct,
      );
    });

    test('CASE 3: correct answer C, user selects D → D RED, C GREEN', () {
      expect(
        quizOptionStateAfterAnswer(isAnswer: false, isSelected: true),
        QuizOptionState.wrong,
      );
      expect(
        quizOptionStateAfterAnswer(isAnswer: true, isSelected: false),
        QuizOptionState.correct,
      );
    });

    test('CASE 4: correct answer D, user selects D → D is GREEN', () {
      expect(
        quizOptionStateAfterAnswer(isAnswer: true, isSelected: true),
        QuizOptionState.correct,
      );
    });

    test('the actual correct option turns green even when not picked', () {
      // Picking a wrong option must still reveal the real correct answer.
      expect(
        quizOptionStateAfterAnswer(isAnswer: true, isSelected: false),
        QuizOptionState.correct,
      );
    });

    test('options the user neither picked nor correct stay neutral', () {
      expect(
        quizOptionStateAfterAnswer(isAnswer: false, isSelected: false),
        QuizOptionState.normal,
      );
    });
  });
}

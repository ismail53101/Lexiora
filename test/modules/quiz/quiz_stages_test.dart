import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/quiz/domain/quiz_stages.dart';

/// Verifies the pure stage-quiz rules: 10-question bucket math, the 50% pass
/// rule, star ratings and the unlock ladder.
void main() {
  group('quizStageCount', () {
    test('an empty pool has no stages', () {
      expect(quizStageCount(0), 0);
      expect(quizStageCount(-3), 0);
    });

    test('splits the pool into 10-question buckets (ceil)', () {
      expect(quizStageCount(10), 1);
      expect(quizStageCount(11), 2);
      expect(quizStageCount(25), 3);
      expect(quizStageCount(100), 10);
      expect(quizStageCount(1300), 130);
      expect(quizStageCount(833), 84);
    });

    test('honours a custom per-stage size', () {
      expect(quizStageCount(25, perStage: 5), 5);
      expect(quizStageCount(1, perStage: 5), 1);
    });
  });

  group('quizStageQuestionCount', () {
    test('returns the exact slice size per stage', () {
      // 25 questions → 10 + 10 + 5.
      expect(quizStageQuestionCount(25, 0), 10);
      expect(quizStageQuestionCount(25, 1), 10);
      expect(quizStageQuestionCount(25, 2), 5);
    });

    test('returns 0 for out-of-range stages', () {
      expect(quizStageQuestionCount(25, 3), 0);
      expect(quizStageQuestionCount(25, -1), 0);
      expect(quizStageQuestionCount(0, 0), 0);
    });
  });

  group('quizStagePassed', () {
    test('requires 50% of the stage', () {
      expect(quizStagePassed(4, 10), isFalse);
      expect(quizStagePassed(5, 10), isTrue);
      expect(quizStagePassed(7, 10), isTrue);
    });

    test('never passes an empty stage', () {
      expect(quizStagePassed(0, 0), isFalse);
      expect(quizStagePassed(5, 0), isFalse);
    });
  });

  group('quizStageStars', () {
    test('3 stars at 90%+, 2 at 70%+, 1 at 50%+, 0 below', () {
      expect(quizStageStars(10, 10), 3);
      expect(quizStageStars(9, 10), 3);
      expect(quizStageStars(8, 10), 2);
      expect(quizStageStars(7, 10), 2);
      expect(quizStageStars(6, 10), 1);
      expect(quizStageStars(5, 10), 1);
      expect(quizStageStars(4, 10), 0);
      expect(quizStageStars(0, 10), 0);
    });

    test('never stars an empty stage', () {
      expect(quizStageStars(0, 0), 0);
    });
  });

  group('QuizStageScope', () {
    test('keeps topic ladders isolated from subject ladders', () {
      const QuizStageScope grammar = QuizStageScope(
        subjectId: 'english',
        topicId: 'english-grammar',
      );
      const QuizStageScope subject = QuizStageScope(subjectId: 'english');

      expect(grammar.progressSubjectId, 'english::english-grammar');
      expect(subject.progressSubjectId, 'english');
      expect(grammar, isNot(subject));
    });
  });

  group('quizStageUnlocked', () {
    test('stage 1 is always unlocked', () {
      expect(quizStageUnlocked(0, const <int>{}), isTrue);
    });

    test('a stage unlocks only when the previous one is passed', () {
      expect(quizStageUnlocked(1, const <int>{}), isFalse);
      expect(quizStageUnlocked(1, const <int>{0}), isTrue);
      expect(quizStageUnlocked(2, const <int>{0}), isFalse);
      expect(quizStageUnlocked(2, const <int>{0, 1}), isTrue);
      expect(quizStageUnlocked(5, const <int>{0, 1, 2, 3}), isFalse);
      expect(quizStageUnlocked(5, const <int>{0, 1, 2, 3, 4}), isTrue);
    });

    test('earlier passes do not bypass the immediate previous stage', () {
      // Passing stage 0 but not stage 1 keeps stage 2 locked.
      expect(quizStageUnlocked(2, const <int>{0, 2}), isFalse);
    });
  });
}

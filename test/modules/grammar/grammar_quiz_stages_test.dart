import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/grammar/domain/grammar_quiz_stages.dart';

void main() {
  group('Grammar staged-quiz policy', () {
    test('only the three approved Grammar quiz sections are staged', () {
      expect(
        stagedGrammarQuizIds,
        <String>{
          'pos/quiz',
          'active-passive-voice/practice-quiz',
          'direct-indirect-speech/practice-quiz',
        },
      );
      expect(stagedGrammarQuizIds, isNot(contains('modals/can')));
      expect(stagedGrammarQuizIds, isNot(contains('modals/would')));
    });

    test('milestone gates are at stages 5, 10, 15, and onward', () {
      expect(isGrammarQuizRewardMilestone(3), isFalse); // Stage 4
      expect(isGrammarQuizRewardMilestone(4), isTrue); // Stage 5
      expect(isGrammarQuizRewardMilestone(8), isFalse); // Stage 9
      expect(isGrammarQuizRewardMilestone(9), isTrue); // Stage 10
      expect(isGrammarQuizRewardMilestone(14), isTrue); // Stage 15
      expect(isGrammarQuizRewardMilestone(31), isFalse); // Stage 32
    });

    test('Stage 1–4 unlock sequentially; Stage 5 requires its own reward', () {
      final Set<int> passed = <int>{0, 1, 2, 3};
      expect(
        isGrammarQuizStageUnlocked(
          stageIndex: 3,
          passedStages: passed,
          rewardedStages: <int>{},
        ),
        isTrue,
      );
      expect(
        canRequestGrammarQuizMilestone(
          stageIndex: 4,
          passedStages: passed,
          rewardedStages: <int>{},
        ),
        isTrue,
      );
      expect(
        isGrammarQuizStageUnlocked(
          stageIndex: 4,
          passedStages: passed,
          rewardedStages: <int>{},
        ),
        isFalse,
      );
      expect(
        isGrammarQuizStageUnlocked(
          stageIndex: 4,
          passedStages: passed,
          rewardedStages: <int>{4},
        ),
        isTrue,
      );
      expect(
        isGrammarQuizStageUnlocked(
          stageIndex: 5,
          passedStages: <int>{0, 1, 2, 3, 4},
          rewardedStages: <int>{4},
        ),
        isTrue,
      );
    });

    test('later milestones require the earlier earned milestone too', () {
      final Set<int> passed = <int>{0, 1, 2, 3, 4, 5, 6, 7, 8};
      expect(
        canRequestGrammarQuizMilestone(
          stageIndex: 9,
          passedStages: passed,
          rewardedStages: <int>{},
        ),
        isFalse,
      );
      expect(
        canRequestGrammarQuizMilestone(
          stageIndex: 9,
          passedStages: passed,
          rewardedStages: <int>{4},
        ),
        isTrue,
      );
    });

    test('a missing earlier pass keeps every subsequent stage locked', () {
      expect(
        canRequestGrammarQuizMilestone(
          stageIndex: 4,
          passedStages: <int>{0, 1, 3},
          rewardedStages: <int>{},
        ),
        isFalse,
      );
      expect(
        isGrammarQuizStageUnlocked(
          stageIndex: 5,
          passedStages: <int>{0, 1, 2, 3, 4},
          rewardedStages: <int>{},
        ),
        isFalse,
      );
    });
  });
}

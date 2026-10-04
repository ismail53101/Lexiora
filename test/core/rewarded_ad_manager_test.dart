import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';

void main() {
  test('main quiz reward milestone is exactly five completions', () {
    final RewardedAdManager manager = RewardedAdManager(
      isPremium: () async => false,
    );

    for (int i = 0; i < AdConfiguration.rewardedQuizMilestone - 1; i++) {
      expect(manager.recordMainQuizCompletion(), isFalse);
    }
    expect(manager.recordMainQuizCompletion(), isTrue);
    expect(manager.recordMainQuizCompletion(), isFalse);
  });

  test('grammar quiz reward milestone is exactly five completions', () {
    final RewardedAdManager manager = RewardedAdManager(
      isPremium: () async => false,
    );

    for (int i = 0; i < AdConfiguration.rewardedQuizMilestone - 1; i++) {
      expect(manager.recordGrammarQuizCompletion(), isFalse);
    }
    expect(manager.recordGrammarQuizCompletion(), isTrue);
    expect(manager.recordGrammarQuizCompletion(), isFalse);
  });

  test('AI free allowance remains seven requests', () {
    final RewardedAdManager manager = RewardedAdManager(
      isPremium: () async => false,
    );
    expect(manager.aiRequestsRemaining, 7);
  });
}

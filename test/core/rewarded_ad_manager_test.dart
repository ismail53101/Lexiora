import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('main quiz reward milestone is exactly five completions', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final RewardedAdManager manager = RewardedAdManager(
      isPremium: () async => false,
    );

    for (int i = 0; i < AdConfiguration.rewardedQuizMilestone; i++) {
      await manager.recordMainQuizCompletion();
    }
    expect(await manager.requiresMainQuizUnlock(6), isTrue);
    await manager.unlockMainQuiz(6);
    expect(await manager.requiresMainQuizUnlock(6), isFalse);
    expect(await manager.requiresMainQuizUnlock(7), isFalse);
  });

  test('grammar quiz reward milestone is exactly five completions', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final RewardedAdManager manager = RewardedAdManager(
      isPremium: () async => false,
    );

    for (int i = 0; i < AdConfiguration.rewardedQuizMilestone; i++) {
      await manager.recordGrammarQuizCompletion();
    }
    expect(await manager.requiresGrammarQuizUnlock(6), isTrue);
    await manager.unlockGrammarQuiz(6);
    expect(await manager.requiresGrammarQuizUnlock(6), isFalse);
    expect(await manager.requiresGrammarQuizUnlock(7), isFalse);
  });

  test('AI free allowance remains seven requests', () {
    final RewardedAdManager manager = RewardedAdManager(
      isPremium: () async => false,
    );
    expect(manager.aiRequestsRemaining, 7);
  });
}

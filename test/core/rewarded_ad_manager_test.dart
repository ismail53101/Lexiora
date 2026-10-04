import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('main quiz reward milestone is exactly five completions', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final RewardedAdManager manager = RewardedAdManager(
      isPremium: () async => false,
    );
    const String subjectId = 'pakistan_affairs';

    for (int i = 0; i < AdConfiguration.rewardedQuizMilestone; i++) {
      await manager.recordMainQuizCompletion(subjectId);
    }
    expect(await manager.requiresMainQuizUnlock(subjectId, 6), isTrue);
    await manager.unlockMainQuiz(subjectId, 6);
    expect(await manager.requiresMainQuizUnlock(subjectId, 6), isFalse);
    expect(await manager.requiresMainQuizUnlock(subjectId, 7), isFalse);
  });

  test('main quiz progress and unlocks stay isolated by subject', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final RewardedAdManager manager = RewardedAdManager(
      isPremium: () async => false,
    );
    const String pakistan = 'pakistan_affairs';
    const String islamic = 'islamic_studies';

    for (int i = 0; i < AdConfiguration.rewardedQuizMilestone; i++) {
      await manager.recordMainQuizCompletion(pakistan);
    }
    for (int i = 0; i < 2; i++) {
      await manager.recordMainQuizCompletion(islamic);
    }

    expect(await manager.requiresMainQuizUnlock(pakistan, 6), isTrue);
    expect(await manager.requiresMainQuizUnlock(islamic, 6), isFalse);
    await manager.unlockMainQuiz(pakistan, 6);
    expect(await manager.hasMainQuizUnlock(pakistan, 6), isTrue);
    expect(await manager.hasMainQuizUnlock(islamic, 6), isFalse);

    final RewardedAdManager restored = RewardedAdManager(
      isPremium: () async => false,
    );
    expect(await restored.hasMainQuizUnlock(pakistan, 6), isTrue);
    expect(await restored.hasMainQuizUnlock(islamic, 6), isFalse);
    expect(await restored.requiresMainQuizUnlock(pakistan, 11), isFalse);
    expect(await restored.requiresMainQuizUnlock(islamic, 6), isFalse);
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

  test(
    'AI allowance counts successful requests only and grants exactly seven',
    () async {
      final RewardedAdManager manager = RewardedAdManager(
        isPremium: () async => false,
      );

      expect(manager.aiRequestsRemaining, 7);
      for (int i = 0; i < 7; i++) {
        expect(await manager.canStartAiRequest(), isTrue);
        manager.recordSuccessfulAiRequest();
      }
      expect(manager.aiRequestsRemaining, 0);

      // A failed request does not call recordSuccessfulAiRequest(), so it does
      // not consume anything. The rewarded callback grants one seven-request
      // allowance, not an allowance at dialog-open or ad-start time.
      manager.grantAiRequestsAfterReward();
      expect(manager.aiRequestsRemaining, 7);
      expect(await manager.canStartAiRequest(), isTrue);
    },
  );

  test('AI free allowance starts at seven requests', () {
    final RewardedAdManager manager = RewardedAdManager(
      isPremium: () async => false,
    );
    expect(manager.aiRequestsRemaining, 7);
  });
}

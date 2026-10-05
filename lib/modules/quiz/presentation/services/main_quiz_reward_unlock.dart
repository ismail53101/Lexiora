import 'dart:async';

import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_repository.dart';

/// Injectable request signature used to keep the reward gate independently
/// testable while production delegates to [RewardedAdManager.showRewarded].
typedef MainQuizRewardedAdRequest = Future<RewardedAdResult> Function({
  required RewardedAdPlacement placement,
  required RewardCallback? onRewarded,
});

RewardedAdPlacement mainQuizRewardPlacementForSubject(String subjectId) =>
    switch (subjectId) {
      'pakistan-affairs' => RewardedAdPlacement.mainQuizPakistanAffairs,
      'islamic-studies' => RewardedAdPlacement.mainQuizIslamicStudies,
      'general-science-ability' =>
        RewardedAdPlacement.mainQuizGeneralScienceAbility,
      'english' => RewardedAdPlacement.mainQuizEnglish,
      _ => throw ArgumentError.value(
          subjectId, 'subjectId', 'Not a Main Quiz subject'),
    };

class MainQuizRewardOutcome {
  const MainQuizRewardOutcome({
    required this.adResult,
    required this.unlockPersisted,
  });

  final RewardedAdResult adResult;
  final bool unlockPersisted;
}

/// Requests one subject-scoped milestone unlock. No load/show/dismiss result
/// grants access: only the manager's official earned-reward callback invokes
/// the durable repository write.
Future<MainQuizRewardOutcome> requestMainQuizMilestoneUnlock({
  required String subjectId,
  required int stageIndex,
  required RewardedAdPlacement placement,
  required QuizRepository repository,
  required MainQuizRewardedAdRequest requestAd,
}) async {
  final Completer<bool> persisted = Completer<bool>();
  bool earnedCallbackStarted = false;

  Future<void> persistEarnedReward() async {
    if (earnedCallbackStarted) return;
    earnedCallbackStarted = true;
    try {
      final bool saved = await repository.grantMainQuizMilestoneUnlock(
        subjectId: subjectId,
        stageIndex: stageIndex,
      );
      if (!persisted.isCompleted) persisted.complete(saved);
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'Main Quiz rewarded milestone unlock could not be persisted',
        error: error,
        stackTrace: stackTrace,
      );
      if (!persisted.isCompleted) persisted.complete(false);
    }
  }

  RewardedAdResult result;
  try {
    result = await requestAd(
      placement: placement,
      onRewarded: persistEarnedReward,
    );
  } on Object catch (error, stackTrace) {
    AppLogger.e(
      'Main Quiz rewarded milestone request failed',
      error: error,
      stackTrace: stackTrace,
    );
    result = RewardedAdResult.failed;
  }

  // RewardedAdManager waits for an earned callback's work before completing
  // its result future. Await the same future here so the map can safely refresh
  // and continue only after the subject-scoped unlock is on disk.
  final bool unlockPersisted = earnedCallbackStarted
      ? await persisted.future
      : false;
  return MainQuizRewardOutcome(
    adResult: result,
    unlockPersisted: unlockPersisted,
  );
}

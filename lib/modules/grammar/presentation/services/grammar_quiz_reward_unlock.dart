import 'dart:async';

import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/modules/grammar/domain/repositories/grammar_repository.dart';

typedef GrammarRewardedAdRequest = Future<RewardedAdResult> Function({
  required RewardedAdPlacement placement,
  required RewardCallback? onRewarded,
});

class GrammarQuizRewardOutcome {
  const GrammarQuizRewardOutcome({
    required this.adResult,
    required this.unlockPersisted,
  });

  final RewardedAdResult adResult;
  final bool unlockPersisted;
}

/// Requests a durable, section-scoped Grammar milestone unlock. The repository
/// write is reachable only through the ad manager's official earned callback;
/// ad load/show/dismissal results alone never grant access.
Future<GrammarQuizRewardOutcome> requestGrammarQuizMilestoneUnlock({
  required String quizId,
  required int stageIndex,
  required GrammarRepository repository,
  required GrammarRewardedAdRequest requestAd,
}) async {
  final Completer<bool> persisted = Completer<bool>();
  bool earnedCallbackStarted = false;

  Future<void> persistEarnedReward() async {
    if (earnedCallbackStarted) return;
    earnedCallbackStarted = true;
    try {
      final bool saved = await repository.grantGrammarQuizMilestoneUnlock(
        quizId: quizId,
        stageIndex: stageIndex,
      );
      if (!persisted.isCompleted) persisted.complete(saved);
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'Grammar rewarded milestone unlock could not be persisted',
        error: error,
        stackTrace: stackTrace,
      );
      if (!persisted.isCompleted) persisted.complete(false);
    }
  }

  RewardedAdResult result;
  try {
    result = await requestAd(
      placement: RewardedAdPlacement.grammarQuiz,
      onRewarded: persistEarnedReward,
    );
  } on Object catch (error, stackTrace) {
    AppLogger.e(
      'Grammar rewarded milestone request failed',
      error: error,
      stackTrace: stackTrace,
    );
    result = RewardedAdResult.failed;
  }

  // RewardedAdManager awaits its earned callback before returning. Require both
  // that official event and a successful durable write before opening the gate.
  final bool unlockPersisted = earnedCallbackStarted
      ? await persisted.future
      : false;
  return GrammarQuizRewardOutcome(
    adResult: result,
    unlockPersisted: unlockPersisted,
  );
}

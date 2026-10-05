/// Stable Grammar quiz IDs that have a staged progression and rewarded gates.
/// Inline lesson Quiz panels are intentionally excluded.
const Set<String> stagedGrammarQuizIds = <String>{
  'pos/quiz',
  'active-passive-voice/practice-quiz',
  'direct-indirect-speech/practice-quiz',
};

/// Milestone stages are 1-based stages 5, 10, 15, ... .
/// [stageIndex] is zero-based, matching the quiz player's index.
bool isGrammarQuizRewardMilestone(int stageIndex) =>
    stageIndex >= 4 && (stageIndex + 1) % 5 == 0;

/// A stage is available only after every earlier stage has been passed and each
/// earlier milestone stage has its own persisted earned-reward unlock.
bool isGrammarQuizStageUnlocked({
  required int stageIndex,
  required Set<int> passedStages,
  required Set<int> rewardedStages,
}) {
  if (stageIndex < 0) return false;
  for (int prior = 0; prior < stageIndex; prior++) {
    if (!passedStages.contains(prior)) return false;
    if (isGrammarQuizRewardMilestone(prior) &&
        !rewardedStages.contains(prior)) {
      return false;
    }
  }
  return !isGrammarQuizRewardMilestone(stageIndex) ||
      rewardedStages.contains(stageIndex);
}

/// Whether the user has completed all prior stages and may request the reward
/// for this milestone. This does not itself grant or persist access.
bool canRequestGrammarQuizMilestone({
  required int stageIndex,
  required Set<int> passedStages,
  required Set<int> rewardedStages,
}) {
  if (!isGrammarQuizRewardMilestone(stageIndex) ||
      rewardedStages.contains(stageIndex)) {
    return false;
  }
  for (int prior = 0; prior < stageIndex; prior++) {
    if (!passedStages.contains(prior)) return false;
    if (isGrammarQuizRewardMilestone(prior) &&
        !rewardedStages.contains(prior)) {
      return false;
    }
  }
  return true;
}

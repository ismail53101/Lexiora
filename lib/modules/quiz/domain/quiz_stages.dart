/// Stage-quiz rules for the staged Quiz experience (Phase v0.11.0).
///
/// Pure, side-effect-free logic — fully unit-testable. Stages are fixed-size
/// slices of a subject's question pool (10 questions per stage by default). A
/// stage is passed at >= 50% and passing unlocks the next stage. The whole
/// feature is a thin layer over the existing question store: no new content,
/// no duplicate-prevention impact.

/// Questions per stage.
const int quizStagePerStage = 10;

/// Percentage required to pass a stage and unlock the next one.
const int quizStagePassPercent = 50;

/// Seconds allowed per question inside a stage.
const int quizStageSecondsPerQuestion = 30;

/// How many stages a subject's question pool splits into (ceil division, so a
/// trailing partial stage counts once). Returns 0 for an empty pool.
int quizStageCount(int questionCount, {int perStage = quizStagePerStage}) {
  if (questionCount <= 0 || perStage <= 0) return 0;
  return (questionCount + perStage - 1) ~/ perStage;
}

/// Number of questions in stage [stageIndex] (0-based) for a pool of
/// [questionCount] questions. The final stage may hold fewer than [perStage].
int quizStageQuestionCount(int questionCount, int stageIndex,
    {int perStage = quizStagePerStage}) {
  final int stages = quizStageCount(questionCount, perStage: perStage);
  if (stageIndex < 0 || stageIndex >= stages) return 0;
  final int remaining = questionCount - stageIndex * perStage;
  return remaining > perStage ? perStage : remaining;
}

/// Whether [correct] out of [total] passes the stage (>= 50%).
bool quizStagePassed(int correct, int total) =>
    total > 0 && correct * 100 >= total * quizStagePassPercent;

/// Star rating for a finished stage (0–3):
/// 3★ >= 90%, 2★ >= 70%, 1★ >= 50% (passing), otherwise 0★.
int quizStageStars(int correct, int total) {
  if (total <= 0 || !quizStagePassed(correct, total)) return 0;
  final double pct = correct * 100 / total;
  if (pct >= 90) return 3;
  if (pct >= 70) return 2;
  return 1;
}

/// Whether stage [stageIndex] is playable given the set of passed stage
/// indices. Stage 1 (index 0) is always unlocked; each later stage unlocks
/// only after the previous one has been passed.
bool quizStageUnlocked(int stageIndex, Set<int> passedStages) =>
    stageIndex <= 0 || passedStages.contains(stageIndex - 1);

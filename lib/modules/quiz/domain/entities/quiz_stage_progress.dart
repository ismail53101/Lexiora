import 'package:equatable/equatable.dart';

/// The user's stored best result for one stage of the staged Quiz experience
/// (Phase v0.11.0). One row per (subject, stage); unlock state is derived at
/// read time from `passed` (a stage unlocks when the previous one is passed),
/// so only the best result is persisted.
class QuizStageProgress extends Equatable {
  const QuizStageProgress({
    required this.subjectId,
    required this.stageIndex,
    required this.bestScore,
    required this.bestStars,
    required this.attempts,
    required this.passed,
    this.lastPlayedAt,
  });

  final String subjectId;

  /// 0-based stage index.
  final int stageIndex;

  /// Best percentage score (0–100) achieved on this stage.
  final int bestScore;

  /// Best star rating (0–3) achieved on this stage.
  final int bestStars;

  /// Total number of completed attempts on this stage.
  final int attempts;

  /// True once the stage was passed (>= 50%), unlocking the next one.
  final bool passed;

  final DateTime? lastPlayedAt;

  @override
  List<Object?> get props => <Object?>[
        subjectId,
        stageIndex,
        bestScore,
        bestStars,
        attempts,
        passed,
        lastPlayedAt,
      ];
}

import 'package:equatable/equatable.dart';

/// Durable progress for one stage in one of the three staged Grammar quizzes.
/// The composite identity is [quizId] + [stageIndex]; it is not shared with the
/// Main Quiz subject progress table.
class GrammarQuizStageProgress extends Equatable {
  const GrammarQuizStageProgress({
    required this.quizId,
    required this.stageIndex,
    required this.bestScore,
    required this.attempts,
    required this.passed,
    required this.rewardedUnlocked,
  });

  final String quizId;
  final int stageIndex;
  final int bestScore;
  final int attempts;
  final bool passed;
  final bool rewardedUnlocked;

  @override
  List<Object?> get props => <Object?>[
        quizId,
        stageIndex,
        bestScore,
        attempts,
        passed,
        rewardedUnlocked,
      ];
}

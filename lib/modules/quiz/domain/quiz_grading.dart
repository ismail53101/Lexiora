import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';

/// One question's outcome inside an attempt (pure input to [gradeAttempt]).
class QuestionOutcome {
  const QuestionOutcome({
    required this.question,
    required this.given,
    required this.skipped,
    this.timeMs = 0,
  });

  final QuizQuestion question;
  final QuizGivenAnswer? given;
  final bool skipped;
  final int timeMs;

  bool get isCorrect =>
      !skipped && given != null && question.isCorrect(given!);
}

/// The pure result of grading an attempt. No storage, no side effects — fully
/// unit-testable and reused by both the player and the repository.
class GradedAttempt {
  const GradedAttempt({
    required this.total,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.outcomes,
  });

  final int total;
  final int correct;
  final int wrong;
  final int skipped;
  final List<QuestionOutcome> outcomes;

  int get answered => correct + wrong;
  double get accuracy => answered == 0 ? 0 : (correct / answered) * 100;
}

/// Grades a list of outcomes into aggregate counts. A skipped question is
/// neither correct nor wrong; an answered-but-incorrect one is wrong.
GradedAttempt gradeAttempt(List<QuestionOutcome> outcomes) {
  int correct = 0;
  int wrong = 0;
  int skipped = 0;
  for (final QuestionOutcome o in outcomes) {
    if (o.skipped || o.given == null || o.given!.isEmpty) {
      skipped++;
    } else if (o.isCorrect) {
      correct++;
    } else {
      wrong++;
    }
  }
  return GradedAttempt(
    total: outcomes.length,
    correct: correct,
    wrong: wrong,
    skipped: skipped,
    outcomes: outcomes,
  );
}

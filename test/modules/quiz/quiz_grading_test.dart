import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/quiz_grading.dart';

void main() {
  final DateTime now = DateTime(2026, 7, 26);

  QuizQuestion mcq() => QuizQuestion(
        id: 'a',
        bankId: 'b',
        type: QuestionType.mcqSingle,
        prompt: 'pick B',
        options: const <String>['A', 'B', 'C'],
        answerIndex: 1,
        createdAt: now,
        updatedAt: now,
      );

  QuizQuestion blank() => QuizQuestion(
        id: 'c',
        bankId: 'b',
        type: QuestionType.fillBlank,
        prompt: 'capital',
        answerTexts: const <String>['Paris', 'paris city'],
        createdAt: now,
        updatedAt: now,
      );

  test('MCQ grading matches the correct index only', () {
    expect(mcq().isCorrect(const QuizGivenAnswer.choice(1)), isTrue);
    expect(mcq().isCorrect(const QuizGivenAnswer.choice(0)), isFalse);
  });

  test('fill-in-the-blank is case-insensitive and trims', () {
    expect(blank().isCorrect(const QuizGivenAnswer.blank('  PARIS ')), isTrue);
    expect(blank().isCorrect(const QuizGivenAnswer.blank('London')), isFalse);
  });

  test('reserved types never grade as correct', () {
    final QuizQuestion matching = QuizQuestion(
      id: 'm',
      bankId: 'b',
      type: QuestionType.matching,
      prompt: '?',
      createdAt: now,
      updatedAt: now,
    );
    expect(matching.isCorrect(const QuizGivenAnswer.choice(0)), isFalse);
  });

  test('gradeAttempt tallies correct / wrong / skipped', () {
    final GradedAttempt g = gradeAttempt(<QuestionOutcome>[
      QuestionOutcome(
          question: mcq(),
          given: const QuizGivenAnswer.choice(1),
          skipped: false), // correct
      QuestionOutcome(
          question: mcq(),
          given: const QuizGivenAnswer.choice(0),
          skipped: false), // wrong
      QuestionOutcome(
          question: blank(), given: null, skipped: true), // skipped
    ]);
    expect(g.total, 3);
    expect(g.correct, 1);
    expect(g.wrong, 1);
    expect(g.skipped, 1);
    expect(g.accuracy, 50);
  });
}

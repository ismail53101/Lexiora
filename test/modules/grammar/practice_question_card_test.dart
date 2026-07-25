import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/presentation/widgets/practice_question_card.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

  const GrammarQuestion question = GrammarQuestion(
    question: 'Which word is a verb?',
    options: <String>['apple', 'quickly', 'run', 'blue'],
    answerIndex: 2,
    explanation: 'A verb expresses an action; "run" is the action word.',
  );

  testWidgets('renders the question and all options without revealing answers',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(const PracticeQuestionCard(question: question)));

    expect(find.text('Which word is a verb?'), findsOneWidget);
    for (final String option in question.options) {
      expect(find.text(option), findsOneWidget);
    }
    expect(find.text('Correct'), findsNothing);
    expect(find.text('Not quite'), findsNothing);
    expect(find.textContaining('action word'), findsNothing);
  });

  testWidgets('tapping a wrong option reveals feedback and the explanation',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(const PracticeQuestionCard(question: question)));

    await tester.tap(find.text('apple'));
    await tester.pumpAndSettle();

    expect(find.text('Not quite'), findsOneWidget);
    expect(find.text('Correct'), findsNothing);
    expect(find.textContaining('the action word'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Try again resets, then the correct option is accepted',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(const PracticeQuestionCard(question: question)));

    await tester.tap(find.text('apple'));
    await tester.pumpAndSettle();
    expect(find.text('Not quite'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Not quite'), findsNothing);
    expect(find.text('Try again'), findsNothing);

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    expect(find.text('Correct'), findsOneWidget);
  });
}

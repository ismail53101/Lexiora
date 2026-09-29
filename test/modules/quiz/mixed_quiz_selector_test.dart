import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/mixed_quiz_selector.dart';

void main() {
  test('mixed selector interleaves categories instead of grouping them', () {
    final List<QuizQuestion> questions = <QuizQuestion>[
      for (int i = 0; i < 4; i++) _question('antonym', i),
      for (int i = 0; i < 4; i++) _question('synonym', i + 10),
      for (int i = 0; i < 4; i++) _question('grammar', i + 20),
    ];

    final List<QuizQuestion> result = MixedQuizSelector.select(
      questions,
      limit: 12,
    );
    final List<String> categories = result.map(mixedQuizCategory).toList();

    expect(categories.toSet(), hasLength(3));
    expect(
      <bool>[
        for (int i = 1; i < categories.length; i++)
          categories[i] == categories[i - 1],
      ].where((bool same) => same).length,
      lessThan(3),
    );
  });

  test('mixed selector respects the requested limit', () {
    final List<QuizQuestion> result = MixedQuizSelector.select(
      <QuizQuestion>[
        _question('antonym', 1),
        _question('synonym', 2),
      ],
      limit: 1,
    );

    expect(result, hasLength(1));
  });
}

QuizQuestion _question(String subject, int index) => QuizQuestion(
      id: '$subject-$index',
      bankId: 'bank-$subject',
      type: QuestionType.mcqSingle,
      prompt: '$subject question $index',
      options: const <String>['A', 'B'],
      answerIndex: 0,
      subject: subject,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

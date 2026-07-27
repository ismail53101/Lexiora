import 'package:flutter/material.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';

/// Reviews each answered question: your answer vs. the correct one + explanation.
class QuizReviewPage extends StatelessWidget {
  const QuizReviewPage({super.key, required this.items});

  final List<AnsweredQuestion> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review answers')),
      body: items.isEmpty
          ? const Center(child: Text('Nothing to review.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int i) =>
                  _ReviewCard(index: i, item: items[i]),
            ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.index, required this.item});
  final int index;
  final AnsweredQuestion item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final QuizQuestion q = item.question;
    final Color statusColor = item.skipped
        ? theme.colorScheme.tertiary
        : (item.isCorrect ? theme.colorScheme.primary : theme.colorScheme.error);
    final String status =
        item.skipped ? 'Skipped' : (item.isCorrect ? 'Correct' : 'Wrong');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Q${index + 1}',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(q.prompt, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            _line(theme, 'Your answer', _givenText(q, item.given),
                item.isCorrect ? theme.colorScheme.primary : theme.colorScheme.error),
            const SizedBox(height: 4),
            _line(theme, 'Correct answer', _correctText(q),
                theme.colorScheme.primary),
            if (q.explanation != null && q.explanation!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(q.explanation!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(ThemeData theme, String label, String value, Color color) {
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: <TextSpan>[
          TextSpan(
              text: '$label: ',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          TextSpan(
              text: value,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _givenText(QuizQuestion q, QuizGivenAnswer? g) {
    if (g == null || g.isEmpty) return '—';
    switch (q.type) {
      case QuestionType.mcqSingle:
      case QuestionType.multiCorrect:
        return (g.index != null && g.index! >= 0 && g.index! < q.options.length)
            ? q.options[g.index!]
            : '—';
      case QuestionType.trueFalse:
        return g.boolValue == null ? '—' : (g.boolValue! ? 'True' : 'False');
      case QuestionType.fillBlank:
        return g.text ?? '—';
      case QuestionType.matching:
        return '—';
    }
  }

  String _correctText(QuizQuestion q) {
    switch (q.type) {
      case QuestionType.mcqSingle:
      case QuestionType.multiCorrect:
        return (q.answerIndex != null &&
                q.answerIndex! >= 0 &&
                q.answerIndex! < q.options.length)
            ? q.options[q.answerIndex!]
            : '—';
      case QuestionType.trueFalse:
        return q.answerBool == null ? '—' : (q.answerBool! ? 'True' : 'False');
      case QuestionType.fillBlank:
        return q.answerTexts.join(', ');
      case QuestionType.matching:
        return '—';
    }
  }
}

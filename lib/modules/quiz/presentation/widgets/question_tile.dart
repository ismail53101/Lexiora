import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';

/// A read-only question row (questions are content — no inline editing). Tap to
/// preview the full question + answer; long-press for quick actions.
class QuestionTile extends ConsumerWidget {
  const QuestionTile({super.key, required this.question});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => _preview(context),
        onLongPress: () => _menu(context, ref),
        title: Text(question.prompt,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: <Widget>[
              QuestionTypeChip(type: question.type),
              const SizedBox(width: 8),
              if (question.subject != null)
                Flexible(
                  child: Text(question.subject!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(question.bookmarked ? Icons.star : Icons.star_border,
              color: question.bookmarked ? theme.colorScheme.tertiary : null),
          tooltip: question.bookmarked ? 'Remove bookmark' : 'Bookmark',
          onPressed: () async {
            await ref
                .read(quizRepositoryProvider)
                .setBookmarked(question.id, !question.bookmarked);
            ref.read(qRevisionProvider.notifier).bump();
          },
        ),
      ),
    );
  }

  void _preview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController controller) =>
              ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: <Widget>[
              Row(children: <Widget>[QuestionTypeChip(type: question.type)]),
              const SizedBox(height: 12),
              Text(question.prompt, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              ..._answerPreview(theme),
              if (question.explanation != null &&
                  question.explanation!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text('Explanation', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(question.explanation!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _answerPreview(ThemeData theme) {
    switch (question.type) {
      case QuestionType.mcqSingle:
      case QuestionType.multiCorrect:
        return <Widget>[
          for (int i = 0; i < question.options.length; i++)
            _optionRow(theme, question.options[i],
                correct: i == question.answerIndex ||
                    question.answerIndexes.contains(i)),
        ];
      case QuestionType.trueFalse:
        return <Widget>[
          _optionRow(theme, 'True', correct: question.answerBool == true),
          _optionRow(theme, 'False', correct: question.answerBool == false),
        ];
      case QuestionType.fillBlank:
        return <Widget>[
          Text('Accepted answers', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(question.answerTexts.join(', '),
              style: theme.textTheme.bodyMedium),
        ];
      case QuestionType.matching:
        return <Widget>[
          Text('Matching preview is not available in this version.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ];
    }
  }

  Widget _optionRow(ThemeData theme, String text, {required bool correct}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(correct ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: correct
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontWeight:
                          correct ? FontWeight.w700 : FontWeight.w400))),
        ],
      ),
    );
  }

  void _menu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(
                  question.bookmarked ? Icons.star_border : Icons.star),
              title: Text(question.bookmarked
                  ? 'Remove bookmark'
                  : 'Bookmark this question'),
              onTap: () async {
                Navigator.of(context).pop();
                await ref
                    .read(quizRepositoryProvider)
                    .setBookmarked(question.id, !question.bookmarked);
                ref.read(qRevisionProvider.notifier).bump();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete question'),
              onTap: () async {
                Navigator.of(context).pop();
                await ref
                    .read(quizRepositoryProvider)
                    .deleteQuestion(question.id);
                ref.read(qRevisionProvider.notifier).bump();
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/quiz_grading.dart';
import 'package:lexiora/modules/quiz/presentation/pages/quiz_player_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/quiz_review_page.dart';

/// The Results screen: score, breakdown, accuracy, time — with Review & Retry.
class QuizResultsPage extends StatelessWidget {
  const QuizResultsPage({
    super.key,
    required this.attempt,
    required this.outcomes,
  });

  final QuizAttempt attempt;
  final List<QuestionOutcome> outcomes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 56,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('${attempt.accuracy.toStringAsFixed(0)}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800)),
                  Text('accuracy',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: <Widget>[
              _tile(context, Icons.check_circle_outline, '${attempt.correct}',
                  'Correct', theme.colorScheme.primary),
              _tile(context, Icons.cancel_outlined, '${attempt.wrong}', 'Wrong',
                  theme.colorScheme.error),
              _tile(context, Icons.skip_next_outlined, '${attempt.skipped}',
                  'Skipped', theme.colorScheme.tertiary),
              _tile(context, Icons.help_outline, '${attempt.totalQuestions}',
                  'Total', theme.colorScheme.secondary),
              _tile(context, Icons.timer_outlined, _duration(attempt.durationMs),
                  'Time', theme.colorScheme.primary),
              _tile(context, Icons.flag_outlined, attempt.mode.label, 'Mode',
                  theme.colorScheme.secondary),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => QuizReviewPage(
                items: outcomes
                    .map((QuestionOutcome o) => AnsweredQuestion(
                          question: o.question,
                          given: o.given,
                          isCorrect: o.isCorrect,
                          skipped: o.skipped ||
                              o.given == null ||
                              o.given!.isEmpty,
                        ))
                    .toList(),
              ),
            )),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Review answers'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
              builder: (_) => QuizPlayerPage(
                  bankId: attempt.bankId, mode: attempt.mode),
            )),
            icon: const Icon(Icons.replay),
            label: const Text('Retry quiz'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String value, String label,
      Color color) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  String _duration(int ms) {
    final int totalSec = ms ~/ 1000;
    final int m = totalSec ~/ 60;
    final int s = totalSec % 60;
    return m == 0 ? '${s}s' : '${m}m ${s}s';
  }
}

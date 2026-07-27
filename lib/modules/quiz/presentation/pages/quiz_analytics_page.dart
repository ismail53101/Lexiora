import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';

/// The Analytics dashboard. Ships all-zero — it fills in as the user takes
/// quizzes (no sample data).
class QuizAnalyticsPage extends ConsumerWidget {
  const QuizAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuizStats s = ref.watch(quizStatsProvider).maybeWhen(
          data: (QuizStats v) => v,
          orElse: () => QuizStats.empty,
        );
    final List<(IconData, String, String)> tiles = <(IconData, String, String)>[
      (Icons.quiz_outlined, '${s.totalQuizzes}', 'Total quizzes'),
      (Icons.help_outline, '${s.questionsSolved}', 'Questions solved'),
      (Icons.check_circle_outline, '${s.correct}', 'Correct'),
      (Icons.cancel_outlined, '${s.wrong}', 'Wrong'),
      (Icons.percent, '${s.accuracy.toStringAsFixed(0)}%', 'Accuracy'),
      (Icons.timer_outlined, _dur(s.avgSecondsPerQuiz), 'Avg time / quiz'),
      (Icons.today_outlined, '${s.dailyQuizzes}', 'Today'),
      (Icons.view_week_outlined, '${s.weeklyQuizzes}', 'This week'),
      (Icons.calendar_month_outlined, '${s.monthlyQuizzes}', 'This month'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        children: <Widget>[
          QuizSectionCard(
            icon: Icons.insights,
            title: 'Overview',
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final int cols = c.maxWidth >= 520 ? 3 : 2;
                const double gap = 12;
                final double w = (c.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: <Widget>[
                    for (final (IconData, String, String) t in tiles)
                      SizedBox(
                          width: w,
                          child: _StatTile(icon: t.$1, value: t.$2, label: t.$3)),
                  ],
                );
              },
            ),
          ),
          QuizSectionCard(
            icon: Icons.emoji_events_outlined,
            title: 'Subjects',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _subjectLine(context, 'Strongest', s.strongestSubject,
                    Icons.trending_up),
                const SizedBox(height: 10),
                _subjectLine(context, 'Weakest', s.weakestSubject,
                    Icons.trending_down),
                if (s.strongestSubject == null && s.weakestSubject == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        'Take a few quizzes (with subjects) to see your strongest and weakest areas.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _subjectLine(BuildContext context, String label, SubjectAccuracy? sa,
      IconData icon) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text('$label: ',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Expanded(
          child: Text(
            sa == null ? '—' : '${sa.subject} (${sa.accuracy.toStringAsFixed(0)}%)',
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _dur(int seconds) {
    if (seconds <= 0) return '0s';
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return m == 0 ? '${s}s' : '${m}m ${s}s';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

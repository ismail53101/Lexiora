import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_common.dart';

class FlashcardStatsPage extends ConsumerWidget {
  const FlashcardStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FlashcardStats s = ref.watch(flashcardStatsProvider).maybeWhen(
          data: (FlashcardStats v) => v,
          orElse: () => FlashcardStats.empty,
        );
    final List<(IconData, String, String)> tiles = <(IconData, String, String)>[
      (Icons.library_books_outlined, '${s.totalDecks}', 'Total decks'),
      (Icons.style_outlined, '${s.totalCards}', 'Total cards'),
      (Icons.today_outlined, '${s.todayReviews}', "Today's reviews"),
      (Icons.task_alt, '${s.completedReviews}', 'Completed reviews'),
      (Icons.local_fire_department_outlined, '${s.difficultCards}', 'Difficult cards'),
      (Icons.favorite_border, '${s.favoriteCards}', 'Favourite cards'),
      (Icons.percent, '${s.averageAccuracy.toStringAsFixed(0)}%', 'Avg accuracy'),
      (Icons.schedule, _dur(s.studyMinutes), 'Study time'),
      (Icons.view_week_outlined, '${s.weeklyReviews}', 'Weekly reviews'),
      (Icons.calendar_month_outlined, '${s.monthlyReviews}', 'Monthly reviews'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcard Statistics')),
      body: ListView(
        children: <Widget>[
          FcSectionCard(
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
                      SizedBox(width: w, child: _StatTile(icon: t.$1, value: t.$2, label: t.$3)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _dur(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h <= 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
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

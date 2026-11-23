import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/flashcards/domain/logic/fc_time.dart';
import 'package:lexiora/modules/flashcards/domain/logic/stats_calc.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_stats_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';

/// Streak, activity heatmap, retention, upcoming reviews and card maturity.
class FlashcardsStatsPage extends ConsumerWidget {
  const FlashcardsStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FcStats> async = ref.watch(fcStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => EmptyState(icon: Icons.error_outline, title: 'Couldn’t load statistics', message: '$e'),
        data: (FcStats s) {
          if (s.totals.cards == 0) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No data yet',
              message: 'Add some cards and study them to see your progress here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: <Widget>[
              _StreakCard(s: s),
              _HeatmapCard(s: s),
              _RetentionCard(s: s),
              _ForecastCard(s: s),
              _BreakdownCard(s: s),
              _Last30Card(s: s),
              _TotalsCard(s: s),
            ],
          );
        },
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.s});
  final FcStats s;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Widget cell(IconData icon, Color color, String value, String label) => Expanded(
          child: Column(
            children: <Widget>[
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        );
    return FcSectionCard(
      child: Row(
        children: <Widget>[
          cell(Icons.local_fire_department_rounded, Colors.orange, '${s.streak}', 'day streak'),
          cell(Icons.emoji_events_outlined, Colors.amber.shade700, '${s.longestStreak}', 'longest streak'),
          cell(Icons.check_circle_outline, theme.colorScheme.fcReview, '${s.reviewsToday}', 'reviewed today'),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.s});
  final FcStats s;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    Color levelColor(int l) => l == 0 ? cs.surfaceContainerHighest : cs.primary.withValues(alpha: 0.25 + 0.2 * l);
    return FcSectionCard(
      title: 'Activity',
      icon: Icons.grid_view_rounded,
      child: LayoutBuilder(
        builder: (BuildContext c, BoxConstraints box) {
          final int weeks = s.heatmap.length;
          const double gap = 3;
          final double size = ((box.maxWidth - gap * (weeks - 1)) / weeks).clamp(6, 20).toDouble();
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: <Widget>[
                for (final List<HeatCell?> week in s.heatmap)
                  Padding(
                    padding: const EdgeInsets.only(right: gap),
                    child: Column(
                      children: <Widget>[
                        for (final HeatCell? cell in week)
                          Padding(
                            padding: const EdgeInsets.only(bottom: gap),
                            child: cell == null
                                ? SizedBox(width: size, height: size)
                                : Tooltip(
                                    message: '${cell.count} ${cell.count == 1 ? 'review' : 'reviews'} · ${dayKey(cell.day)}',
                                    child: Container(
                                      width: size,
                                      height: size,
                                      decoration: BoxDecoration(color: levelColor(cell.level), borderRadius: BorderRadius.circular(3)),
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RetentionCard extends StatelessWidget {
  const _RetentionCard({required this.s});
  final FcStats s;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool enough = s.retentionSample >= 20;
    final double v = s.retentionPercent / 100;
    return FcSectionCard(
      title: 'Retention (30 days)',
      icon: Icons.psychology_outlined,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: enough ? v : 0,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                Text(enough ? '${s.retentionPercent.round()}%' : '—',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              enough
                  ? 'You answered ${s.retentionPercent.round()}% of ${s.retentionSample} reviews correctly. Around 90% means the schedule is working well.'
                  : 'Not enough reviews yet (${s.retentionSample}/20). Keep studying and this will fill in.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple bar chart: one bar per value.
class _Bars extends StatelessWidget {
  const _Bars({required this.values, required this.color, this.labels = const <int, String>{}});
  final List<int> values;
  final Color color;
  static const double height = 90;

  /// Index → label drawn under the axis.
  final Map<int, String> labels;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    int max = 1;
    for (final int v in values) {
      if (v > max) max = v;
    }
    return Column(
      children: <Widget>[
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int i = 0; i < values.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message: '${values[i]}',
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: values[i] / max),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOut,
                        builder: (BuildContext c, double f, Widget? _) => Container(
                          height: values[i] == 0 ? 2 : (height - 4) * f + 2,
                          decoration: BoxDecoration(
                            color: values[i] == 0 ? theme.colorScheme.surfaceContainerHighest : color,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 14,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < values.length; i++)
                Expanded(
                  child: labels.containsKey(i)
                      ? OverflowBox(
                          maxWidth: 60,
                          child: Text(labels[i]!, textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.s});
  final FcStats s;

  @override
  Widget build(BuildContext context) {
    final int week = s.forecast.take(7).fold(0, (int a, int b) => a + b);
    return FcSectionCard(
      title: 'Upcoming reviews',
      icon: Icons.event_outlined,
      trailing: Text('$week in 7 days', style: Theme.of(context).textTheme.labelMedium),
      child: _Bars(
        values: s.forecast,
        color: Theme.of(context).colorScheme.fcReview,
        labels: const <int, String>{0: 'Today', 7: '1w', 14: '2w', 21: '3w', 29: '30d'},
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.s});
  final FcStats s;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final StateBreakdown b = s.breakdown;
    final List<(String, int, Color)> parts = <(String, int, Color)>[
      ('New', b.newCards, cs.fcNew),
      ('Learning', b.learning, cs.fcLearning),
      ('Young', b.young, cs.fcReview.withValues(alpha: 0.55)),
      ('Mature', b.mature, cs.fcReview),
      ('Suspended', b.suspended, cs.outline),
    ];
    return FcSectionCard(
      title: 'Your cards',
      icon: Icons.pie_chart_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: <Widget>[
                  for (final (String, int, Color) p in parts)
                    if (p.$2 > 0) Expanded(flex: p.$2, child: Container(color: p.$3)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: <Widget>[
              for (final (String, int, Color) p in parts)
                Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: p.$3, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${p.$1} ${p.$2}', style: theme.textTheme.labelMedium),
                ]),
            ],
          ),
          const SizedBox(height: 8),
          Text('Mature cards have a memory strength of 3+ weeks.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Last30Card extends StatelessWidget {
  const _Last30Card({required this.s});
  final FcStats s;

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now().subtract(const Duration(hours: studyDayStartHour));
    final Map<String, int> byDay = <String, int>{for (final DayCount d in s.last30) d.day: d.total};
    final List<int> values = <int>[
      for (int i = 29; i >= 0; i--) byDay[dayKey(DateTime(today.year, today.month, today.day - i))] ?? 0,
    ];
    final int total = values.fold(0, (int a, int b) => a + b);
    return FcSectionCard(
      title: 'Last 30 days',
      icon: Icons.bar_chart_rounded,
      trailing: Text('$total reviews', style: Theme.of(context).textTheme.labelMedium),
      child: _Bars(
        values: values,
        color: Theme.of(context).colorScheme.primary,
        labels: const <int, String>{0: '30d', 15: '15d', 29: 'Today'},
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.s});
  final FcStats s;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int mins = (s.totals.studyMs / 60000).round();
    final String time = mins >= 60 ? '${(mins / 60).toStringAsFixed(1)} h' : '$mins min';
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: <Widget>[
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
            Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        );
    return FcSectionCard(
      title: 'All time',
      icon: Icons.all_inclusive,
      child: Column(children: <Widget>[
        row('Decks', '${s.totals.decks}'),
        row('Cards', '${s.totals.cards}'),
        row('Reviews', '${s.totals.reviews}'),
        row('Time studied', time),
      ]),
    );
  }
}

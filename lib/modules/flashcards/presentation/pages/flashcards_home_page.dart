import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_stats_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_sheets.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_tile.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';

/// Flashcards home: what is due today, your streak, and your decks.
class FlashcardsHomePage extends ConsumerWidget {
  const FlashcardsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<FcDeckSummary>> decks = ref.watch(fcDecksProvider);
    final FcDashboard dash =
        ref.watch(fcDashboardProvider).asData?.value ?? FcDashboard.empty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search cards',
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.flashcardsSearch),
          ),
          IconButton(
            tooltip: 'Statistics',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.push(AppRoutes.flashcardsStats),
          ),
          PopupMenuButton<String>(
            onSelected: (String v) {
              switch (v) {
                case 'decks':
                  context.push(AppRoutes.flashcardsDecks);
                case 'import':
                  context.push(AppRoutes.flashcardsImport);
                case 'export':
                  context.push(fcExportLocation());
              }
            },
            itemBuilder: (BuildContext c) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'decks', child: Text('All decks')),
              PopupMenuItem<String>(value: 'import', child: Text('Import cards')),
              PopupMenuItem<String>(value: 'export', child: Text('Export & backup')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDeckEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('New deck'),
      ),
      body: decks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Couldn’t load your decks',
          message: '$e',
        ),
        data: (List<FcDeckSummary> list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.style_outlined,
              title: 'Make your first deck',
              message: 'Create a deck, add cards, and the app schedules every review for you.',
              action: Wrap(
                spacing: 12,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () => showDeckEditor(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New deck'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.flashcardsImport),
                    child: const Text('Import cards'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: <Widget>[
              _TodayCard(dash: dash),
              _StatsStrip(dash: dash),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
                child: Row(
                  children: <Widget>[
                    Text('Your decks',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.flashcardsDecks),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
              for (final FcDeckSummary s in list) FcDeckTile(summary: s),
            ],
          );
        },
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.dash});
  final FcDashboard dash;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final StudyCounts c = dash.counts;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Flashcards',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _DashboardCount(
                  icon: Icons.schedule_rounded,
                  label: 'Due',
                  value: c.reviewCount,
                  color: cs.error,
                ),
              ),
              Expanded(
                child: _DashboardCount(
                  icon: Icons.school_outlined,
                  label: 'Learning',
                  value: c.learningCount,
                  color: cs.tertiary,
                ),
              ),
              Expanded(
                child: _DashboardCount(
                  icon: Icons.fiber_new_rounded,
                  label: 'New',
                  value: c.newCount,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: c.reviewCount == 0
                  ? null
                  : () => context.push(fcStudyLocation()),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCount extends StatelessWidget {
  const _DashboardCount({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.dash});
  final FcDashboard dash;

  @override
  Widget build(BuildContext context) {
    Widget cell(IconData icon, Color color, String value, String label) => Expanded(
          child: FcSectionCard(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: <Widget>[
                Icon(icon, color: color),
                const SizedBox(height: 6),
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                Text(label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          cell(Icons.local_fire_department_rounded, Colors.orange, '${dash.streak}', dash.streak == 1 ? 'day streak' : 'day streak'),
          cell(Icons.check_circle_outline, Theme.of(context).colorScheme.fcReview, '${dash.reviewsToday}', 'reviewed today'),
          cell(Icons.layers_outlined, Theme.of(context).colorScheme.primary, '${dash.totalCards}', 'cards in ${dash.totalDecks} ${dash.totalDecks == 1 ? 'deck' : 'decks'}'),
        ],
      ),
    );
  }
}

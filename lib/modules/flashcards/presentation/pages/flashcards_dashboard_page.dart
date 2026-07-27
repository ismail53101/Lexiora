import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_editor.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_common.dart';

/// The Flashcards dashboard: review queue + quick actions + recent activity.
class FlashcardsDashboardPage extends ConsumerWidget {
  const FlashcardsDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push(AppRoutes.flashcardsSearch),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          const _ReviewQueueCard(),
          const _QuickActions(),
          const _RecentActivityCard(),
          const SizedBox(height: 24),
        ].animate(interval: 45.ms).fadeIn(duration: 220.ms).slideY(
              begin: 0.05,
              end: 0,
              curve: Curves.easeOut,
            ),
      ),
    );
  }
}

class _ReviewQueueCard extends ConsumerWidget {
  const _ReviewQueueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ReviewQueue q = ref.watch(reviewQueueProvider).maybeWhen(
          data: (ReviewQueue v) => v,
          orElse: () => ReviewQueue.empty,
        );
    return FcSectionCard(
      icon: Icons.playlist_play,
      title: "Today's Review",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${q.total}',
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text('cards to review',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _QueuePill(label: 'New', value: q.newCount, color: theme.colorScheme.primary),
              _QueuePill(label: 'Learning', value: q.learningCount, color: theme.colorScheme.tertiary),
              _QueuePill(label: 'Review', value: q.reviewCount, color: theme.colorScheme.secondary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(Icons.schedule, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Estimated time: ${q.estimatedMinutes} min',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              FilledButton.icon(
                onPressed: q.total == 0
                    ? null
                    : () => context.push('${AppRoutes.flashcardsStudy}?mode=due'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueuePill extends StatelessWidget {
  const _QueuePill({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: <Widget>[
            Text('$value',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800, color: color)),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final List<_Action> actions = <_Action>[
      _Action(Icons.add, 'Create Deck', () => showDeckEditor(context)),
      _Action(Icons.library_books_outlined, 'My Decks',
          () => context.push(AppRoutes.flashcardsDecks)),
      _Action(Icons.local_fire_department_outlined, 'Difficult Cards',
          () => context.push('${AppRoutes.flashcardsStudy}?mode=difficult')),
      _Action(Icons.bar_chart, 'Statistics',
          () => context.push(AppRoutes.flashcardsStats)),
      _Action(Icons.download_outlined, 'Import Cards',
          () => context.push(AppRoutes.flashcardsImport)),
      _Action(Icons.ios_share, 'Export & Backup',
          () => context.push(AppRoutes.flashcardsExport)),
    ];
    return FcSectionCard(
      icon: Icons.grid_view_outlined,
      title: 'Dashboard',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          const double gap = 12;
          final double w = (c.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: <Widget>[
              for (final _Action a in actions)
                SizedBox(width: w, child: _ActionTile(action: a)),
            ],
          );
        },
      ),
    );
  }
}

class _Action {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});
  final _Action action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: <Widget>[
              Icon(action.icon, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(action.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityCard extends ConsumerWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<ReviewActivity> items = ref.watch(recentActivityProvider).maybeWhen(
          data: (List<ReviewActivity> v) => v.take(6).toList(),
          orElse: () => const <ReviewActivity>[],
        );
    return FcSectionCard(
      icon: Icons.history,
      title: 'Recent Activity',
      child: items.isEmpty
          ? Text('No reviews yet — start studying to see your activity.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
          : Column(
              children: <Widget>[
                for (final ReviewActivity a in items)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: _RatingDot(rating: a.rating),
                    title: Text(a.cardFront,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${a.deckName} · ${a.rating.label}'),
                  ),
              ],
            ),
    );
  }
}

class _RatingDot extends StatelessWidget {
  const _RatingDot({required this.rating});
  final CardRating rating;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    final Color c = switch (rating) {
      CardRating.again => s.error,
      CardRating.hard => s.tertiary,
      CardRating.good => s.primary,
      CardRating.easy => s.secondary,
    };
    return CircleAvatar(radius: 6, backgroundColor: c);
  }
}

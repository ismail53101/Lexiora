import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_stats_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';

/// "Flashcards due today" shortcut for the planner. Hidden when there is
/// nothing due, so it never clutters the day.
class FlashcardsDueCard extends ConsumerWidget {
  const FlashcardsDueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FcDashboard? dash = ref.watch(fcDashboardProvider).asData?.value;
    if (dash == null || dash.counts.isEmpty) return const SizedBox.shrink();
    final StudyCounts c = dash.counts;
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: cs.secondaryContainer.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: <Widget>[
            Icon(Icons.style_rounded, color: cs.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${c.total} flashcards due',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.onSecondaryContainer)),
                  Text(
                    '${c.newCount} new · ${c.learningCount} learning · ${c.reviewCount} review · ≈ ${c.estimatedMinutes} min',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSecondaryContainer),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => context.push(AppRoutes.flashcardsStudy),
              child: const Text('Study'),
            ),
          ],
        ),
      ),
    );
  }
}

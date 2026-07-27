import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

/// 🔥 Study streak: current & best consecutive study days, with a motivator.
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final StudyStreak streak = ref.watch(studyStreakProvider).maybeWhen(
          data: (StudyStreak s) => s,
          orElse: () => StudyStreak.empty,
        );

    return SectionCard(
      icon: Icons.local_fire_department,
      title: 'Study Streak',
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  const Text('🔥', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 6),
                  Text('${streak.current}',
                      style: theme.textTheme.displaySmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('day${streak.current == 1 ? '' : 's'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Best: ${streak.best} day${streak.best == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _message(streak.current),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  String _message(int current) {
    if (current <= 0) return 'Study today to start your streak!';
    if (current == 1) return 'Great start — come back tomorrow to keep it going!';
    if (current < 7) return "You're on a $current-day streak. Nice momentum!";
    if (current < 14) return '🔥 $current-day streak — a full week and counting!';
    if (current < 30) return "🔥 You're on a $current-day streak. Unstoppable!";
    return '🔥 $current days straight — you are a study machine!';
  }
}

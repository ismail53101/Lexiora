import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_goal.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/goal_editor.dart';

/// 🔥 Study Streak + 🎯 Today's Goal + ⏱ Study Today, merged into one
/// compact three-tile row instead of three separate full-width cards. Same
/// underlying data/providers as before — just a tighter layout.
class TodayOverviewRow extends ConsumerWidget {
  const TodayOverviewRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StudyStreak streak = ref.watch(studyStreakProvider).maybeWhen(
          data: (StudyStreak s) => s,
          orElse: () => StudyStreak.empty,
        );
    final String day = ref.watch(studyTodayProvider);
    final List<StudyGoal> goals = ref.watch(studyGoalsProvider).maybeWhen(
          data: (List<StudyGoal> g) => g,
          orElse: () => const <StudyGoal>[],
        );
    final int minutesToday = ref.watch(studyMinutesTodayProvider).maybeWhen(
          data: (int m) => m,
          orElse: () => 0,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          const double gap = 8;
          final double w = (c.maxWidth - gap * 2) / 3;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(width: w, child: _StreakTile(streak: streak)),
                const SizedBox(width: gap),
                SizedBox(width: w, child: _GoalTile(day: day, goals: goals)),
                const SizedBox(width: gap),
                SizedBox(width: w, child: _StudyTodayTile(minutes: minutesToday)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.onTap, required this.child});
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: child,
        ),
      ),
    );
  }
}

class _StreakTile extends StatelessWidget {
  const _StreakTile({required this.streak});
  final StudyStreak streak;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return _Tile(
      onTap: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('🔥', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text('${streak.current}d',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text('Streak · best ${streak.best}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.day, required this.goals});
  final String day;
  final List<StudyGoal> goals;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final StudyGoal? primary = goals.isEmpty ? null : goals.first;
    return _Tile(
      onTap: () => primary == null
          ? showGoalEditor(context, day: day)
          : showGoalEditor(context, day: day, existing: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('🎯', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          if (primary == null) ...<Widget>[
            Text('No goal',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text('Tap to set',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700)),
          ] else ...<Widget>[
            Text('${(primary.progress * 100).round()}%',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              goals.length > 1 ? '${primary.title} +${goals.length - 1}' : primary.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudyTodayTile extends StatelessWidget {
  const _StudyTodayTile({required this.minutes});
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return _Tile(
      onTap: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('⏱', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(formatDuration(minutes),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text('Study today',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_goal.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/goal_editor.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

/// 🎯 Today's goal(s) with a circular progress indicator and quick +/- controls.
class DailyGoalCard extends ConsumerWidget {
  const DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String day = ref.watch(studyTodayProvider);
    final List<StudyGoal> goals = ref.watch(studyGoalsProvider).maybeWhen(
          data: (List<StudyGoal> g) => g,
          orElse: () => const <StudyGoal>[],
        );

    return SectionCard(
      icon: Icons.track_changes,
      title: "Today's Goal",
      trailing: IconButton(
        icon: const Icon(Icons.add),
        tooltip: 'Add goal',
        onPressed: () => showGoalEditor(context, day: day),
      ),
      child: goals.isEmpty
          ? _Empty(day: day)
          : Column(
              children: <Widget>[
                _PrimaryGoal(goal: goals.first),
                if (goals.length > 1) ...<Widget>[
                  const Divider(height: 20),
                  for (final StudyGoal g in goals.skip(1)) _GoalRow(goal: g),
                ],
              ],
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.day});
  final String day;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('No goal set for today.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => showGoalEditor(context, day: day),
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Set a goal'),
        ),
      ],
    );
  }
}

class _PrimaryGoal extends ConsumerWidget {
  const _PrimaryGoal({required this.goal});
  final StudyGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        ProgressRing(
          value: goal.progress,
          size: 96,
          strokeWidth: 9,
          center: FittedBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('${goal.currentCount}',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text('/ ${goal.targetCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(goal.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                goal.achieved
                    ? 'Achieved 🎉'
                    : '${(goal.progress * 100).round()}% · ${goal.type.label}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: goal.achieved
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              _Stepper(goal: goal),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});
  final StudyGoal goal;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Stepper(goal: goal, compact: true),
        ],
      ),
    );
  }
}

class _Stepper extends ConsumerWidget {
  const _Stepper({required this.goal, this.compact = false});
  final StudyGoal goal;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void bump(int delta) =>
        ref.read(studyHubRepositoryProvider).incrementGoal(goal.id, delta);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: goal.currentCount <= 0 ? null : () => bump(-1),
          icon: const Icon(Icons.remove, size: 18),
        ),
        SizedBox(
          width: compact ? 44 : 56,
          child: Text(
            '${goal.currentCount}/${goal.targetCount}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: () => bump(1),
          icon: const Icon(Icons.add, size: 18),
        ),
        if (!compact)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Edit',
            onPressed: () => showGoalEditor(context, day: goal.day, existing: goal),
            icon: const Icon(Icons.more_vert, size: 18),
          ),
      ],
    );
  }
}

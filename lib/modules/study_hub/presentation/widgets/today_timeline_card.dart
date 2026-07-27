import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

/// 🕘 Today's Timeline: today's scheduled sessions & breaks, in time order.
class TodayTimelineCard extends ConsumerWidget {
  const TodayTimelineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<StudyTask> all = ref.watch(studyTasksProvider).maybeWhen(
          data: (List<StudyTask> t) => t,
          orElse: () => const <StudyTask>[],
        );
    final Map<String, int> colors = ref.watch(subjectColorsProvider).maybeWhen(
          data: (Map<String, int> m) => m,
          orElse: () => const <String, int>{},
        );
    final List<StudyTask> timed = all
        .where((StudyTask t) => t.startMinute != null)
        .toList()
      ..sort((StudyTask a, StudyTask b) =>
          a.startMinute!.compareTo(b.startMinute!));

    return SectionCard(
      icon: Icons.schedule,
      title: "Today's Timeline",
      child: timed.isEmpty
          ? Text(
              'Add a start time to your sessions to see them here.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          : Column(
              children: <Widget>[
                for (int i = 0; i < timed.length; i++)
                  _TimelineRow(
                    task: timed[i],
                    isLast: i == timed.length - 1,
                    colors: colors,
                  ),
              ],
            ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.task,
    required this.isLast,
    required this.colors,
  });
  final StudyTask task;
  final bool isLast;
  final Map<String, int> colors;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? subjectColor = subjectColorOf(task.displaySubject, colors);
    final Color dot = task.isBreak
        ? theme.colorScheme.tertiary
        : (subjectColor ??
            (task.completed
                ? theme.colorScheme.primary
                : theme.colorScheme.outline));
    final String second = task.isBreak
        ? 'Break'
        : (task.topic ?? '');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(formatMinuteOfDay(task.startMinute),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          Column(
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(task.isBreak ? task.title : task.displaySubject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (second.isNotEmpty)
                    Text(second,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/session_editor.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

/// A reusable planner row for a study session or a break. Used by the Daily,
/// Weekly and Monthly planners so behaviour is identical everywhere.
class SessionTile extends ConsumerWidget {
  const SessionTile({super.key, required this.task});
  final StudyTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    if (task.isBreak) return _break(context, theme);

    final String time = _timeRange(task);
    final String subtitle = <String>[
      if (task.topic != null && task.topic!.isNotEmpty) task.topic!,
      if (time.isNotEmpty) time,
    ].join(' · ');

    final Color? subjectColor = subjectColorOf(
      task.displaySubject,
      ref.watch(subjectColorsProvider).maybeWhen(
            data: (Map<String, int> m) => m,
            orElse: () => const <String, int>{},
          ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: subjectColor ?? Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Checkbox(
            value: task.completed,
            onChanged: (bool? v) => ref
                .read(studyHubRepositoryProvider)
                .setTaskCompleted(task.id, completed: v ?? false),
          ),
          _PriorityDot(priority: task.priority),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  task.displaySubject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                    color:
                        task.completed ? theme.colorScheme.onSurfaceVariant : null,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (task.status == TaskStatus.inProgress)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _StatusChip(label: 'Active', color: theme.colorScheme.tertiary),
            ),
          _menu(context, ref),
        ],
      ),
    );
  }

  Widget _break(BuildContext context, ThemeData theme) {
    final String time = _timeRange(task);
    return Consumer(builder: (BuildContext context, WidgetRef ref, _) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 8),
            Icon(Icons.free_breakfast_outlined,
                size: 20, color: theme.colorScheme.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                time.isEmpty ? task.title : '${task.title} · $time',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            _menu(context, ref),
          ],
        ),
      );
    });
  }

  Widget _menu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (String v) {
        if (v == 'edit') {
          task.isBreak
              ? showBreakEditor(context, day: task.day, existing: task)
              : showSessionEditor(context, day: task.day, existing: task);
        } else if (v == 'delete') {
          ref.read(studyHubRepositoryProvider).deleteTask(task.id);
        }
      },
      itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
        PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  String _timeRange(StudyTask t) {
    if (t.startMinute == null && t.endMinute == null) return '';
    if (t.endMinute == null) return formatMinuteOfDay(t.startMinute);
    if (t.startMinute == null) return formatMinuteOfDay(t.endMinute);
    return '${formatMinuteOfDay(t.startMinute)} – ${formatMinuteOfDay(t.endMinute)}';
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = switch (priority) {
      TaskPriority.high => scheme.error,
      TaskPriority.medium => scheme.tertiary,
      TaskPriority.low => scheme.outline,
    };
    return Tooltip(
      message: '${priority.label} priority',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

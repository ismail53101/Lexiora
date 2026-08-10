import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/session_editor.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/session_tile.dart';

/// A header + the sessions/breaks for a single [day] with add controls. Shared
/// by the Weekly and Monthly planners so behaviour is identical.
class DayPlannerSection extends ConsumerWidget {
  const DayPlannerSection({
    super.key,
    required this.day,
    required this.title,
    this.subtitle,
    this.highlight = false,
  });

  final String day; // YYYY-MM-DD
  final String title;
  final String? subtitle;
  final bool highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<StudyTask> tasks = ref.watch(studyDayTasksProvider(day)).maybeWhen(
          data: (List<StudyTask> t) => t,
          orElse: () => const <StudyTask>[],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: highlight ? theme.colorScheme.primary : null),
                  children: <InlineSpan>[
                    TextSpan(text: title),
                    if (subtitle != null)
                      TextSpan(
                        text: '  $subtitle',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.add),
              tooltip: 'Add',
              color: theme.colorScheme.surfaceContainerHigh,
              elevation: 8,
              onSelected: (String v) => v == 'session'
                  ? showSessionEditor(context, day: day)
                  : showBreakEditor(context, day: day),
              itemBuilder: (BuildContext context) =>
                  const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'session', child: Text('Add session')),
                PopupMenuItem<String>(value: 'break', child: Text('Add break')),
              ],
            ),
          ],
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('No sessions',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          )
        else
          for (final StudyTask t in tasks) SessionTile(task: t),
      ],
    );
  }
}

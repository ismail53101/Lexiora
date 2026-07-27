import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/session_editor.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/session_tile.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

/// 📅 Daily Planner: today's study sessions and breaks with full CRUD.
class DailyPlannerCard extends ConsumerWidget {
  const DailyPlannerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String day = ref.watch(studyTodayProvider);
    final List<StudyTask> tasks = ref.watch(studyTasksProvider).maybeWhen(
          data: (List<StudyTask> t) => t,
          orElse: () => const <StudyTask>[],
        );
    final Iterable<StudyTask> sessions =
        tasks.where((StudyTask t) => !t.isBreak);
    final int done = sessions.where((StudyTask t) => t.completed).length;

    return SectionCard(
      icon: Icons.event_note_outlined,
      title: 'Daily Planner',
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.add),
        tooltip: 'Add',
        onSelected: (String v) => v == 'session'
            ? showSessionEditor(context, day: day)
            : showBreakEditor(context, day: day),
        itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
          PopupMenuItem<String>(value: 'session', child: Text('Add session')),
          PopupMenuItem<String>(value: 'break', child: Text('Add break')),
        ],
      ),
      child: tasks.isEmpty
          ? _Empty(day: day)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('$done of ${sessions.length} sessions done',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                for (final StudyTask t in tasks) SessionTile(task: t),
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
        Text('No sessions planned for today.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: () => showSessionEditor(context, day: day),
              icon: const Icon(Icons.add_task),
              label: const Text('Add session'),
            ),
            OutlinedButton.icon(
              onPressed: () => showBreakEditor(context, day: day),
              icon: const Icon(Icons.free_breakfast_outlined),
              label: const Text('Add break'),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_template.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';

/// Editable routine templates. Applying a template copies its sessions into a
/// day as fully editable entries — it never locks data.
class TemplatesPage extends ConsumerWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<StudyTemplate> templates =
        ref.watch(studyTemplatesProvider).maybeWhen(
              data: (List<StudyTemplate> t) => t,
              orElse: () => const <StudyTemplate>[],
            );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: "Save today's plan as template",
            onPressed: () => _saveTodayAsTemplate(context, ref),
          ),
        ],
      ),
      body: templates.isEmpty
          ? const EmptyState(
              icon: Icons.bookmarks_outlined,
              title: 'No templates yet',
              message: 'Plan a day, then tap the bookmark icon to save it as a '
                  'reusable routine (e.g. "CSS Routine").',
            )
          : ListView.separated(
              itemCount: templates.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int i) {
                final StudyTemplate t = templates[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.event_repeat)),
                  title: Text(t.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${t.itemCount} item${t.itemCount == 1 ? '' : 's'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FilledButton.tonal(
                        onPressed: () => _apply(context, ref, t),
                        child: const Text('Apply'),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (String v) {
                          if (v == 'delete') {
                            ref
                                .read(studyHubRepositoryProvider)
                                .deleteTemplate(t.id);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            const <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                              value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _saveTodayAsTemplate(BuildContext context, WidgetRef ref) async {
    final TextEditingController name = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Save as template'),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Template name',
            hintText: 'e.g. CSS Routine',
          ),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(name.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    if (!context.mounted) return;
    await ref
        .read(studyHubRepositoryProvider)
        .saveTemplateFromDay(result, todayKey());
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Saved "$result"')));
    }
  }

  Future<void> _apply(
      BuildContext context, WidgetRef ref, StudyTemplate t) async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      helpText: 'Apply "${t.name}" to…',
    );
    if (date == null || !context.mounted) return;
    final int added = await ref
        .read(studyHubRepositoryProvider)
        .applyTemplateToDay(t.id, dayKey(date));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text('Added $added session${added == 1 ? '' : 's'} — '
                'all editable')));
    }
  }
}

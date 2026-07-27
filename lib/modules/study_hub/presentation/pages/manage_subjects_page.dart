import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_subject.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/study_hub_repository.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/subject_color_picker.dart';
import 'package:uuid/uuid.dart';

/// Manage Subjects: add, rename, colour, archive/restore, delete. Deleting a
/// subject removes only its colour label — study history stays intact.
class ManageSubjectsPage extends ConsumerStatefulWidget {
  const ManageSubjectsPage({super.key});

  @override
  ConsumerState<ManageSubjectsPage> createState() => _ManageSubjectsPageState();
}

class _ManageSubjectsPageState extends ConsumerState<ManageSubjectsPage> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<SubjectUsage>> usage =
        ref.watch(subjectUsageProvider(_showArchived));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        actions: <Widget>[
          IconButton(
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            icon: Icon(_showArchived
                ? Icons.unarchive_outlined
                : Icons.archive_outlined),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubject,
        icon: const Icon(Icons.add),
        label: const Text('Add subject'),
      ),
      body: usage.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => const Center(child: Text('Could not load subjects')),
        data: (List<SubjectUsage> items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.palette_outlined,
              title: 'No subjects yet',
              message: 'Add a subject or create a study session — then colour it.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int i) =>
                _SubjectRow(usage: items[i], onAction: _handle),
          );
        },
      ),
    );
  }

  StudyHubRepository get _repo => ref.read(studyHubRepositoryProvider);

  Future<void> _addSubject() async {
    final TextEditingController name = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Add subject'),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              labelText: 'Subject name', hintText: 'e.g. Pakistan Affairs'),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(name.text.trim()),
              child: const Text('Next')),
        ],
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    final int? color = await showSubjectColorPicker(context);
    if (color == null) return;
    final DateTime now = DateTime.now();
    await _repo.saveSubject(StudySubject(
      id: const Uuid().v4(),
      name: result,
      color: color,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> _handle(String action, SubjectUsage u) async {
    switch (action) {
      case 'color':
        final int? c =
            await showSubjectColorPicker(context, current: u.subject?.color);
        if (c == null) return;
        if (u.hasColor) {
          await _repo.setSubjectColor(u.subject!.id, c);
        } else {
          final DateTime now = DateTime.now();
          await _repo.saveSubject(StudySubject(
            id: const Uuid().v4(),
            name: u.name,
            color: c,
            createdAt: now,
            updatedAt: now,
          ));
        }
      case 'rename':
        if (!u.hasColor) return;
        final TextEditingController ctrl =
            TextEditingController(text: u.name);
        final String? newName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Rename subject'),
            content: TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'New name')),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
                  child: const Text('Save')),
            ],
          ),
        );
        if (newName != null && newName.isNotEmpty) {
          await _repo.renameSubject(u.subject!.id, newName);
        }
      case 'archive':
        if (u.hasColor) await _repo.setSubjectArchived(u.subject!.id, true);
      case 'restore':
        if (u.hasColor) await _repo.setSubjectArchived(u.subject!.id, false);
      case 'delete':
        if (u.hasColor) await _repo.deleteSubject(u.subject!.id);
    }
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.usage, required this.onAction});
  final SubjectUsage usage;
  final Future<void> Function(String, SubjectUsage) onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool archived = usage.subject?.archived ?? false;
    return ListTile(
      leading: GestureDetector(
        onTap: () => onAction('color', usage),
        child: CircleAvatar(
          backgroundColor: usage.hasColor
              ? usage.subject!.colorValue
              : theme.colorScheme.surfaceContainerHighest,
          child: usage.hasColor
              ? null
              : Icon(Icons.add, size: 18, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      title: Text(usage.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: archived ? TextDecoration.lineThrough : null,
          )),
      subtitle: Text(<String>[
        '${usage.sessionCount} session${usage.sessionCount == 1 ? '' : 's'}',
        if (archived) 'Archived',
        if (!usage.hasColor) 'No colour',
      ].join(' · ')),
      trailing: PopupMenuButton<String>(
        onSelected: (String v) => onAction(v, usage),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
              value: 'color',
              child: Text(usage.hasColor ? 'Change colour' : 'Add colour')),
          if (usage.hasColor)
            const PopupMenuItem<String>(value: 'rename', child: Text('Rename')),
          if (usage.hasColor && !archived)
            const PopupMenuItem<String>(value: 'archive', child: Text('Archive')),
          if (usage.hasColor && archived)
            const PopupMenuItem<String>(value: 'restore', child: Text('Restore')),
          if (usage.hasColor)
            const PopupMenuItem<String>(value: 'delete', child: Text('Delete colour')),
        ],
      ),
    );
  }
}

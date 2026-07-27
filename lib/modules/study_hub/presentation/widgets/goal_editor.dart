import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_goal.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:uuid/uuid.dart';

/// Opens the add/edit goal sheet. Pass [existing] to edit.
Future<void> showGoalEditor(
  BuildContext context, {
  required String day,
  StudyGoal? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _GoalEditorSheet(day: day, existing: existing),
  );
}

class _GoalEditorSheet extends ConsumerStatefulWidget {
  const _GoalEditorSheet({required this.day, this.existing});
  final String day;
  final StudyGoal? existing;

  @override
  ConsumerState<_GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends ConsumerState<_GoalEditorSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _target = TextEditingController(
      text: (widget.existing?.targetCount ?? 20).toString());
  late final TextEditingController _unit =
      TextEditingController(text: widget.existing?.unit ?? '');
  late GoalType _type = widget.existing?.type ?? GoalType.vocabulary;

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String title = _title.text.trim();
    final int target = int.tryParse(_target.text.trim()) ?? 0;
    if (title.isEmpty || target <= 0) return;
    final DateTime now = DateTime.now();
    final StudyGoal goal = (widget.existing ??
            StudyGoal(
              id: const Uuid().v4(),
              day: widget.day,
              title: title,
              targetCount: target,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
      title: title,
      type: _type,
      targetCount: target,
      unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
      updatedAt: now,
      clearUnit: _unit.text.trim().isEmpty,
    );
    await ref.read(studyHubRepositoryProvider).saveGoal(goal);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.existing == null ? "Set today's goal" : 'Edit goal',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Goal',
                hintText: 'e.g. Learn 20 vocabulary words',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GoalType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Category'),
              items: <DropdownMenuItem<GoalType>>[
                for (final GoalType t in GoalType.values)
                  DropdownMenuItem<GoalType>(value: t, child: Text(t.label)),
              ],
              onChanged: (GoalType? t) =>
                  setState(() => _type = t ?? GoalType.custom),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _target,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Target'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit (optional)',
                      hintText: 'words, pages…',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                if (widget.existing != null)
                  TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(studyHubRepositoryProvider)
                          .deleteGoal(widget.existing!.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.delete_outline,
                        color: theme.colorScheme.error),
                    label: Text('Delete',
                        style: TextStyle(color: theme.colorScheme.error)),
                  ),
                const Spacer(),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

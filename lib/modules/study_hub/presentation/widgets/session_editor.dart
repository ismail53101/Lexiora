import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/scheduling/study_schedule_service.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:uuid/uuid.dart';

/// Add/edit a STUDY SESSION (subject + topic + notes + time + priority + status).
Future<void> showSessionEditor(
  BuildContext context, {
  required String day,
  StudyTask? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _SessionEditor(day: day, existing: existing),
  );
}

/// Add/edit a BREAK (name + start/end → duration).
Future<void> showBreakEditor(
  BuildContext context, {
  required String day,
  StudyTask? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _BreakEditor(day: day, existing: existing),
  );
}

double _bottomInset(BuildContext c) => MediaQuery.of(c).viewInsets.bottom + 16;

/// Merges lists into one, de-duplicated case-insensitively, order preserved.
List<String> _mergeUnique(List<List<String>> lists) {
  final Set<String> seen = <String>{};
  final List<String> out = <String>[];
  for (final List<String> list in lists) {
    for (final String v in list) {
      final String key = v.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(v);
    }
  }
  return out;
}

class _SessionEditor extends ConsumerStatefulWidget {
  const _SessionEditor({required this.day, this.existing});
  final String day;
  final StudyTask? existing;

  @override
  ConsumerState<_SessionEditor> createState() => _SessionEditorState();
}

class _SessionEditorState extends ConsumerState<_SessionEditor> {
  late final TextEditingController _subject =
      TextEditingController(text: widget.existing?.subject ?? widget.existing?.title ?? '');
  late final TextEditingController _topic =
      TextEditingController(text: widget.existing?.topic ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.existing?.notes ?? '');
  late int? _start = widget.existing?.startMinute;
  late int? _end = widget.existing?.endMinute;
  late TaskPriority _priority = widget.existing?.priority ?? TaskPriority.medium;
  late TaskStatus _status = widget.existing?.status ?? TaskStatus.pending;
  bool _addBreak = false;
  int _breakMinutes = 10;
  late bool _automatic = widget.existing?.autoScheduled ?? true;

  @override
  void dispose() {
    _subject.dispose();
    _topic.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool start, int? initialMinute}) async {
    final int base = initialMinute ??
        ((start ? _start : _end) ?? (start ? 9 * 60 : 10 * 60));
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base ~/ 60, minute: base % 60),
    );
    if (picked == null) return;
    final int m = picked.hour * 60 + picked.minute;
    setState(() {
      if (start) {
        _automatic = false;
        _start = m;
      } else {
        _end = m;
      }
    });
    // After the start time is confirmed (OK), jump straight into the
    // end-time picker — pre-filled with start + 1h — so the user just
    // confirms the end; no need to tap the End button separately.
    if (start && mounted) {
      final int suggested =
          (_end != null && _end! > m) ? _end! : (m + 60) % (24 * 60);
      await _pickTime(start: false, initialMinute: suggested);
    }
  }

  Future<void> _save() async {
    final String subject = _subject.text.trim();
    if (subject.isEmpty) return;
    final DateTime now = DateTime.now();
    final StudyTask base = widget.existing ??
        StudyTask(
          id: const Uuid().v4(),
          day: widget.day,
          title: subject,
          createdAt: now,
          updatedAt: now,
        );
    final StudyTask task = base.copyWith(
      title: subject,
      subject: subject,
      topic: _topic.text.trim().isEmpty ? null : _topic.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      startMinute: _start,
      endMinute: _end,
      priority: _priority,
      status: _status,
      kind: SessionKind.session,
      durationMinutes: _start != null && _end != null ? _end! - _start! : null,
      autoScheduled: _automatic,
      updatedAt: now,
      completedAt: _status == TaskStatus.completed ? now : null,
      clearTopic: _topic.text.trim().isEmpty,
      clearNotes: _notes.text.trim().isEmpty,
      clearTimes: _start == null && _end == null,
    );
    await ref.read(studyHubRepositoryProvider).saveTask(task);
    // One combined flow: optionally create the break right after this
    // session's end time, instead of it being a separate "Add break" step —
    // so a Pomodoro-style focus+break pair can be planned in one go.
    if (widget.existing == null && _addBreak && _end != null) {
      final int breakStart = _end!;
      final int breakEnd = (breakStart + _breakMinutes) % (24 * 60);
      await ref.read(studyHubRepositoryProvider).saveTask(
            StudyTask(
              id: const Uuid().v4(),
              day: widget.day,
              title: 'Break',
              startMinute: breakStart,
              endMinute: breakEnd,
              kind: SessionKind.breakTime,
              autoScheduled: true,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<StudyTask> dayTasks = ref
        .watch(studyDayTasksProvider(widget.day))
        .maybeWhen(
          data: (List<StudyTask> tasks) => tasks,
          orElse: () => const <StudyTask>[],
        );
    final int? nextAvailable = StudyScheduleService.nextAvailableMinute(
      dayTasks,
      excludeId: widget.existing?.id,
    );
    List<String> data(AsyncValue<List<String>> v) => v.maybeWhen(
          data: (List<String> s) => s,
          orElse: () => const <String>[],
        );
    // Recent + frequent first (fast planning), then the rest alphabetically.
    final List<String> subjects = _mergeUnique(<List<String>>[
      data(ref.watch(recentSubjectsProvider)),
      data(ref.watch(frequentSubjectsProvider)),
      data(ref.watch(subjectSuggestionsProvider)),
    ]);
    final List<String> topics = _mergeUnique(<List<String>>[
      data(ref.watch(recentTopicsProvider)),
      data(ref.watch(topicSuggestionsProvider)),
    ]);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, _bottomInset(context)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.existing == null ? 'New study session' : 'Edit session',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _subject,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Subject',
                hintText: 'e.g. Pakistan Affairs',
              ),
            ),
            _Suggestions(values: subjects, onTap: (String v) => _subject.text = v),
            const SizedBox(height: 12),
            TextField(
              controller: _topic,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Topic (optional)',
                hintText: 'e.g. Economy of Pakistan',
              ),
            ),
            _Suggestions(values: topics, onTap: (String v) => _topic.text = v),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes / description (optional)',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _automatic,
              onChanged: (bool value) => setState(() => _automatic = value),
              title: const Text('Automatic scheduling'),
              subtitle: Text(
                _automatic && nextAvailable != null
                    ? 'Next available: ${formatMinuteOfDay(nextAvailable)}'
                    : 'Choose a custom start time manually',
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(start: true),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(
                      _automatic && nextAvailable != null
                          ? formatMinuteOfDay(nextAvailable)
                          : (_start == null ? 'Start' : formatMinuteOfDay(_start)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(start: false),
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label:
                        Text(_end == null ? 'End' : formatMinuteOfDay(_end)),
                  ),
                ),
              ],
            ),
            if (widget.existing == null) ...<Widget>[
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _addBreak,
                onChanged: (bool v) => setState(() => _addBreak = v),
                title: const Text('Add a break right after this session'),
                subtitle: const Text('Creates it in the same step — Pomodoro-style'),
              ),
              if (_addBreak)
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final int m in const <int>[5, 10, 15, 20])
                      ChoiceChip(
                        label: Text('$m min'),
                        selected: _breakMinutes == m,
                        onSelected: (_) => setState(() => _breakMinutes = m),
                      ),
                  ],
                ),
            ],
            const SizedBox(height: 16),
            Text('Priority', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: const <ButtonSegment<TaskPriority>>[
                ButtonSegment<TaskPriority>(value: TaskPriority.low, label: Text('Low')),
                ButtonSegment<TaskPriority>(value: TaskPriority.medium, label: Text('Med')),
                ButtonSegment<TaskPriority>(value: TaskPriority.high, label: Text('High')),
              ],
              selected: <TaskPriority>{_priority},
              onSelectionChanged: (Set<TaskPriority> s) =>
                  setState(() => _priority = s.first),
            ),
            const SizedBox(height: 12),
            Text('Status', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<TaskStatus>(
              segments: const <ButtonSegment<TaskStatus>>[
                ButtonSegment<TaskStatus>(value: TaskStatus.pending, label: Text('Pending')),
                ButtonSegment<TaskStatus>(value: TaskStatus.inProgress, label: Text('Active')),
                ButtonSegment<TaskStatus>(value: TaskStatus.completed, label: Text('Done')),
              ],
              selected: <TaskStatus>{_status},
              onSelectionChanged: (Set<TaskStatus> s) =>
                  setState(() => _status = s.first),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                if (widget.existing != null)
                  TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(studyHubRepositoryProvider)
                          .deleteTask(widget.existing!.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
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

class _BreakEditor extends ConsumerStatefulWidget {
  const _BreakEditor({required this.day, this.existing});
  final String day;
  final StudyTask? existing;

  @override
  ConsumerState<_BreakEditor> createState() => _BreakEditorState();
}

class _BreakEditorState extends ConsumerState<_BreakEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.title ?? '');
  late int? _start = widget.existing?.startMinute;
  late int? _end = widget.existing?.endMinute;

  static const List<String> _presets = <String>[
    'Tea Break', 'Lunch', 'Prayer', 'Walk', 'Rest',
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool start, int? initialMinute}) async {
    final int base = initialMinute ??
        ((start ? _start : _end) ?? (start ? 11 * 60 : 11 * 60 + 15));
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base ~/ 60, minute: base % 60),
    );
    if (picked == null) return;
    final int m = picked.hour * 60 + picked.minute;
    setState(() {
      if (start) {
        _start = m;
      } else {
        _end = m;
      }
    });
    // Same flow as sessions: confirming the start opens the end picker
    // automatically (pre-filled with start + 15 min).
    if (start && mounted) {
      final int suggested =
          (_end != null && _end! > m) ? _end! : (m + 15) % (24 * 60);
      await _pickTime(start: false, initialMinute: suggested);
    }
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return;
    final DateTime now = DateTime.now();
    final StudyTask base = widget.existing ??
        StudyTask(
          id: const Uuid().v4(),
          day: widget.day,
          title: name,
          createdAt: now,
          updatedAt: now,
        );
    final StudyTask task = base.copyWith(
      title: name,
      startMinute: _start,
      endMinute: _end,
      kind: SessionKind.breakTime,
      status: TaskStatus.pending,
      durationMinutes: _start != null && _end != null ? _end! - _start! : null,
      updatedAt: now,
      clearSubject: true,
      clearTopic: true,
      clearTimes: _start == null && _end == null,
    );
    await ref.read(studyHubRepositoryProvider).saveTask(task);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, _bottomInset(context)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.existing == null ? 'New break' : 'Edit break',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Break name',
                hintText: 'e.g. Tea Break',
              ),
            ),
            _Suggestions(values: _presets, onTap: (String v) => _name.text = v),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(start: true),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(
                        _start == null ? 'Start' : formatMinuteOfDay(_start)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(start: false),
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label:
                        Text(_end == null ? 'End' : formatMinuteOfDay(_end)),
                  ),
                ),
              ],
            ),
            if (_start != null && _end != null && _end! > _start!)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Duration: ${formatDuration(_end! - _start!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                if (widget.existing != null)
                  TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(studyHubRepositoryProvider)
                          .deleteTask(widget.existing!.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
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

/// A wrapping row of tappable suggestion chips (from the user's own history).
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.values, required this.onTap});
  final List<String> values;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: -4,
        children: <Widget>[
          for (final String v in values.take(8))
            ActionChip(
              label: Text(v),
              visualDensity: VisualDensity.compact,
              onPressed: () => onTap(v),
            ),
        ],
      ),
    );
  }
}

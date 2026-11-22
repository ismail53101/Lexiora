import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/recurrence/recurrence.dart';
import 'package:lexiora/modules/study_hub/domain/recurrence/repeat_series.dart';
import 'package:lexiora/modules/study_hub/domain/scheduling/pomodoro_planner.dart';
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

/// Focus + break lengths offered when splitting a session (minutes).
const List<(int, int)> _blockPresets = <(int, int)>[(25, 5), (50, 10), (90, 15)];

enum _TimeMode {
  /// Placed right after the previous item of the day (the default).
  auto('After previous'),

  /// The user chooses the start time.
  manual('Set time'),

  /// No time at all (just a to-do for the day).
  none('No time');

  const _TimeMode(this.label);
  final String label;
}

const List<String> _shortMonths = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Wed 11 Mar" for a `yyyy-MM-dd` day.
String _shortDay(String key) {
  final DateTime? d = parseDayKeyOrNull(key);
  if (d == null) return key;
  return '${weekdayShort[d.weekday - 1]} ${d.day} ${_shortMonths[d.month - 1]}';
}

TimeOfDay _timeOfDay(int minute) {
  final int m = minute.clamp(0, 24 * 60 - 1);
  return TimeOfDay(hour: m ~/ 60, minute: m % 60);
}

/// Friendly text for a scheduling error (shown inside the sheet, where the user
/// is looking — a SnackBar would appear hidden behind it).
String _scheduleErrorText(Object error) {
  if (error is StudyScheduleInvalidTimeException) return error.message;
  if (error is StudyScheduleOverlapException) {
    String span(StudyTask t) =>
        '“${t.displaySubject}” (${formatMinuteOfDay(t.startMinute)}–${formatMinuteOfDay(t.endMinute)})';
    return 'This overlaps with ${span(error.conflict.previous)} and '
        '${span(error.conflict.item)}. Pick another time, or choose '
        '“After previous”.';
  }
  return 'Could not save: $error';
}

/// Duration chips + a ±5 minute fine-tune, shared by sessions and breaks.
class _DurationPicker extends StatelessWidget {
  const _DurationPicker({
    required this.minutes,
    required this.options,
    required this.onChanged,
  });

  final int minutes;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            for (final int m in options)
              ChoiceChip(
                label: Text(formatDuration(m)),
                selected: minutes == m,
                onSelected: (_) => onChanged(m),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            IconButton.filledTonal(
              tooltip: '5 minutes less',
              icon: const Icon(Icons.remove),
              onPressed: minutes <= 5 ? null : () => onChanged(minutes - 5),
            ),
            Expanded(
              child: Text(
                formatDuration(minutes),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.filledTonal(
              tooltip: '5 minutes more',
              icon: const Icon(Icons.add),
              onPressed: minutes >= 12 * 60 ? null : () => onChanged(minutes + 5),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: cs.onErrorContainer)),
          ),
        ],
      ),
    );
  }
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

  /// Ids are fixed for the life of the sheet, so pressing Save twice (or again
  /// after an error) updates the same rows instead of adding duplicates.
  late final String _sessionId = widget.existing?.id ?? const Uuid().v4();
  String _breakId = const Uuid().v4();

  late _TimeMode _mode = _initialMode();
  late int? _start = widget.existing?.startMinute;
  late int _duration = widget.existing == null
      ? StudyScheduleService.defaultSessionMinutes
      : StudyScheduleService.durationOf(widget.existing!);
  int _next = StudyScheduleService.defaultDayStartMinute;

  late TaskPriority _priority = widget.existing?.priority ?? TaskPriority.medium;
  late TaskStatus _status = widget.existing?.status ?? TaskStatus.pending;
  bool _addBreak = false;
  bool _split = false;
  int _preset = 1;
  bool _repeat = false;
  int _repeatWeeks = 8;
  late final Set<int> _repeatDays = <int>{
    parseDayKeyOrNull(widget.day)?.weekday ?? DateTime.now().weekday,
  };
  late final String _seriesId = const Uuid().v4();
  int _breakMinutes = StudyScheduleService.defaultBreakMinutes;
  StudyTask? _existingBreak;
  bool _breakLoaded = false;
  bool _saving = false;
  String? _error;

  _TimeMode _initialMode() {
    final StudyTask? e = widget.existing;
    if (e == null) return _TimeMode.auto;
    if (e.startMinute == null) return _TimeMode.none;
    return e.autoScheduled ? _TimeMode.auto : _TimeMode.manual;
  }

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      unawaited(_loadExistingBreak());
    } else {
      _breakLoaded = true;
    }
  }

  Future<void> _loadExistingBreak() async {
    final StudyTask? session = widget.existing;
    if (session == null) return;
    final List<StudyTask> tasks =
        await ref.read(studyHubRepositoryProvider).watchTasks(widget.day).first;
    final Iterable<StudyTask> matches = tasks.where((StudyTask task) =>
        task.isBreak && task.startMinute == session.endMinute);
    final StudyTask? breakTask = matches.isEmpty ? null : matches.first;
    if (!mounted) return;
    setState(() {
      _existingBreak = breakTask;
      if (breakTask != null) {
        _breakId = breakTask.id;
        _addBreak = true;
        _breakMinutes = StudyScheduleService.durationOf(breakTask);
      }
      _breakLoaded = true;
    });
  }

  @override
  void dispose() {
    _subject.dispose();
    _topic.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Where this session starts for the current choice (null = no time).
  int? _startFor() {
    switch (_mode) {
      case _TimeMode.none:
        return null;
      case _TimeMode.manual:
        return _start ?? _next;
      case _TimeMode.auto:
        final StudyTask? e = widget.existing;
        // Editing an automatic session keeps its place in the day.
        if (e != null && e.autoScheduled && e.startMinute != null) {
          return e.startMinute;
        }
        return _next;
    }
  }

  Future<void> _pickStart(int current) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDay(current),
      helpText: 'START TIME',
    );
    if (picked == null) return;
    setState(() {
      _mode = _TimeMode.manual;
      _start = picked.hour * 60 + picked.minute;
      _error = null;
    });
  }

  Future<void> _pickEnd(int start, int currentEnd) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDay(currentEnd),
      helpText: 'END TIME',
    );
    if (picked == null) return;
    final int end = picked.hour * 60 + picked.minute;
    setState(() {
      if (end <= start) {
        _error = 'The end time must be after the start time '
            '(${formatMinuteOfDay(start)}).';
      } else {
        _duration = end - start;
        _error = null;
      }
    });
  }

  /// If a new session is being scheduled for today but its manual start
  /// time has already passed, offer a safe way to move it forward instead of
  /// silently creating a session in the past.
  Future<String?> _resolvePastTodayTime(int start) async {
    if (widget.existing != null ||
        widget.day != dayKey(DateTime.now()) ||
        _mode != _TimeMode.manual) {
      return widget.day;
    }

    final DateTime now = DateTime.now();
    if (start > now.hour * 60 + now.minute) return widget.day;

    final String? choice = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('This time has already passed'),
        content: Text(
          formatMinuteOfDay(start) +
              ' is already in the past for today. Would you like to move '
              'this session to tomorrow or choose another day?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop('tomorrow'),
            child: const Text('Tomorrow'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('other'),
            child: const Text('Choose another day'),
          ),
        ],
      ),
    );

    if (choice == 'tomorrow') {
      return dayKey(DateTime(now.year, now.month, now.day + 1));
    }
    if (choice != 'other') return choice == 'cancel' ? null : widget.day;

    if (!mounted) return null;
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 2, now.month, now.day),
      helpText: 'CHOOSE STUDY DAY',
    );
    return picked == null ? null : dayKey(picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    final String subject = _subject.text.trim();
    if (subject.isEmpty) {
      setState(() => _error = 'Enter a subject first.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final DateTime now = DateTime.now();
      if (!_breakLoaded) await _loadExistingBreak();

      final int? selectedStart = _startFor();
      final String? targetDay = selectedStart == null
          ? widget.day
          : await _resolvePastTodayTime(selectedStart);
      if (targetDay == null) {
        setState(() {
          _saving = false;
          _error = null;
        });
        return;
      }

      final StudyTask base = widget.existing ??
          StudyTask(
            id: _sessionId,
            day: targetDay,
            title: subject,
            createdAt: now,
            updatedAt: now,
          );
      final int? start = _startFor();
      final StudyTask common = base.copyWith(
        title: subject,
        subject: subject,
        topic: _topic.text.trim().isEmpty ? null : _topic.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        priority: _priority,
        status: _status,
        kind: SessionKind.session,
        updatedAt: now,
        completedAt: _status == TaskStatus.completed ? now : null,
        clearTopic: _topic.text.trim().isEmpty,
        clearNotes: _notes.text.trim().isEmpty,
      );
      final StudyTask task;
      switch (_mode) {
        case _TimeMode.none:
          task = common.copyWith(autoScheduled: false, clearTimes: true);
        case _TimeMode.manual:
          task = common.copyWith(
            autoScheduled: false,
            startMinute: start,
            endMinute: start! + _duration,
            durationMinutes: _duration,
          );
        case _TimeMode.auto:
          // The repository places it (after the previous item) and fills in
          // the start/end from the duration.
          task = common.copyWith(
            autoScheduled: true,
            durationMinutes: _duration,
          );
      }
      final repo = ref.read(studyHubRepositoryProvider);
      if (_repeat && widget.existing == null && _mode == _TimeMode.manual && !_split) {
        final RepeatSaveResult res = await repo.createRepeatingSessions(
          seriesId: _seriesId,
          template: task,
          weekdays: _repeatDays,
          startDay: targetDay,
          untilDay: untilAfterWeeks(targetDay, _repeatWeeks),
          breakMinutes: _addBreak ? _breakMinutes : null,
        );
        if (res.created == 0) {
          setState(() => _error = 'Nothing was added: that time is already taken on '
              '${res.skippedDays.length} of the chosen days.');
          return;
        }
        if (!mounted) return;
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(
              'Added ${res.created} ${res.created == 1 ? 'session' : 'sessions'}'
              '${res.skippedDays.isEmpty ? '' : '. Skipped ${res.skippedDays.length} (time already taken): ${res.skippedDays.take(3).map(_shortDay).join(', ')}${res.skippedDays.length > 3 ? '…' : ''}'}',
            ),
          ));
        return;
      }
      if (_split && widget.existing == null && _mode != _TimeMode.none) {
        await repo.saveSessionAsBlocks(
          session: task,
          focusMinutes: _blockPresets[_preset].$1,
          breakMinutes: _blockPresets[_preset].$2,
        );
      } else {
        await repo.saveSessionWithBreak(
          session: task,
          breakId: _breakId,
          breakMinutes:
              (_addBreak && _mode != _TimeMode.none) ? _breakMinutes : null,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) setState(() => _error = _scheduleErrorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    // Everything on the day except this session and its own break.
    _next = StudyScheduleService.nextAvailableMinute(
      dayTasks.where((StudyTask t) =>
          t.id != _sessionId && t.id != _breakId && t.id != _existingBreak?.id),
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

    final bool canSplit = widget.existing == null && _mode != _TimeMode.none;
    final bool splitting = canSplit && _split;
    final PomodoroPlan? plan = splitting
        ? planPomodoroWindow(
            totalWindowMinutes: _duration,
            focusMinutes: _blockPresets[_preset].$1,
            breakMinutes: _blockPresets[_preset].$2,
          )
        : null;
    final int? start = _startFor();
    final int? end =
        start == null ? null : start + (plan?.windowMinutes ?? _duration);
    final bool pastMidnight = end != null && end > 24 * 60;

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
            const SizedBox(height: 20),
            Text('When', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<_TimeMode>(
              showSelectedIcon: false,
              segments: <ButtonSegment<_TimeMode>>[
                for (final _TimeMode m in _TimeMode.values)
                  ButtonSegment<_TimeMode>(value: m, label: Text(m.label)),
              ],
              selected: <_TimeMode>{_mode},
              onSelectionChanged: (Set<_TimeMode> s) => setState(() {
                final _TimeMode next = s.first;
                if (next == _TimeMode.manual && _mode != _TimeMode.manual) {
                  _start = _startFor() ?? _next;
                }
                if (next == _TimeMode.none) _addBreak = false;
                _mode = next;
                _error = null;
              }),
            ),
            const SizedBox(height: 4),
            Text(
              switch (_mode) {
                _TimeMode.auto =>
                  'Starts right after your last item of the day, and moves '
                      'automatically if earlier items change.',
                _TimeMode.manual => 'Choose exactly when this session starts.',
                _TimeMode.none =>
                  'No time: it stays on your list without a place on the '
                      'timeline and sends no reminder.',
              },
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (start != null && end != null) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickStart(start),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text('Start  ${formatMinuteOfDay(start)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: splitting ? null : () => _pickEnd(start, end),
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: Text('End  ${formatMinuteOfDay(end % (24 * 60))}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('How long?', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              _DurationPicker(
                minutes: _duration,
                options: const <int>[30, 45, 60, 90, 120],
                onChanged: (int m) => setState(() {
                  _duration = m;
                  _error = null;
                }),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  pastMidnight
                      ? '${formatMinuteOfDay(start)} → past midnight. Choose an earlier start or a shorter time.'
                      : '${formatMinuteOfDay(start)} → ${formatMinuteOfDay(end)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: pastMidnight
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (canSplit) ...<Widget>[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _split,
                onChanged: (bool v) => setState(() {
                  _split = v;
                  if (v) _repeat = false;
                  _error = null;
                }),
                title: const Text('Split into focus blocks'),
                subtitle: Text(
                  plan == null
                      ? 'Pomodoro style: study in blocks with short breaks in between.'
                      : plan.breaks == 0
                          ? 'Too short to split: this stays one block.'
                          : '${plan.summary} min  ·  ${plan.focusBlocks} blocks, ${plan.breaks} breaks',
                ),
              ),
              if (_split)
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (int i = 0; i < _blockPresets.length; i++)
                      ChoiceChip(
                        label: Text('${_blockPresets[i].$1} + ${_blockPresets[i].$2} min'),
                        selected: _preset == i,
                        onSelected: (_) => setState(() => _preset = i),
                      ),
                  ],
                ),
            ],
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _addBreak && _mode != _TimeMode.none && !splitting,
              onChanged: (_mode == _TimeMode.none || splitting)
                  ? null
                  : (bool v) => setState(() => _addBreak = v),
              title: const Text('Add a break right after this session'),
              subtitle: Text(
                _mode == _TimeMode.none
                    ? 'A break needs a time — choose “After previous” or “Set time”.'
                    : splitting
                        ? 'Not needed: breaks are already between the focus blocks.'
                        : (_addBreak && end != null
                            ? 'Break ${formatMinuteOfDay(end)} → ${formatMinuteOfDay((end + _breakMinutes) % (24 * 60))}'
                            : 'Creates it in the same step'),
              ),
            ),
            if (_addBreak && _mode != _TimeMode.none && !splitting)
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
            if (widget.existing == null && _mode != _TimeMode.none) ...<Widget>[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _repeat,
                onChanged: splitting
                    ? null
                    : (bool v) => setState(() {
                        _repeat = v;
                        _error = null;
                        if (v && _mode != _TimeMode.manual) {
                          // A repeating session needs a fixed time.
                          _start = _startFor() ?? _next;
                          _mode = _TimeMode.manual;
                        }
                      }),
                title: const Text('Repeat weekly'),
                subtitle: Text(
                  splitting
                      ? 'Not available with focus blocks.'
                      : _repeat
                          ? 'Adds this session on the chosen days (at a fixed time)'
                          : 'For example every Monday and Wednesday',
                ),
              ),
              if (_repeat) ...<Widget>[
                Wrap(
                  spacing: 6,
                  children: <Widget>[
                    for (int d = 1; d <= 7; d++)
                      FilterChip(
                        label: Text(weekdayShort[d - 1]),
                        selected: _repeatDays.contains(d),
                        onSelected: (bool v) => setState(() {
                          if (v) {
                            _repeatDays.add(d);
                          } else if (_repeatDays.length > 1) {
                            _repeatDays.remove(d);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final int w in const <int>[4, 8, 12, 16])
                      ChoiceChip(
                        label: Text('$w weeks'),
                        selected: _repeatWeeks == w,
                        onSelected: (_) => setState(() => _repeatWeeks = w),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    () {
                      final List<String> days = occurrenceDays(
                        weekdays: _repeatDays,
                        startDay: widget.day,
                        untilDay: untilAfterWeeks(widget.day, _repeatWeeks),
                      );
                      return '${describeWeekdays(_repeatDays)} · ${days.length} '
                          '${days.length == 1 ? 'session' : 'sessions'}'
                          '${days.isEmpty ? '' : ' until ${_shortDay(days.last)}'}';
                    }(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
            if (_error != null) _ErrorBanner(_error!),
            Row(
              children: <Widget>[
                if (widget.existing != null)
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
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
                FilledButton.icon(
                  onPressed: (_saving || pastMidnight) ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Saving…' : 'Save'),
                ),
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
  late final String _id = widget.existing?.id ?? const Uuid().v4();
  late int? _start = widget.existing?.startMinute;
  late int _duration = widget.existing == null
      ? 15
      : StudyScheduleService.durationOf(widget.existing!);
  int _next = StudyScheduleService.defaultDayStartMinute;
  bool _saving = false;
  String? _error;

  static const List<String> _presets = <String>[
    'Tea Break', 'Lunch', 'Prayer', 'Walk', 'Rest',
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int get _startValue => _start ?? _next;

  Future<void> _pickStart() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDay(_startValue),
      helpText: 'START TIME',
    );
    if (picked == null) return;
    setState(() {
      _start = picked.hour * 60 + picked.minute;
      _error = null;
    });
  }

  Future<void> _pickEnd() async {
    final int start = _startValue;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDay(start + _duration),
      helpText: 'END TIME',
    );
    if (picked == null) return;
    final int end = picked.hour * 60 + picked.minute;
    setState(() {
      if (end <= start) {
        _error = 'The end time must be after the start time '
            '(${formatMinuteOfDay(start)}).';
      } else {
        _duration = end - start;
        _error = null;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name for the break.');
      return;
    }
    final int start = _startValue;
    final int end = start + _duration;
    final String? problem = StudyScheduleService.validateSpan(start, end);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final DateTime now = DateTime.now();
      final StudyTask base = widget.existing ??
          StudyTask(
            id: _id,
            day: widget.day,
            title: name,
            createdAt: now,
            updatedAt: now,
          );
      final StudyTask task = base.copyWith(
        title: name,
        startMinute: start,
        endMinute: end,
        kind: SessionKind.breakTime,
        status: TaskStatus.pending,
        durationMinutes: _duration,
        // Editing a break is an explicit user action, so preserve its chosen
        // time instead of letting automatic scheduling move it elsewhere.
        autoScheduled: false,
        updatedAt: now,
        clearSubject: true,
        clearTopic: true,
      );
      await ref.read(studyHubRepositoryProvider).saveTask(task);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) setState(() => _error = _scheduleErrorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    _next = StudyScheduleService.nextAvailableMinute(
      dayTasks.where((StudyTask t) => t.id != _id),
    );
    final int start = _startValue;
    final int end = start + _duration;
    final bool pastMidnight = end > 24 * 60;

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
                    onPressed: _pickStart,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text('Start  ${formatMinuteOfDay(start)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEnd,
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: Text('End  ${formatMinuteOfDay(end % (24 * 60))}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('How long?', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            _DurationPicker(
              minutes: _duration,
              options: const <int>[5, 10, 15, 20, 30],
              onChanged: (int m) => setState(() {
                _duration = m;
                _error = null;
              }),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                pastMidnight
                    ? 'This runs past midnight. Choose an earlier start or a shorter break.'
                    : '${formatMinuteOfDay(start)} → ${formatMinuteOfDay(end)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: pastMidnight
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null) _ErrorBanner(_error!),
            Row(
              children: <Widget>[
                if (widget.existing != null)
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
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
                FilledButton.icon(
                  onPressed: (_saving || pastMidnight) ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Saving…' : 'Save'),
                ),
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

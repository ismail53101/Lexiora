import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_subject.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';
import 'package:lexiora/modules/study_hub/domain/planning/day_planner.dart';
import 'package:lexiora/modules/study_hub/domain/planning/plan_inputs.dart';
import 'package:lexiora/modules/study_hub/domain/scheduling/study_schedule_service.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:uuid/uuid.dart';

const List<(int, int)> _styles = <(int, int)>[(25, 5), (50, 10), (90, 15)];

/// Pick your free time and subjects; the planner fills the gaps with focus
/// sessions and breaks. Nothing is saved until you tap "Add to my day".
class PlanDayPage extends ConsumerStatefulWidget {
  const PlanDayPage({super.key, required this.day});

  final String day;

  @override
  ConsumerState<PlanDayPage> createState() => _PlanDayPageState();
}

class _PlanDayPageState extends ConsumerState<PlanDayPage> {
  static const Uuid _uuid = Uuid();

  late int _start;
  late int _end;
  int _style = 1;
  Set<String>? _selected; // lower-cased subject names
  DayPlan? _plan;
  List<String> _ids = <String>[];
  final Set<int> _removed = <int>{};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    if (widget.day == dayKey(now)) {
      final int s = (((now.hour * 60 + now.minute) + 14) ~/ 15) * 15;
      _start = s.clamp(0, 23 * 60);
      _end = 21 * 60;
      if (_start >= _end - 30) _end = (_start + 3 * 60).clamp(0, 24 * 60);
    } else {
      _start = 9 * 60;
      _end = 17 * 60;
    }
  }

  TimeOfDay _tod(int m) => TimeOfDay(hour: (m ~/ 60).clamp(0, 23), minute: m % 60);

  Future<void> _pick({required bool start}) async {
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: _tod(start ? _start : _end),
      helpText: start ? 'FREE FROM' : 'FREE UNTIL',
    );
    if (t == null) return;
    setState(() {
      if (start) {
        _start = t.hour * 60 + t.minute;
      } else {
        _end = t.hour * 60 + t.minute;
      }
      _plan = null;
      _error = null;
    });
  }

  List<MinuteRange> _busy(List<StudyTask> tasks) => <MinuteRange>[
        for (final StudyTask t in tasks)
          if (t.startMinute != null && t.endMinute != null)
            MinuteRange(t.startMinute!, t.endMinute!),
      ];

  void _generate(List<StudyTask> tasks, List<PlanCandidate> cands) {
    final String? problem = _end <= _start ? 'The end time must be after the start time.' : null;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final List<PlanSubject> subjects = <PlanSubject>[
      for (final PlanCandidate c in cands)
        if ((_selected ?? <String>{}).contains(c.subject.name.toLowerCase())) c.subject,
    ];
    final DayPlan plan = planDay(
      window: MinuteRange(_start, _end),
      busy: _busy(tasks),
      subjects: subjects,
      settings: PlanSettings(focusMinutes: _styles[_style].$1, breakMinutes: _styles[_style].$2),
    );
    setState(() {
      _plan = plan;
      _ids = <String>[for (int i = 0; i < plan.items.length; i++) _uuid.v4()];
      _removed.clear();
      _error = null;
    });
  }

  /// Removes block [i] and the break next to it, so no lonely break is left.
  void _remove(int i) {
    final List<PlannedItem> items = _plan!.items;
    setState(() {
      _removed.add(i);
      if (i + 1 < items.length && !items[i + 1].isFocus) {
        _removed.add(i + 1);
      } else if (i - 1 >= 0 && !items[i - 1].isFocus) {
        _removed.add(i - 1);
      }
    });
  }

  Future<void> _save() async {
    final DayPlan? plan = _plan;
    if (plan == null || _saving) return;
    final DateTime now = DateTime.now();
    final List<StudyTask> rows = <StudyTask>[
      for (int i = 0; i < plan.items.length; i++)
        if (!_removed.contains(i))
          StudyTask(
            id: _ids[i],
            day: widget.day,
            title: plan.items[i].isFocus ? plan.items[i].subject! : 'Break',
            subject: plan.items[i].isFocus ? plan.items[i].subject : null,
            topic: plan.items[i].topic,
            kind: plan.items[i].isFocus ? SessionKind.session : SessionKind.breakTime,
            startMinute: plan.items[i].start,
            endMinute: plan.items[i].end,
            durationMinutes: plan.items[i].minutes,
            createdAt: now,
            updatedAt: now,
          ),
    ];
    if (rows.isEmpty) {
      setState(() => _error = 'Nothing to add: every block was removed.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final int n = await ref.read(studyHubRepositoryProvider).saveGeneratedPlan(day: widget.day, items: rows);
      if (!mounted) return;
      final int blocks = rows.where((StudyTask t) => !t.isBreak).length;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Added $blocks ${blocks == 1 ? 'session' : 'sessions'} to your day ($n items)')));
      Navigator.of(context).pop();
    } on StudyScheduleOverlapException {
      setState(() => _error = 'This overlaps something you added meanwhile. Generate the plan again.');
    } on Object catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _dur(int m) => m % 60 == 0 ? '${m ~/ 60} h' : (m < 60 ? '$m min' : '${m ~/ 60} h ${m % 60} min');

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final List<StudyTask> tasks = ref.watch(studyDayTasksProvider(widget.day)).maybeWhen(
          data: (List<StudyTask> t) => t,
          orElse: () => const <StudyTask>[],
        );
    final List<StudySubject> registered = ref.watch(subjectsProvider(false)).maybeWhen(
          data: (List<StudySubject> s) => s,
          orElse: () => const <StudySubject>[],
        );
    final List<String> suggestions = ref.watch(subjectSuggestionsProvider).maybeWhen(
          data: (List<String> s) => s,
          orElse: () => const <String>[],
        );
    final List<ExamCountdown> countdowns = ref.watch(examCountdownsProvider).asData?.value ?? const <ExamCountdown>[];
    final List<SubjectSyllabus> syllabi = ref.watch(syllabiProvider).asData?.value ?? const <SubjectSyllabus>[];
    final Map<String, String> last = ref.watch(lastStudiedDaysProvider).asData?.value ?? const <String, String>{};
    final Map<String, int> colors = ref.watch(subjectColorsProvider).asData?.value ?? const <String, int>{};

    final List<PlanCandidate> cands = buildPlanCandidates(
      subjectNames: <String>[for (final StudySubject s in registered) s.name, ...suggestions],
      countdowns: countdowns,
      syllabi: syllabi,
      lastStudiedDay: last,
      now: DateTime.now(),
    );
    _selected ??= cands.isEmpty
        ? null
        : <String>{for (final PlanCandidate c in cands) if (c.suggested) c.subject.name.toLowerCase()};

    final List<MinuteRange> gaps = freeGaps(MinuteRange(_start, _end), _busy(tasks));
    final int freeMinutes = gaps.fold(0, (int s, MinuteRange g) => s + g.length);
    final DayPlan? plan = _plan;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan my day')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Text('When are you free?', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(start: true),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text('From  ${formatMinuteOfDay(_start)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(start: false),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text('Until  ${formatMinuteOfDay(_end)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _end <= _start
                ? 'The end must be after the start.'
                : '${_dur(freeMinutes)} free${tasks.any((StudyTask t) => t.startMinute != null) ? ' (around what is already planned)' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _end <= _start ? cs.error : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Text('Study style', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (int i = 0; i < _styles.length; i++)
                ChoiceChip(
                  label: Text('${_styles[i].$1} min + ${_styles[i].$2} break'),
                  selected: _style == i,
                  onSelected: (_) => setState(() {
                    _style = i;
                    _plan = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(child: Text('Subjects', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
              if (cands.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    final Set<String> all = <String>{for (final PlanCandidate c in cands) c.subject.name.toLowerCase()};
                    _selected = (_selected ?? <String>{}).length == all.length ? <String>{} : all;
                    _plan = null;
                  }),
                  child: Text((_selected ?? <String>{}).length == cands.length ? 'Clear' : 'Select all'),
                ),
            ],
          ),
          if (cands.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'You have no subjects yet. Add a subject or plan a session first, then come back.',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else
            for (final PlanCandidate c in cands)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: (_selected ?? <String>{}).contains(c.subject.name.toLowerCase()),
                onChanged: (bool? v) => setState(() {
                  final Set<String> s = _selected ?? <String>{};
                  final String k = c.subject.name.toLowerCase();
                  if (v ?? false) {
                    s.add(k);
                  } else {
                    s.remove(k);
                  }
                  _selected = s;
                  _plan = null;
                }),
                secondary: CircleAvatar(
                  radius: 6,
                  backgroundColor: colors[c.subject.name.toLowerCase()] == null ? cs.primary : Color(colors[c.subject.name.toLowerCase()]!),
                ),
                title: Text(c.subject.name),
                subtitle: c.subject.reason.isEmpty ? null : Text(c.subject.reason),
              ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: cands.isEmpty || (_selected ?? <String>{}).isEmpty ? null : () => _generate(tasks, cands),
            icon: const Icon(Icons.auto_awesome),
            label: Text(plan == null ? 'Make my plan' : 'Make it again'),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: TextStyle(color: cs.onErrorContainer)),
            ),
          ],
          if (plan != null) ...<Widget>[
            const SizedBox(height: 24),
            if (plan.isEmpty)
              Text(
                'No room for a study block in that time. Try a longer window or a shorter study style.',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              )
            else ...<Widget>[
              Text('Your plan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(
                '${_dur(plan.focusMinutes)} of focus in ${plan.blocks.length} ${plan.blocks.length == 1 ? 'block' : 'blocks'}'
                '${plan.freeMinutesLeft > 0 ? ' · ${_dur(plan.freeMinutesLeft)} left free' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < plan.items.length; i++)
                if (!_removed.contains(i))
                  plan.items[i].isFocus
                      ? _BlockTile(
                          item: plan.items[i],
                          color: colors[(plan.items[i].subject ?? '').toLowerCase()] == null
                              ? cs.primary
                              : Color(colors[(plan.items[i].subject ?? '').toLowerCase()]!),
                          onRemove: () => _remove(i),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.free_breakfast_outlined, size: 16, color: cs.outline),
                              const SizedBox(width: 8),
                              Text(
                                'Break  ${formatMinuteOfDay(plan.items[i].start)} – ${formatMinuteOfDay(plan.items[i].end)}',
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                              ),
                            ],
                          ),
                        ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Adding…' : 'Add to my day'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({required this.item, required this.color, required this.onRemove});
  final PlannedItem item;
  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: <Widget>[
            Container(width: 5, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${formatMinuteOfDay(item.start)} – ${formatMinuteOfDay(item.end)}  ·  ${item.minutes} min',
                      style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  Text(item.subject ?? '', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  if (item.topic != null)
                    Text(item.topic!, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(tooltip: 'Remove this block', icon: const Icon(Icons.close), onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}

/// Entry point shown in the daily planner.
class PlanMyDayCard extends StatelessWidget {
  const PlanMyDayCard({super.key, required this.day});
  final String day;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: cs.primaryContainer.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(Icons.auto_awesome, color: cs.onPrimaryContainer),
        title: Text('Plan my day', style: TextStyle(fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)),
        subtitle: Text('Fill your free time with the right subjects', style: TextStyle(color: cs.onPrimaryContainer)),
        trailing: Icon(Icons.chevron_right, color: cs.onPrimaryContainer),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (BuildContext c) => PlanDayPage(day: day)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner/planner_common.dart';

const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _weekdaysFull = <String>[
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

DateTime _mondayOf(DateTime d) {
  final DateTime day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// The Weekly tab: `< May 12 – May 18 >` header, a day strip, then seven
/// collapsible day cards (tap the chevron to expand/collapse; the
/// selected/today day starts expanded) — matches the mockup closely while
/// staying much more compact than a full always-expanded week.
class PlannerWeeklyView extends StatefulWidget {
  const PlannerWeeklyView({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  State<PlannerWeeklyView> createState() => PlannerWeeklyViewState();
}

class PlannerWeeklyViewState extends State<PlannerWeeklyView> {
  late DateTime _selected = widget.initialDate ?? DateTime.now();

  void _shiftWeek(int weeks) =>
      setState(() => _selected = _selected.add(Duration(days: 7 * weeks)));

  void selectDate(DateTime d) => setState(() => _selected = d);

  @override
  Widget build(BuildContext context) {
    final DateTime weekStart = _mondayOf(_selected);
    final DateTime weekEnd = weekStart.add(const Duration(days: 6));
    final String label = '${_months[weekStart.month - 1]} ${weekStart.day} – '
        '${_months[weekEnd.month - 1]} ${weekEnd.day}';
    final String selectedKey = dayKey(_selected);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        PlannerNavHeader(
          label: label,
          onPrevious: () => _shiftWeek(-1),
          onNext: () => _shiftWeek(1),
        ),
        const SizedBox(height: 8),
        PlannerWeekStrip(
          weekStart: weekStart,
          selected: _selected,
          onSelect: (DateTime d) => setState(() => _selected = d),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < 7; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DayCard(
              key: ValueKey<String>(dayKey(weekStart.add(Duration(days: i)))),
              day: weekStart.add(Duration(days: i)),
              weekdayLabel: _weekdaysFull[i],
              initiallyExpanded: dayKey(weekStart.add(Duration(days: i))) == selectedKey,
            ),
          ),
      ],
    );
  }
}

class _DayCard extends ConsumerStatefulWidget {
  const _DayCard({
    super.key,
    required this.day,
    required this.weekdayLabel,
    required this.initiallyExpanded,
  });

  final DateTime day;
  final String weekdayLabel;
  final bool initiallyExpanded;

  @override
  ConsumerState<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends ConsumerState<_DayCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(covariant _DayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded && !oldWidget.initiallyExpanded) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String key = dayKey(widget.day);
    final bool isToday = key == todayKey();
    final List<StudyTask> tasks = ref.watch(studyDayTasksProvider(key)).maybeWhen(
          data: (List<StudyTask> t) => t,
          orElse: () => const <StudyTask>[],
        );
    final int sessionCount = tasks.where((StudyTask t) => !t.isBreak).length;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: '${widget.weekdayLabel}, ${widget.day.day} '
                                '${_months[widget.day.month - 1]}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isToday ? theme.colorScheme.primary : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$sessionCount Tasks',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: tasks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text('No sessions',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    )
                  : Column(
                      children: <Widget>[
                        for (int i = 0; i < tasks.length; i++)
                          PlannerTaskRow(
                            task: tasks[i],
                            showConnectorTop: i > 0,
                            showConnectorBottom: i < tasks.length - 1,
                            dense: true,
                          ),
                      ],
                    ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

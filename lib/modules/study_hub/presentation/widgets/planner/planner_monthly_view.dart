import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner/planner_common.dart';

const List<String> _months = <String>[
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];
const List<String> _dowShort = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const Color _kCompletedColor = Color(0xFF22C55E);
const Color _kPendingColor = Color(0xFF38BDF8);
const Color _kOverdueColor = Color(0xFFF43F5E);

/// The Monthly tab: a calendar with per-day coloured dots, a Total /
/// Completed / Pending / Overdue stats grid, a Day Overview list for the
/// selected date, and a Monthly Progress donut.
class PlannerMonthlyView extends StatefulWidget {
  const PlannerMonthlyView({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  State<PlannerMonthlyView> createState() => PlannerMonthlyViewState();
}

class PlannerMonthlyViewState extends State<PlannerMonthlyView> {
  late DateTime _month = DateTime(
    (widget.initialDate ?? DateTime.now()).year,
    (widget.initialDate ?? DateTime.now()).month,
  );
  late DateTime _selected = widget.initialDate ?? DateTime.now();

  void _shiftMonth(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  void selectDate(DateTime d) =>
      setState(() {
        _selected = d;
        _month = DateTime(d.year, d.month);
      });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final DateTime lastDay = DateTime(_month.year, _month.month, daysInMonth);
    final String today = todayKey();

    return Consumer(builder: (BuildContext context, WidgetRef ref, _) {
      final List<StudyTask> monthTasks = ref
          .watch(studyRangeTasksProvider('${dayKey(_month)}|${dayKey(lastDay)}'))
          .maybeWhen(data: (List<StudyTask> t) => t, orElse: () => const <StudyTask>[]);
      final Map<String, int> colors = ref.watch(subjectColorsProvider).maybeWhen(
          data: (Map<String, int> m) => m, orElse: () => const <String, int>{});

      final Map<String, List<Color>> dayColors = <String, List<Color>>{};
      int total = 0, completed = 0, overdue = 0;
      for (final StudyTask t in monthTasks) {
        if (t.isBreak) continue;
        total++;
        if (t.completed) {
          completed++;
        } else if (t.day.compareTo(today) < 0) {
          overdue++;
        }
        final List<Color> list = dayColors.putIfAbsent(t.day, () => <Color>[]);
        final Color c = resolveSubjectColor(t.displaySubject, colors);
        if (!list.contains(c) && list.length < 3) list.add(c);
      }
      final int pending = total - completed - overdue;
      final int pct = total == 0 ? 0 : ((completed / total) * 100).round();

      final String selectedKey = dayKey(_selected);
      final List<StudyTask> dayTasks =
          monthTasks.where((StudyTask t) => t.day == selectedKey).toList();

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: <Widget>[
          PlannerNavHeader(
            label: '${_months[_month.month - 1]} ${_month.year}',
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: 8),
          _Calendar(
            month: _month,
            selected: _selected,
            dayColors: dayColors,
            onSelect: (DateTime d) => setState(() => _selected = d),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: <Widget>[
              PlannerStatCard(
                icon: Icons.assignment_outlined,
                label: 'Total Tasks',
                value: '$total',
                color: theme.colorScheme.primary,
              ),
              PlannerStatCard(
                icon: Icons.check_circle_outline,
                label: 'Completed',
                value: '$completed',
                color: _kCompletedColor,
              ),
              PlannerStatCard(
                icon: Icons.pending_actions_outlined,
                label: 'Pending',
                value: '$pending',
                color: _kPendingColor,
              ),
              PlannerStatCard(
                icon: Icons.error_outline,
                label: 'Overdue',
                value: '$overdue',
                color: _kOverdueColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Day Overview',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '${_weekdayFull(_selected)}, ${_selected.day} ${_months[_selected.month - 1]} ${_selected.year}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (dayTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('No sessions for this day.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            )
          else
            for (int i = 0; i < dayTasks.length; i++)
              PlannerTaskRow(
                task: dayTasks[i],
                showConnectorTop: i > 0,
                showConnectorBottom: i < dayTasks.length - 1,
              ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Monthly Progress',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    PlannerDonut(
                      segments: <DonutSegment>[
                        DonutSegment(value: completed.toDouble(), color: _kCompletedColor),
                        DonutSegment(value: pending.toDouble(), color: _kPendingColor),
                        DonutSegment(value: overdue.toDouble(), color: _kOverdueColor),
                      ],
                      centerValue: '$pct%',
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          PlannerLegendRow(
                            color: _kCompletedColor,
                            label: 'Completed',
                            count: completed,
                            percent: total == 0 ? 0 : ((completed / total) * 100).round(),
                          ),
                          PlannerLegendRow(
                            color: _kPendingColor,
                            label: 'Pending',
                            count: pending,
                            percent: total == 0 ? 0 : ((pending / total) * 100).round(),
                          ),
                          PlannerLegendRow(
                            color: _kOverdueColor,
                            label: 'Overdue',
                            count: overdue,
                            percent: total == 0 ? 0 : ((overdue / total) * 100).round(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AddTaskButton(day: selectedKey),
        ],
      );
    });
  }

  static const List<String> _fullDow = <String>[
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  String _weekdayFull(DateTime d) => _fullDow[d.weekday - 1];
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.selected,
    required this.dayColors,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Map<String, List<Color>> dayColors;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int leading = DateTime(month.year, month.month).weekday - 1; // Mon=0
    final int cells = leading + daysInMonth;
    final int rows = (cells / 7.0).ceil();
    final String todayK = todayKey();

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final String d in _dowShort)
              Expanded(
                child: Center(
                  child: Text(d,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (int r = 0; r < rows; r++)
          Row(
            children: <Widget>[
              for (int c = 0; c < 7; c++)
                Expanded(child: _cell(context, r * 7 + c - leading + 1, todayK)),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, int dayNum, String todayK) {
    final ThemeData theme = Theme.of(context);
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
    }
    final DateTime date = DateTime(month.year, month.month, dayNum);
    final String key = dayKey(date);
    final bool isSelected = key == dayKey(selected);
    final bool isToday = key == todayK;
    final List<Color> cols = dayColors[key] ?? const <Color>[];

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: isSelected
              ? theme.colorScheme.primary
              : (isToday
                  ? theme.colorScheme.primary.withValues(alpha: 0.14)
                  : Colors.transparent),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onSelect(date),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('$dayNum',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : (isToday ? theme.colorScheme.primary : null),
                    )),
                const SizedBox(height: 3),
                SizedBox(
                  height: 6,
                  child: cols.isEmpty
                      ? const SizedBox.shrink()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            for (final Color c in cols)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? theme.colorScheme.onPrimary : c,
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

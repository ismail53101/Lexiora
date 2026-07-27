import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/day_planner_section.dart';

const List<String> _months = <String>[
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];
const List<String> _dowShort = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// A true monthly planner: a calendar; any date holds unlimited sessions.
class MonthlyPlannerPage extends ConsumerStatefulWidget {
  const MonthlyPlannerPage({super.key});

  @override
  ConsumerState<MonthlyPlannerPage> createState() => _MonthlyPlannerPageState();
}

class _MonthlyPlannerPageState extends ConsumerState<MonthlyPlannerPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = DateTime.now();

  void _shiftMonth(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final DateTime lastDay = DateTime(_month.year, _month.month, daysInMonth);
    final List<StudyTask> monthTasks = ref
        .watch(studyRangeTasksProvider('${dayKey(_month)}|${dayKey(lastDay)}'))
        .maybeWhen(
            data: (List<StudyTask> t) => t, orElse: () => const <StudyTask>[]);
    final Map<String, int> colors = ref.watch(subjectColorsProvider).maybeWhen(
        data: (Map<String, int> m) => m, orElse: () => const <String, int>{});
    // Per-day distinct subject colours (up to 3) + any-activity flag.
    final Map<String, List<int>> dayColors = <String, List<int>>{};
    final Set<String> daysWithData = <String>{};
    for (final StudyTask t in monthTasks) {
      daysWithData.add(t.day);
      if (t.isBreak) continue;
      final int? argb = colors[t.displaySubject.toLowerCase()];
      if (argb == null) continue;
      final List<int> list = dayColors.putIfAbsent(t.day, () => <int>[]);
      if (!list.contains(argb) && list.length < 3) list.add(argb);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Planner'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: <Widget>[
                IconButton(
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text('${_months[_month.month - 1]} ${_month.year}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: <Widget>[
          _Calendar(
            month: _month,
            selected: _selected,
            daysWithData: daysWithData,
            dayColors: dayColors,
            onSelect: (DateTime d) => setState(() => _selected = d),
          ),
          const Divider(height: 28),
          DayPlannerSection(
            day: dayKey(_selected),
            title: '${_months[_selected.month - 1]} ${_selected.day}, '
                '${_selected.year}',
            highlight: dayKey(_selected) == todayKey(),
          ),
        ],
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.selected,
    required this.daysWithData,
    required this.dayColors,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Set<String> daysWithData;
  final Map<String, List<int>> dayColors;
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
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (int r = 0; r < rows; r++)
          Row(
            children: <Widget>[
              for (int c = 0; c < 7; c++)
                Expanded(child: _cell(theme, r * 7 + c - leading + 1, todayK)),
            ],
          ),
      ],
    );
  }

  Widget _cell(ThemeData theme, int dayNum, String todayK) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
    }
    final DateTime date = DateTime(month.year, month.month, dayNum);
    final String key = dayKey(date);
    final bool isSelected = key == dayKey(selected);
    final bool isToday = key == todayK;
    final bool hasData = daysWithData.contains(key);
    final List<int> cols = dayColors[key] ?? const <int>[];

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: isSelected
              ? theme.colorScheme.primary
              : (isToday
                  ? theme.colorScheme.primaryContainer
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
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : (isToday
                              ? theme.colorScheme.onPrimaryContainer
                              : null),
                    )),
                const SizedBox(height: 3),
                SizedBox(
                  height: 6,
                  child: cols.isNotEmpty
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            for (final int c in cols)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : Color(c),
                                ),
                              ),
                          ],
                        )
                      : (hasData
                          ? Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                              ),
                            )
                          : const SizedBox.shrink()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

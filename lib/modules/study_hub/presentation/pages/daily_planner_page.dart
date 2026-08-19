import 'package:flutter/material.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/day_planner_section.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner_view_tabs.dart';

const List<String> _weekdayShort = <String>[
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];
const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Browse and plan a single day, with a tappable week date-strip up top
/// (like a calendar strip) instead of picking a date from a text field —
/// tap any day to jump straight to it, or use the arrows to shift a week
/// at a time. Shares [DayPlannerSection] with the Weekly/Monthly planners,
/// so add/edit/complete behaviour is identical everywhere.
class DailyPlannerPage extends StatefulWidget {
  const DailyPlannerPage({super.key});

  @override
  State<DailyPlannerPage> createState() => _DailyPlannerPageState();
}

class _DailyPlannerPageState extends State<DailyPlannerPage> {
  late DateTime _selected = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  void _shiftWeek(int weeks) => setState(() {
        _selected = _selected.add(Duration(days: 7 * weeks));
      });

  void _select(DateTime d) => setState(() => _selected = d);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime weekStart = _mondayOf(_selected);
    final DateTime today = _dateOnly(DateTime.now());
    final bool isToday = _selected == today;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Planner'),
        bottom: const PlannerViewTabs(current: PlannerView.daily),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => _shiftWeek(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    isToday
                        ? 'Today · ${_months[_selected.month - 1]} ${_selected.day}'
                        : '${_weekdayShort[_selected.weekday - 1]}, '
                            '${_months[_selected.month - 1]} ${_selected.day}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => _shiftWeek(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: <Widget>[
                for (int i = 0; i < 7; i++)
                  Expanded(
                    child: _DateChip(
                      date: weekStart.add(Duration(days: i)),
                      label: _weekdayShort[i],
                      selected: weekStart.add(Duration(days: i)) == _selected,
                      isToday: weekStart.add(Duration(days: i)) == today,
                      onTap: () => _select(weekStart.add(Duration(days: i))),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: DayPlannerSection(
                day: dayKey(_selected),
                title: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable day pill in the week date-strip — weekday letters + day
/// number, filled when selected, a thin ring when it's today but not
/// selected. Compact enough that the whole week fits without scrolling.
class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.label,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final String label;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: selected ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: (!selected && isToday)
                  ? Border.all(color: scheme.primary, width: 1.4)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? scheme.onPrimary.withValues(alpha: 0.8)
                          : scheme.onSurfaceVariant,
                    )),
                const SizedBox(height: 2),
                Text('${date.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? scheme.onPrimary : null,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

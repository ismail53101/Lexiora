import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/day_planner_section.dart';

const List<String> _weekdays = <String>[
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Plan the whole week: seven days, each with unlimited sessions and breaks.
class WeeklyPlannerPage extends ConsumerStatefulWidget {
  const WeeklyPlannerPage({super.key});

  @override
  ConsumerState<WeeklyPlannerPage> createState() => _WeeklyPlannerPageState();
}

class _WeeklyPlannerPageState extends ConsumerState<WeeklyPlannerPage> {
  late DateTime _weekStart = _mondayOf(DateTime.now());

  static DateTime _mondayOf(DateTime d) {
    final DateTime day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  void _shift(int weeks) =>
      setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));

  @override
  Widget build(BuildContext context) {
    final DateTime end = _weekStart.add(const Duration(days: 6));
    final String today = todayKey();
    final String label =
        '${_months[_weekStart.month - 1]} ${_weekStart.day} – '
        '${_months[end.month - 1]} ${end.day}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Planner'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () => _shift(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 7,
        separatorBuilder: (_, _) => const Divider(height: 28),
        itemBuilder: (BuildContext context, int i) {
          final DateTime d = _weekStart.add(Duration(days: i));
          final String key = dayKey(d);
          return DayPlannerSection(
            day: key,
            title: _weekdays[i],
            subtitle: '${_months[d.month - 1]} ${d.day}',
            highlight: key == today,
          );
        },
      ),
    );
  }
}

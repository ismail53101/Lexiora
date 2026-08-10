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
const List<String> _weekdaysShort = <String>[
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

DateTime _mondayOf(DateTime d) {
  final DateTime day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// The Daily tab: a day strip, `< Wed, 14 May >` header, and a vertical
/// timeline of that day's sessions/breaks with round coloured checkmarks.
class PlannerDailyView extends StatefulWidget {
  const PlannerDailyView({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  State<PlannerDailyView> createState() => PlannerDailyViewState();
}

class PlannerDailyViewState extends State<PlannerDailyView> {
  late DateTime _selected = widget.initialDate ?? DateTime.now();

  void _shiftDay(int days) =>
      setState(() => _selected = _selected.add(Duration(days: days)));

  void selectDate(DateTime d) => setState(() => _selected = d);

  @override
  Widget build(BuildContext context) {
    final String key = dayKey(_selected);
    final DateTime weekStart = _mondayOf(_selected);
    final String label =
        '${_weekdaysShort[_selected.weekday - 1]}, ${_selected.day} ${_months[_selected.month - 1]}';

    return Consumer(builder: (BuildContext context, WidgetRef ref, _) {
      final List<StudyTask> tasks = ref.watch(studyDayTasksProvider(key)).maybeWhen(
            data: (List<StudyTask> t) => t,
            orElse: () => const <StudyTask>[],
          );

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: <Widget>[
          PlannerNavHeader(
            label: label,
            onPrevious: () => _shiftDay(-1),
            onNext: () => _shiftDay(1),
          ),
          const SizedBox(height: 8),
          PlannerWeekStrip(
            weekStart: weekStart,
            selected: _selected,
            onSelect: (DateTime d) => setState(() => _selected = d),
          ),
          const SizedBox(height: 18),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No sessions planned for this day.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            for (int i = 0; i < tasks.length; i++)
              PlannerTaskRow(
                task: tasks[i],
                showConnectorTop: i > 0,
                showConnectorBottom: i < tasks.length - 1,
              ),
          const SizedBox(height: 12),
          AddTaskButton(day: key),
        ],
      );
    });
  }
}

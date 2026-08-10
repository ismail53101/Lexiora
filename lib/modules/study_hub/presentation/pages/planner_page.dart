import 'package:flutter/material.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner/planner_common.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner/planner_daily_view.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner/planner_monthly_view.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner/planner_weekly_view.dart';

enum PlannerTab { daily, weekly, monthly }

/// The redesigned unified Planner: Daily / Weekly / Monthly live behind one
/// segmented control instead of three separate screens, matching the new
/// mockups — colour-coded subjects, round checkmarks, a collapsible weekly
/// list and a monthly calendar with stats + a progress donut.
class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key, this.initialTab = PlannerTab.daily});
  final PlannerTab initialTab;

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  late int _tab = widget.initialTab.index;
  DateTime _focusedDate = DateTime.now();

  final GlobalKey<PlannerDailyViewState> _dailyKey = GlobalKey();
  final GlobalKey<PlannerWeeklyViewState> _weeklyKey = GlobalKey();
  final GlobalKey<PlannerMonthlyViewState> _monthlyKey = GlobalKey();

  Future<void> _jumpToDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _focusedDate = picked);
    _dailyKey.currentState?.selectDate(picked);
    _weeklyKey.currentState?.selectDate(picked);
    _monthlyKey.currentState?.selectDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Jump to date',
            onPressed: _jumpToDate,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: PlannerSegmentedControl(
              labels: const <String>['Daily', 'Weekly', 'Monthly'],
              selectedIndex: _tab,
              onChanged: (int i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: <Widget>[
                PlannerDailyView(key: _dailyKey, initialDate: _focusedDate),
                PlannerWeeklyView(key: _weeklyKey, initialDate: _focusedDate),
                PlannerMonthlyView(key: _monthlyKey, initialDate: _focusedDate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

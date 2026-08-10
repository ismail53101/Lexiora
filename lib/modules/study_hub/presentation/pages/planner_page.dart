import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/study_hub/presentation/pages/planner_menu_pages.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner/planner_common.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner/planner_daily_view.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner/planner_monthly_view.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner/planner_weekly_view.dart';

enum PlannerTab { daily, weekly, monthly }

/// The Study Planner home — a unified Daily / Weekly / Monthly planner.
///
/// Opening Study Planner lands on this screen: the pill-style segmented
/// control (Daily | Weekly | Monthly) sits at the top exactly like the
/// planner mockups and switches the three views below it in place. The ⋮
/// menu keeps every dashboard feature reachable — Study Timer, Progress,
/// Quick Actions, Templates, Manage Subjects and Export & Backup.
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

  void _pushPage(Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search & filter',
            onPressed: () => context.push(AppRoutes.studyHubSearch),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Jump to date',
            onPressed: _jumpToDate,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            elevation: 8,
            onSelected: (String v) {
              switch (v) {
                case 'timer':
                  _pushPage(const PlannerTimerPage());
                case 'progress':
                  _pushPage(const PlannerProgressPage());
                case 'quick':
                  _pushPage(const PlannerQuickActionsPage());
                case 'templates':
                  context.push(AppRoutes.studyHubTemplates);
                case 'subjects':
                  context.push(AppRoutes.studyHubSubjects);
                case 'export':
                  context.push(AppRoutes.studyHubExport);
              }
            },
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'timer', child: Text('Study Timer')),
              PopupMenuItem<String>(value: 'progress', child: Text('Progress')),
              PopupMenuItem<String>(
                  value: 'quick', child: Text('Quick Actions')),
              PopupMenuDivider(),
              PopupMenuItem<String>(value: 'templates', child: Text('Templates')),
              PopupMenuItem<String>(
                  value: 'subjects', child: Text('Manage Subjects')),
              PopupMenuItem<String>(
                  value: 'export', child: Text('Export & Backup')),
            ],
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

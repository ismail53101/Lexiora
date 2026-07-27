import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/daily_goal_card.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/quick_actions_card.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/streak_card.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_progress_cards.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_timer_card.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/tasks_card.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/today_timeline_card.dart';

/// The Study Hub dashboard — the student's Academic Planning System home.
class StudyHubPage extends ConsumerWidget {
  const StudyHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Hub'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search & filter',
            onPressed: () => context.push(AppRoutes.studyHubSearch),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          const StreakCard(),
          const DailyGoalCard(),
          const TodayTimelineCard(),
          const DailyPlannerCard(),
          const _PlannersCard(),
          const _ToolsCard(),
          const StudyTimerCard(),
          const WeeklyStatsCard(),
          const ProgressTrackerCard(),
          const QuickActionsCard(),
          const SizedBox(height: 24),
        ].animate(interval: 45.ms).fadeIn(duration: 240.ms).slideY(
              begin: 0.05,
              end: 0,
              curve: Curves.easeOut,
            ),
      ),
    );
  }
}

/// Navigation into the full Weekly / Monthly planners and Templates.
class _PlannersCard extends StatelessWidget {
  const _PlannersCard();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      icon: Icons.calendar_month_outlined,
      title: 'Planners',
      child: Column(
        children: <Widget>[
          _NavRow(
            icon: Icons.view_week_outlined,
            label: 'Weekly Planner',
            subtitle: 'Plan every day of the week',
            route: AppRoutes.studyHubWeekly,
          ),
          _NavRow(
            icon: Icons.calendar_month,
            label: 'Monthly Planner',
            subtitle: 'Schedule any date on a calendar',
            route: AppRoutes.studyHubMonthly,
          ),
          _NavRow(
            icon: Icons.event_repeat,
            label: 'Templates',
            subtitle: 'Save & reuse study routines',
            route: AppRoutes.studyHubTemplates,
          ),
        ],
      ),
    );
  }
}

/// Productivity tools: search, subject colours, export & backup.
class _ToolsCard extends StatelessWidget {
  const _ToolsCard();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      icon: Icons.build_outlined,
      title: 'Tools',
      child: Column(
        children: <Widget>[
          _NavRow(
            icon: Icons.search,
            label: 'Search & Filter',
            subtitle: 'Find sessions across all your plans',
            route: AppRoutes.studyHubSearch,
          ),
          _NavRow(
            icon: Icons.palette_outlined,
            label: 'Manage Subjects',
            subtitle: 'Colour-label and organise subjects',
            route: AppRoutes.studyHubSubjects,
          ),
          _NavRow(
            icon: Icons.ios_share,
            label: 'Export & Backup',
            subtitle: 'CSV / PDF / Excel · local backup',
            route: AppRoutes.studyHubExport,
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }
}

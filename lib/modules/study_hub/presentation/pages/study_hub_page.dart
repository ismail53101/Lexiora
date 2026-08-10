import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/quick_actions_card.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_progress_cards.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_timer_card.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/tasks_card.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/today_overview_card.dart';

/// The Study Planner dashboard (formerly "Study Hub") — the student's
/// Academic Planning System home.
///
/// Redesigned into a compact, one-short-scroll dashboard: Streak / Today's
/// Goal / Study Today share one row instead of three tall cards, Weekly
/// Statistics + Progress Tracker were merged into one Progress section
/// (they showed mostly the same numbers twice), and Planners / Tools moved
/// from full-height list rows into compact 2-column tile grids. Every
/// feature from the previous layout is still here — just denser.
class StudyHubPage extends ConsumerWidget {
  const StudyHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search & filter',
            onPressed: () => context.push(AppRoutes.studyHubSearch),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: <Widget>[
          const TodayOverviewRow(),
          const DailyPlannerCard(),
          const _PlannersCard(),
          const _ToolsCard(),
          const StudyTimerCard(),
          const ProgressCard(),
          const QuickActionsCard(),
          const SizedBox(height: 20),
        ].animate(interval: 40.ms).fadeIn(duration: 220.ms).slideY(
              begin: 0.05,
              end: 0,
              curve: Curves.easeOut,
            ),
      ),
    );
  }
}

/// Navigation into the full Weekly / Monthly planners and Templates — a
/// compact 2-column tile grid instead of three full-height list rows.
class _PlannersCard extends StatelessWidget {
  const _PlannersCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.calendar_month_outlined,
      title: 'Planners',
      child: CompactNavGrid(
        tiles: <Widget>[
          CompactNavTile(
            icon: Icons.today_outlined,
            label: 'Daily Planner',
            subtitle: 'Browse day by day',
            onTap: () => context.push(AppRoutes.studyHubDaily),
          ),
          CompactNavTile(
            icon: Icons.view_week_outlined,
            label: 'Weekly Planner',
            subtitle: 'Every day of the week',
            onTap: () => context.push(AppRoutes.studyHubWeekly),
          ),
          CompactNavTile(
            icon: Icons.calendar_month,
            label: 'Monthly Planner',
            subtitle: 'Any date on a calendar',
            onTap: () => context.push(AppRoutes.studyHubMonthly),
          ),
          CompactNavTile(
            icon: Icons.event_repeat,
            label: 'Templates',
            subtitle: 'Save & reuse study routines',
            onTap: () => context.push(AppRoutes.studyHubTemplates),
          ),
        ],
      ),
    );
  }
}

/// Productivity tools: search, subject colours, export & backup — a compact
/// 2-column tile grid instead of three full-height list rows.
class _ToolsCard extends StatelessWidget {
  const _ToolsCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.build_outlined,
      title: 'Tools',
      child: CompactNavGrid(
        tiles: <Widget>[
          CompactNavTile(
            icon: Icons.search,
            label: 'Search & Filter',
            subtitle: 'Find sessions',
            onTap: () => context.push(AppRoutes.studyHubSearch),
          ),
          CompactNavTile(
            icon: Icons.palette_outlined,
            label: 'Manage Subjects',
            subtitle: 'Organise subjects',
            onTap: () => context.push(AppRoutes.studyHubSubjects),
          ),
          CompactNavTile(
            icon: Icons.ios_share,
            label: 'Export & Backup',
            subtitle: 'CSV / PDF / Excel',
            onTap: () => context.push(AppRoutes.studyHubExport),
          ),
        ],
      ),
    );
  }
}

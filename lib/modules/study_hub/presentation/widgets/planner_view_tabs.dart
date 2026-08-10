import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';

enum PlannerView { daily, weekly, monthly }

/// The Daily / Weekly / Monthly switcher shown at the top of all three
/// planner pages — tapping a different view swaps straight to that page
/// (each of which shows this same bar, so it always feels like one
/// continuous "Planner" screen with three tabs, not three separate pages).
class PlannerViewTabs extends StatelessWidget implements PreferredSizeWidget {
  const PlannerViewTabs({super.key, required this.current});

  final PlannerView current;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  void _go(BuildContext context, PlannerView v) {
    if (v == current) return;
    final String route = switch (v) {
      PlannerView.daily => AppRoutes.studyHubDaily,
      PlannerView.weekly => AppRoutes.studyHubWeekly,
      PlannerView.monthly => AppRoutes.studyHubMonthly,
    };
    context.pushReplacement(route);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SegmentedButton<PlannerView>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const <ButtonSegment<PlannerView>>[
          ButtonSegment<PlannerView>(value: PlannerView.daily, label: Text('Daily')),
          ButtonSegment<PlannerView>(value: PlannerView.weekly, label: Text('Weekly')),
          ButtonSegment<PlannerView>(
              value: PlannerView.monthly, label: Text('Monthly')),
        ],
        selected: <PlannerView>{current},
        onSelectionChanged: (Set<PlannerView> s) => _go(context, s.first),
      ),
    );
  }
}

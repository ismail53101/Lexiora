import 'package:flutter/material.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/quick_actions_card.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_progress_cards.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_timer_card.dart';

/// Standalone pages for the Study Planner's tool cards, opened from the
/// planner's ⋮ menu. Each page simply hosts one of the existing dashboard
/// cards (same providers and behaviour as before), so every feature stays
/// reachable while the planner home stays focused on the Daily / Weekly /
/// Monthly views from the planner mockups.
class PlannerTimerPage extends StatelessWidget {
  const PlannerTimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Timer')),
      body: const ListView(
        padding: EdgeInsets.symmetric(vertical: 6),
        children: <Widget>[StudyTimerCard()],
      ),
    );
  }
}

/// Weekly / Monthly progress stats (study time, completed/pending sessions,
/// subjects, topics, goals, break time, avg daily) + subject chips.
class PlannerProgressPage extends StatelessWidget {
  const PlannerProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: const ListView(
        padding: EdgeInsets.symmetric(vertical: 6),
        children: <Widget>[ProgressCard()],
      ),
    );
  }
}

/// Quick Actions — jump straight into studying (Library, Vocabulary, …).
class PlannerQuickActionsPage extends StatelessWidget {
  const PlannerQuickActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Actions')),
      body: const ListView(
        padding: EdgeInsets.symmetric(vertical: 6),
        children: <Widget>[QuickActionsCard()],
      ),
    );
  }
}

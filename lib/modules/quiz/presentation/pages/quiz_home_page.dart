import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/app_bottom_nav.dart';

/// Quiz tab home (Phase v0.12.0). Two premium entry cards — **MCQs**
/// (study-mode, subject-wise practice with answers) and **Quiz** (staged,
/// timed levels) — mirroring the classic "All Modules" layout. Subjects are
/// reached from inside either card, so no separate subject list lives here.
class QuizHomePage extends StatelessWidget {
  const QuizHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push(AppRoutes.quizSearch),
          ),
          PopupMenuButton<String>(
            onSelected: (String v) {
              switch (v) {
                case 'analytics':
                  context.push(AppRoutes.quizAnalytics);
                case 'bookmarks':
                  context.push(AppRoutes.quizBookmarks);
                case 'wrong':
                  context.push(AppRoutes.quizWrong);
                case 'settings':
                  context.push(AppRoutes.quizSettings);
              }
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                  value: 'analytics', child: Text('Analytics')),
              PopupMenuItem<String>(
                  value: 'bookmarks', child: Text('Bookmarks')),
              PopupMenuItem<String>(
                  value: 'wrong', child: Text('Wrong answers')),
              PopupMenuItem<String>(
                  value: 'settings', child: Text('Quiz settings')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Master every subject, one level at a time',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Practice subject-wise MCQs, or climb the timed stage ladder.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          // IntrinsicHeight bounds the Row's cross axis so that
          // CrossAxisAlignment.stretch has a real height to fill. Without it,
          // a stretch Row inside a ListView receives an unbounded height
          // constraint and the cards fail to lay out (blank area in release).
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _ModuleCard(
                    title: 'MCQs',
                    subtitle: 'Subject-wise MCQs, answers shown as you study',
                    icon: Icons.list_alt_rounded,
                    gradient: const <Color>[
                      Color(0xFFF2B33D),
                      Color(0xFFC77D1B),
                    ],
                    onTap: () => context.push(AppRoutes.quizMcqs),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModuleCard(
                    title: 'Quiz',
                    subtitle: 'Timed 10-question levels, stage by stage',
                    icon: Icons.emoji_events_outlined,
                    gradient: const <Color>[
                      Color(0xFF5C8DF6),
                      Color(0xFF4A56C4),
                    ],
                    onTap: () => context.push(AppRoutes.quizStages),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms).slideY(
                begin: 0.06,
                end: 0,
                curve: Curves.easeOut,
              ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.tips_and_updates_outlined,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'MCQs shows the correct answer on every card so you can '
                    'learn while browsing. Quiz is the timed stage ladder — '
                    'answers stay hidden until the end.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ).animate(delay: 80.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// A premium gradient entry card (MCQs / Quiz).
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Open',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 15, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

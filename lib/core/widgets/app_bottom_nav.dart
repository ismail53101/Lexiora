import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';

/// The persistent bottom tab bar shown on each of the app's 5 top-level
/// screens (Home, AI Assistant, Quiz, Notes, Profile).
///
/// Each of those screens embeds this in its own `Scaffold.bottomNavigationBar`
/// — there's no `ShellRoute` wrapping them, so each tab keeps owning its own
/// route/page the same way every other [FeatureModule] does. Switching tabs
/// uses [GoRouter.go] (not `push`), so tabs never stack on top of each other.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  /// Which tab is active: 0 Home, 1 AI Assistant, 2 Quiz, 3 Notes, 4 Profile.
  final int currentIndex;

  static const List<_Tab> _tabs = <_Tab>[
    _Tab(
      'Home',
      Icons.home_outlined,
      Icons.home_rounded,
      AppRoutes.home,
      imageAsset: 'assets/branding/home_nav.jpg',
    ),
    _Tab(
      'AI Assistant',
      Icons.smart_toy_outlined,
      Icons.smart_toy_rounded,
      AppRoutes.aiAssistant,
      imageAsset: 'assets/quiz/branding/sapiora_ai_page_badge.png',
    ),
    _Tab(
      'Quiz',
      Icons.quiz_outlined,
      Icons.quiz_rounded,
      AppRoutes.quiz,
      imageAsset: 'assets/quiz/branding/quiz_hero.png',
    ),
    _Tab('Notes', Icons.notes_outlined, Icons.notes_rounded,
        AppRoutes.notesHome),
    _Tab(
      'Profile',
      Icons.person_outline,
      Icons.person_rounded,
      AppRoutes.profile,
      imageAsset: 'assets/branding/profile_nav.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (int i) {
        if (i == currentIndex) return;
        context.go(_tabs[i].route);
      },
      destinations: <Widget>[
        for (final _Tab tab in _tabs)
          NavigationDestination(
            icon: _tabIcon(context, tab, selected: false),
            selectedIcon: _tabIcon(context, tab, selected: true),
            label: tab.label,
          ),
      ],
    );
  }

  Widget _tabIcon(
    BuildContext context,
    _Tab tab, {
    required bool selected,
  }) {
    if (tab.imageAsset == null) {
      return Icon(selected ? tab.selectedIcon : tab.icon);
    }
    return Container(
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              )
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          tab.imageAsset!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Icon(
            selected ? tab.selectedIcon : tab.icon,
          ),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab(
    this.label,
    this.icon,
    this.selectedIcon,
    this.route, {
    this.imageAsset,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final String? imageAsset;
}

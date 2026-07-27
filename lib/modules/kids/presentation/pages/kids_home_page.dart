import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A single learning category tile shown on the Kids Zone home grid.
///
/// This is a lightweight, presentation-only model (not a domain entity) —
/// each category becomes a real feature with its own JSON data, provider and
/// pages in a follow-up file. For now every tile is present and tappable so
/// the screen is fully navigable and reviewable, and simply announces the
/// category is on its way rather than opening a route that doesn't exist yet.
@immutable
class _KidsCategory {
  const _KidsCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.available,
  });

  final String label;
  final IconData icon;
  final Color color;

  /// True once this category's real screen has been built and wired in.
  final bool available;
}

const List<_KidsCategory> _kCategories = <_KidsCategory>[
  _KidsCategory(
    label: 'ABC Learning',
    icon: Icons.abc,
    color: Color(0xFFFF6B6B),
    available: false,
  ),
  _KidsCategory(
    label: 'Numbers',
    icon: Icons.onetwothree,
    color: Color(0xFF4ECDC4),
    available: false,
  ),
  _KidsCategory(
    label: 'Colors',
    icon: Icons.palette,
    color: Color(0xFFFFB84C),
    available: false,
  ),
  _KidsCategory(
    label: 'Animals',
    icon: Icons.pets,
    color: Color(0xFF95D5B2),
    available: false,
  ),
  _KidsCategory(
    label: 'Birds',
    icon: Icons.flutter_dash,
    color: Color(0xFF74C0FC),
    available: false,
  ),
  _KidsCategory(
    label: 'Fruits',
    icon: Icons.apple,
    color: Color(0xFFFF8FA3),
    available: false,
  ),
  _KidsCategory(
    label: 'Vegetables',
    icon: Icons.eco,
    color: Color(0xFF8AC926),
    available: false,
  ),
  _KidsCategory(
    label: 'Shapes',
    icon: Icons.category,
    color: Color(0xFFB185DB),
    available: false,
  ),
  _KidsCategory(
    label: 'Body Parts',
    icon: Icons.accessibility_new,
    color: Color(0xFFFF9F6B),
    available: false,
  ),
  _KidsCategory(
    label: 'Transport',
    icon: Icons.directions_car,
    color: Color(0xFF6BAAFF),
    available: false,
  ),
  _KidsCategory(
    label: 'Days',
    icon: Icons.calendar_view_day,
    color: Color(0xFFFFD166),
    available: false,
  ),
  _KidsCategory(
    label: 'Months',
    icon: Icons.calendar_month,
    color: Color(0xFF06D6A0),
    available: false,
  ),
  _KidsCategory(
    label: 'Seasons',
    icon: Icons.wb_sunny,
    color: Color(0xFFFFA69E),
    available: false,
  ),
  _KidsCategory(
    label: 'Occupations',
    icon: Icons.engineering,
    color: Color(0xFF9AACFF),
    available: false,
  ),
  _KidsCategory(
    label: 'Family',
    icon: Icons.family_restroom,
    color: Color(0xFFF6A6C1),
    available: false,
  ),
  _KidsCategory(
    label: 'Tiny Stories',
    icon: Icons.auto_stories,
    color: Color(0xFFB088F9),
    available: false,
  ),
  _KidsCategory(
    label: 'Rhymes',
    icon: Icons.music_note,
    color: Color(0xFFFF7EB6),
    available: false,
  ),
  _KidsCategory(
    label: 'Quiz',
    icon: Icons.quiz,
    color: Color(0xFF5B4BE6),
    available: false,
  ),
  _KidsCategory(
    label: 'Progress',
    icon: Icons.bar_chart_rounded,
    color: Color(0xFF2EC4B6),
    available: false,
  ),
  _KidsCategory(
    label: 'Achievements',
    icon: Icons.emoji_events,
    color: Color(0xFFFFC43D),
    available: false,
  ),
];

/// The Kids Zone landing screen: a bright, cartoon-style grid of learning
/// categories, kept deliberately distinct from the rest of Sapiora's more
/// serious study surfaces (dictionary, grammar, quiz, flashcards).
class KidsHomePage extends StatelessWidget {
  const KidsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8EE),
        foregroundColor: const Color(0xFF3A2E52),
        elevation: 0,
        title: const Text(
          'Kids Zone 🎈',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            const SliverToBoxAdapter(child: _WelcomeBanner()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.92,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final _KidsCategory category = _kCategories[index];
                    return _CategoryCard(category: category, index: index);
                  },
                  childCount: _kCategories.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFD6E8), Color(0xFFC7F0FF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: <Widget>[
          Text('🦉', style: TextStyle(fontSize: 48)),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Let\'s learn English!',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3A2E52),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pick something fun to explore today',
                  style: TextStyle(fontSize: 13, color: Color(0xFF5C4E7A)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.08, end: 0);
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.index});

  final _KidsCategory category;
  final int index;

  void _onTap(BuildContext context) {
    if (!category.available) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: category.color,
            content: Text(
              '${category.label} is on its way! 🚧',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      return;
    }
    // Real categories navigate to their own route once built.
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _onTap(context),
        child: Ink(
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: category.color.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  category.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF3A2E52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (25 * index).ms)
        .fadeIn(duration: 240.ms)
        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1));
  }
}

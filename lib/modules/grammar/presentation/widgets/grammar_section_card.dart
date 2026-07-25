import 'package:flutter/material.dart';

/// A titled card used to group a lesson section (Explanation, Rules, Examples,
/// Notes, Tips, Common Mistakes, Practice). Keeps the Lesson screen visually
/// consistent and readable for long-form study.
class GrammarSectionCard extends StatelessWidget {
  const GrammarSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.accent,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// Optional accent color for the header (defaults to the theme primary).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color headerColor = accent ?? theme.colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: headerColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// A simple leading-bullet row used inside section cards for rules, notes and
/// tips lists.
class GrammarBullet extends StatelessWidget {
  const GrammarBullet({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon ?? Icons.circle,
              size: icon != null ? 18 : 7,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

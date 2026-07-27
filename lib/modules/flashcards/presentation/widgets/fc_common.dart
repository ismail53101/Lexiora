import 'package:flutter/material.dart';

/// Resolves a subject's colour from the shared Study Hub colour map.
Color? subjectColorOf(String? subject, Map<String, int> colors) {
  if (subject == null || subject.trim().isEmpty) return null;
  final int? argb = colors[subject.trim().toLowerCase()];
  return argb == null ? null : Color(argb);
}

/// A titled dashboard card, consistent with the rest of Sapiora.
class FcSectionCard extends StatelessWidget {
  const FcSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

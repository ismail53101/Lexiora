import 'package:flutter/material.dart';

/// Resolves a subject's user-assigned colour from the live colour map
/// (nameLower → ARGB), or null when the subject has no colour yet.
Color? subjectColorOf(String? subject, Map<String, int> colors) {
  if (subject == null || subject.trim().isEmpty) return null;
  final int? argb = colors[subject.trim().toLowerCase()];
  return argb == null ? null : Color(argb);
}

/// A titled dashboard card used across the Study Hub for a consistent look.
class SectionCard extends StatelessWidget {
  const SectionCard({
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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// A compact icon + title + optional-subtitle tile used for the Planners and
/// Tools grids — a much shorter alternative to a full-height ListTile row.
class CompactNavTile extends StatelessWidget {
  const CompactNavTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700, height: 1.15),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays compact nav tiles out 2-per-row, with a final odd tile (if any)
/// spanning the full width — used by the Planners and Tools sections.
class CompactNavGrid extends StatelessWidget {
  const CompactNavGrid({super.key, required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const double gap = 10;
        final double halfWidth = (c.maxWidth - gap) / 2;
        final List<Widget> rows = <Widget>[];
        for (int i = 0; i < tiles.length; i += 2) {
          final bool hasPair = i + 1 < tiles.length;
          rows.add(Padding(
            padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? gap : 0),
            child: hasPair
                ? Row(
                    children: <Widget>[
                      SizedBox(width: halfWidth, child: tiles[i]),
                      const SizedBox(width: gap),
                      SizedBox(width: halfWidth, child: tiles[i + 1]),
                    ],
                  )
                : tiles[i],
          ));
        }
        return Column(children: rows);
      },
    );
  }
}

/// A circular progress ring with an optional centered widget.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 120,
    this.strokeWidth = 10,
    this.color,
    this.center,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? theme.colorScheme.primary,
              ),
            ),
          ),
          if (center != null) Padding(padding: const EdgeInsets.all(8), child: center),
        ],
      ),
    );
  }
}

/// A compact metric tile (icon + value + label) used in the statistics grids.
class StudyStatTile extends StatelessWidget {
  const StudyStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color c = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: c),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Lays [tiles] out in a responsive grid (2 columns on phones, 3 when wide).
class StudyStatGrid extends StatelessWidget {
  const StudyStatGrid({super.key, required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final int columns = c.maxWidth >= 520 ? 4 : 2;
        const double gap = 8;
        final double itemWidth =
            (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final Widget t in tiles)
              SizedBox(width: itemWidth, child: t),
          ],
        );
      },
    );
  }
}

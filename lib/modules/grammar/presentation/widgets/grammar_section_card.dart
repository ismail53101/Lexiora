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
    const GrammarBullet({
    super.key,
    required this.text,
    this.icon,
    this.compact = false,
  });
  final String text;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon ?? Icons.circle,
              size: compact ? (icon != null ? 17 : 6) : (icon != null ? 18 : 7),
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyLarge)?.copyWith(
                  height: compact ? 1.25 : 1.4,
                ),
                children: _highlightRuleDetails(
                  text,
                  const Color(0xFF42A5F5),
                  defaultColor: compact ? const Color(0xFF64B5F6) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


List<TextSpan> _highlightRuleDetails(
  String text,
  Color highlightColor, {
  Color? defaultColor,
}) {
  final List<TextSpan> spans = <TextSpan>[];
  const Color exampleColor = Color(0xFF64B5F6);
  const Color explanationColor = Color(0xFFCE93D8);
  final RegExp marker = RegExp(r'(Example|Examples|Explanation):');
  int cursor = 0;
  Color? detailColor;

  for (final RegExpMatch match in marker.allMatches(text)) {
    if (match.start > cursor) {
      spans.addAll(_markupSpans(
        text.substring(cursor, match.start),
        detailColor,
      ));
    }
    spans.add(TextSpan(
      text: text.substring(match.start, match.end),
      style: TextStyle(color: highlightColor, fontWeight: FontWeight.w700),
    ));
    cursor = match.end;
    detailColor = match.group(1)!.startsWith('Explanation')
        ? explanationColor
        : exampleColor;
  }

  if (cursor < text.length) {
    spans.addAll(_markupSpans(
      text.substring(cursor),
      detailColor,
    ));
  }

  return spans.isEmpty ? _markupSpans(text, defaultColor) : spans;
}

List<TextSpan> _markupSpans(String text, Color? color) {
  final List<TextSpan> spans = <TextSpan>[];
  final RegExp markup = RegExp(r'(\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|__(.+?)__)');
  int cursor = 0;
  for (final RegExpMatch match in markup.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start), style: color == null ? null : TextStyle(color: color)));
    }
    final String value = match.group(2) ?? match.group(3) ?? match.group(4)!;
    final bool both = match.group(2) != null;
    final bool bold = both || match.group(3) != null;
    final bool underline = both || match.group(4) != null;
    spans.add(TextSpan(
      text: value,
      style: TextStyle(
        color: color,
        fontWeight: bold ? FontWeight.w800 : null,
        decoration: underline ? TextDecoration.underline : null,
        decorationThickness: underline ? 2 : null,
      ),
    ));
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: color == null ? null : TextStyle(color: color)));
  }
  return spans.isEmpty ? <TextSpan>[TextSpan(text: text, style: color == null ? null : TextStyle(color: color))] : spans;
}

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
  const Color exampleColor = Color(0xFF64B5F6);
  const Color explanationColor = Color(0xFFCE93D8);
  final List<TextSpan> spans = <TextSpan>[];
  final RegExp marker = RegExp(r'(Example|Examples|Explanation):');

  for (final String line in text.split('\n')) {
    if (line.isEmpty) {
      spans.add(const TextSpan(text: '\n'));
      continue;
    }
    if (!marker.hasMatch(line) && _looksLikeExampleLine(line)) {
      spans.add(TextSpan(
        text: 'Example: ',
        style: TextStyle(color: highlightColor, fontWeight: FontWeight.w700),
      ));
      spans.addAll(_markupSpans(line, exampleColor));
      spans.add(const TextSpan(text: '\n'));
      continue;
    }
    int cursor = 0;
    for (final RegExpMatch match in marker.allMatches(line)) {
      if (match.start > cursor) {
        spans.addAll(_markupSpans(
          line.substring(cursor, match.start),
          defaultColor,
        ));
      }
      final bool explanation = match.group(1)!.startsWith('Explanation');
      spans.add(TextSpan(
        text: line.substring(match.start, match.end),
        style: TextStyle(color: highlightColor, fontWeight: FontWeight.w700),
      ));
      cursor = match.end;
      final RegExpMatch? next = marker.firstMatch(line.substring(cursor));
      final int end = next == null ? line.length : cursor + next.start;
      spans.addAll(_markupSpans(
        line.substring(cursor, end),
        explanation ? explanationColor : exampleColor,
      ));
      cursor = end;
    }
    if (cursor < line.length) {
      spans.addAll(_markupSpans(line.substring(cursor), defaultColor));
    }
    spans.add(const TextSpan(text: '\n'));
  }
  if (spans.isNotEmpty) spans.removeLast();
  return spans;
}

bool _looksLikeExampleLine(String line) {
  final String value = line.trim();
  if (value.isEmpty || RegExp(r'[\u0600-\u06FF]').hasMatch(value)) return false;
  if (value.startsWith('❌') || value.startsWith('✅')) return true;
  if (!RegExp(r'[.!?]$').hasMatch(value)) return false;
  return RegExp(r'^(I|He|She|It|We|They|You|Ali|Sara|John|The students|The boy|The girl|Did |Does |Do |Has |Have |Had |Will |Am |Is |Are |Was |Were )').hasMatch(value);
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

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
    this.showHeader = true,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// Optional accent color for the header (defaults to the theme primary).
  final Color? accent;

  /// Hides only the title/icon row while preserving the card and its content.
  final bool showHeader;

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
            if (showHeader) ...<Widget>[
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
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// A simple leading-bullet row used inside section cards for rules, notes and
/// tips lists.
class TenseRichText extends StatelessWidget {
  const TenseRichText({required this.text, this.style, this.bilingual = false});
  final String text;
  final TextStyle? style;
  final bool bilingual;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        style ?? theme.textTheme.bodySmall?.copyWith(height: 1.3) ?? const TextStyle();
    if (bilingual) {
      return _BilingualRichText(text: text, style: baseStyle);
    }
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: _highlightRuleDetails(text, const Color(0xFF42A5F5)),
      ),
    );
  }
}

class _BilingualRichText extends StatelessWidget {
  const _BilingualRichText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final List<Widget> lines = <Widget>[];
    Color? carriedColor;
    final List<String> rawLines = text.split('\n');
    for (int lineIndex = 0; lineIndex < rawLines.length; lineIndex++) {
      final String rawLine = rawLines[lineIndex];
      if (rawLine.trim().startsWith('|') &&
          lineIndex + 1 < rawLines.length &&
          rawLines[lineIndex + 1].trim().startsWith('|')) {
        final List<String> tableLines = <String>[];
        while (lineIndex < rawLines.length &&
            rawLines[lineIndex].trim().startsWith('|')) {
          tableLines.add(rawLines[lineIndex].trim());
          lineIndex++;
        }
        lineIndex--;
        final List<List<String>> rows = _markdownTableRows(tableLines);
        if (rows.length > 1) {
          carriedColor = null;
          lines.add(_CompactMarkdownTable(rows: rows));
          continue;
        }
      }
      final String line = _normalizeLabelMarkup(rawLine);
      if (line.isEmpty) {
        carriedColor = null;
        lines.add(const SizedBox(height: 10));
        continue;
      }
      final bool isUrdu = RegExp(r'[\u0600-\u06ff]').hasMatch(line);
      final bool isExample = _looksLikeExampleLine(line) || _looksLikeConditionalExampleLine(line);
      final bool startsExplanation = RegExp(r'^(Explanation|Here):').hasMatch(line);
      final bool startsExample = RegExp(r'^(Example|Examples):').hasMatch(line);
      if (startsExplanation) {
        carriedColor = const Color(0xFFCE93D8);
      } else if (startsExample) {
        carriedColor = const Color(0xFF64B5F6);
      } else if (carriedColor == const Color(0xFF64B5F6) &&
          !isUrdu &&
          !isExample &&
          line.trim().startsWith('In each example')) {
        carriedColor = null;
      }
      final Color? lineColor = startsExplanation ||
              line.startsWith('Here:') ||
              carriedColor == const Color(0xFFCE93D8)
          ? const Color(0xFFCE93D8)
          : (startsExample ||
                  isExample ||
                  (isUrdu && carriedColor == const Color(0xFF64B5F6)))
              ? const Color(0xFF64B5F6)
              : null;
      final bool heading = RegExp(
        r'^(Definition|English:|Urdu:|Example:|Examples:|Explanation:|Here:|Quick Tip|Types of Clauses|Types of Conditional Sentences|Basic Structure|Structure|Common Structure|Main Function|How to Identify|Compare|Easy Rule|Exam Tip|Functions of|Function|Usage|Common Words|Common Structures|Conditional Sentence:|Zero Conditional:|First Conditional:|Second Conditional:|Third Conditional:|Mixed Conditional:|Past Perfect|Past Simple|If \+|Subject:|Verb:|Complete thought:|Condition|Result|Noun Clause:|Adjective Clause:|Adverb Clause:|Independent Clause:|Dependent Clause:)',
      ).hasMatch(line.trim());
      final List<TextSpan> spans = _markupSpans(line, lineColor);
      if (heading && spans.isNotEmpty) {
        spans[0] = TextSpan(
          text: spans[0].text,
          style: (spans[0].style ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w800,
          ),
          children: spans[0].children,
        );
      }
      lines.add(
        Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Text.rich(
            TextSpan(style: style, children: spans),
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: lines);
  }
}

List<List<String>> _markdownTableRows(List<String> lines) {
  final List<List<String>> rows = <List<String>>[];
  for (final String line in lines) {
    final List<String> cells = line
        .split('|')
        .map((String cell) => cell.trim())
        .toList();
    if (cells.isNotEmpty && cells.first.isEmpty) cells.removeAt(0);
    if (cells.isNotEmpty && cells.last.isEmpty) cells.removeLast();
    if (cells.isEmpty || cells.every((String cell) => RegExp(r'^:?-{2,}:?$').hasMatch(cell))) {
      continue;
    }
    rows.add(cells);
  }
  return rows;
}

class _CompactMarkdownTable extends StatelessWidget {
  const _CompactMarkdownTable({required this.rows});
  static const Color _exampleColor = Color(0xFF64B5F6);
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> header = rows.first;
    final List<List<String>> body = rows.skip(1).toList();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: <Widget>[
            _tableRow(header, theme, isHeader: true),
            for (final List<String> row in body) ...<Widget>[
              Divider(height: 10, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.65)),
              _tableRow(row, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tableRow(List<String> cells, ThemeData theme, {bool isHeader = false}) {
    final String left = cells.isNotEmpty ? cells[0] : '';
    final String right = cells.length > 1 ? cells[1] : '';
    final TextStyle leftStyle = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w800,
      color: isHeader ? theme.colorScheme.primary : null,
      height: 1.2,
    );
    final TextStyle rightStyle = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: isHeader ? theme.colorScheme.primary : _exampleColor,
      fontWeight: isHeader ? FontWeight.w800 : null,
      height: 1.2,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: Text.rich(TextSpan(style: leftStyle, children: _markupSpans(left, leftStyle.color)))),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: Text.rich(TextSpan(style: rightStyle, children: _markupSpans(right, rightStyle.color)))),
      ],
    );
  }
}

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
                  defaultColor: null,
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
  final RegExp marker = RegExp(r'(Example|Examples|Explanation|Here):');
  for (final String rawLine in text.split('\n')) {
    final String line = _normalizeLabelMarkup(rawLine);
    if (line.isEmpty) {
      spans.add(const TextSpan(text: '\n'));
      continue;
    }
    if (!marker.hasMatch(line) && _looksLikeExampleLine(line)) {
      spans.addAll(_exampleLineSpans(line, exampleColor));
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
      final bool explanation = match.group(1)!.startsWith('Explanation') || match.group(1) == 'Here';
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

bool _looksLikeConditionalExampleLine(String line) {
  final String value = line.trim();
  if (value.startsWith('|')) {
    return RegExp(r'\bIf\b.*[.!?]\s*\|?$').hasMatch(value);
  }
  if (value.contains('→') && value.contains('Condition') ||
      value.contains('→') && value.contains('Result')) {
    return true;
  }
  if (RegExp(r'^(If\s+.+[.!?]|[a-z]+\s+→\s+(Condition|Result))$').hasMatch(value)) {
    return true;
  }
  return false;
}

bool _looksLikeExampleLine(String line) {
  final String value = line.trim().replaceFirst(RegExp(r'^[.•]+\s*'), '');
  final String englishPart = value.split(RegExp(r'\s+[—–-]\s+')).first.trim();
  if (englishPart.isEmpty) return false;
  if (value.startsWith('❌') || value.startsWith('✅')) return true;
  if (!RegExp(r'[.!?]$').hasMatch(englishPart)) return false;
  if (RegExp(r'(Subject\s*\+|Formula:|\bV[123](?:-ing)?\b|\bAffirmative\b|\bNegative\b|\bInterrogative\b)').hasMatch(englishPart)) return false;
  return RegExp(r'^(I|He|She|It|We|They|You|Ali|Sara|John|The students|The boy|The girl|Did |Does |Do |Has |Have |Had |Will |Am |Is |Are |Was |Were )').hasMatch(englishPart);
}

String _normalizeLabelMarkup(String line) {
  return line.replaceAllMapped(
    RegExp(r'(?:\*{2,3}|__)(Examples?|Explanation):(?:\*{2,3}|__)'),
    (Match match) => '${match.group(1)}:',
  );
}

List<TextSpan> _exampleLineSpans(String line, Color color) {
  final RegExpMatch? separator = RegExp(r'\s+[—–-]\s+').firstMatch(line);
  if (separator == null) return _markupSpans(line, color);
  return <TextSpan>[
    ..._markupSpans(line.substring(0, separator.start), color),
    ..._markupSpans(line.substring(separator.start), null),
  ];
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

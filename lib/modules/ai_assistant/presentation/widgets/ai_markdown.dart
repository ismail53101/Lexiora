import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Renders assistant Markdown: headings, bold/italic, bullet & numbered lists,
/// tables, fenced code blocks, and LaTeX math ($...$ / $$...$$). Provider-output
/// friendly via the `gpt_markdown` engine.
///
/// Headings are toned down to chat-appropriate sizes (a raw `#` from a model
/// shouldn't render bigger than a screen title) and tables are wrapped in
/// their own horizontally-scrollable, bordered card so a wide table scrolls
/// sideways instead of being clipped off the edge of the screen.
class AiMarkdown extends StatelessWidget {
  const AiMarkdown({super.key, required this.data, this.color});

  final String data;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color textColor = color ?? scheme.onSurface;

    return GptMarkdownTheme(
      gptThemeData: GptMarkdownThemeData(
        brightness: theme.brightness,
        linkColor: scheme.primary,
        highlightColor: scheme.primary.withValues(alpha: 0.16),
        h1: theme.textTheme.titleLarge
            ?.copyWith(color: textColor, fontWeight: FontWeight.w800),
        h2: theme.textTheme.titleMedium
            ?.copyWith(color: textColor, fontWeight: FontWeight.w800),
        h3: theme.textTheme.titleSmall
            ?.copyWith(color: textColor, fontWeight: FontWeight.w800),
        h4: theme.textTheme.bodyLarge
            ?.copyWith(color: textColor, fontWeight: FontWeight.w800),
        h5: theme.textTheme.bodyMedium
            ?.copyWith(color: textColor, fontWeight: FontWeight.w800),
        h6: theme.textTheme.bodyMedium
            ?.copyWith(color: textColor, fontWeight: FontWeight.w700),
        hrLineColor: scheme.outlineVariant,
        hrLineThickness: 1,
      ),
      child: GptMarkdown(
        data,
        useDollarSignsForLatex: true,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          height: 1.5,
        ),
        codeBuilder:
            (BuildContext context, String name, String code, bool closed) =>
                _CodeBlock(language: name, code: code),
        // Left untyped (rather than spelling out the package's row/cell/config
        // types) so Dart infers them from the `tableBuilder` parameter's own
        // type — avoids coupling this file to gpt_markdown's exact internal
        // type names, which have changed across versions.
        tableBuilder: (context, rows, textStyle, config) =>
            _MarkdownTable(rows: rows, textStyle: textStyle, color: textColor),
      ),
    );
  }
}

/// A ChatGPT-style table: shaded header row, bordered cells. Each column
/// gets an equal share of the screen when that's roomy enough for text to
/// wrap normally; once there isn't enough room per column for that (e.g. a
/// 4-column Word / English / Urdu / Synonym table), squeezing columns down
/// with FlexColumnWidth forces individual long words to snap mid-letter
/// ("Parado" / "xically") because there's no space left to wrap at a word
/// boundary. In that case each column instead gets a fixed, comfortable
/// minimum width and the whole table scrolls sideways — words stay whole,
/// you just swipe to see the rest of a wide table.
class _MarkdownTable extends StatelessWidget {
  const _MarkdownTable({
    required this.rows,
    required this.textStyle,
    required this.color,
  });

  // Kept dynamic (not the package's row/cell type names) — those types
  // aren't part of gpt_markdown's stable public export path across versions,
  // so this reads `.isHeader` / `.fields` / `.data` / `.alignment` off
  // whatever row/cell objects gpt_markdown hands back.
  final List<dynamic> rows;
  final TextStyle textStyle;
  final Color color;

  // Below this width per column, wrapped text starts running out of room
  // for whole words at normal font sizes — that's the threshold for
  // switching from "shrink columns to fit" to "fixed width + scroll".
  static const double _minComfortableColumnWidth = 108;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final int columnCount =
        rows.isEmpty ? 0 : (rows.first.fields as List<dynamic>).length;
    if (columnCount == 0) return const SizedBox.shrink();

    Widget buildTable(Map<int, TableColumnWidth> columnWidths) {
      return Table(
        columnWidths: columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(
          horizontalInside: BorderSide(color: scheme.outlineVariant),
          verticalInside: BorderSide(color: scheme.outlineVariant),
        ),
        children: <TableRow>[
          for (final dynamic row in rows)
            TableRow(
              decoration: row.isHeader == true
                  ? BoxDecoration(color: scheme.surfaceContainerHighest)
                  : null,
              children: <Widget>[
                for (final dynamic cell in row.fields as List<dynamic>)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    child: Text(
                      '${cell.data}',
                      textAlign: cell.alignment as TextAlign?,
                      softWrap: true,
                      style: textStyle.copyWith(
                        color: color,
                        fontSize: 13,
                        fontWeight: row.isHeader == true
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bool fitsComfortably =
            columnCount * _minComfortableColumnWidth <= available;

        final Widget bordered = Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: fitsComfortably
              ? buildTable(<int, TableColumnWidth>{
                  for (int i = 0; i < columnCount; i++)
                    i: const FlexColumnWidth(),
                })
              : SizedBox(
                  width: columnCount * _minComfortableColumnWidth,
                  child: buildTable(<int, TableColumnWidth>{
                    for (int i = 0; i < columnCount; i++)
                      i: const FixedColumnWidth(_minComfortableColumnWidth),
                  }),
                ),
        );

        if (fitsComfortably) return SizedBox(width: double.infinity, child: bordered);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: bordered,
        );
      },
    );
  }
}

/// A code block with a language label and a copy button, horizontally scrollable.
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.language, required this.code});

  final String language;
  final String code;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String cleanCode =
        code.endsWith('\n') ? code.substring(0, code.length - 1) : code;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  language.trim().isEmpty ? 'code' : language.trim(),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copy code',
                visualDensity: VisualDensity.compact,
                onPressed: () => _copy(context, cleanCode),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SelectableText(
              cleanCode,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _copy(BuildContext context, String text) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: text));
  messenger.showSnackBar(const SnackBar(content: Text('Code copied')));
}

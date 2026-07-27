import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Renders assistant Markdown: headings, bold/italic, bullet & numbered lists,
/// tables, fenced code blocks, and LaTeX math ($...$ / $$...$$). Provider-output
/// friendly via the `gpt_markdown` engine.
class AiMarkdown extends StatelessWidget {
  const AiMarkdown({super.key, required this.data, this.color});

  final String data;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GptMarkdown(
      data,
      useDollarSignsForLatex: true,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: color ?? theme.colorScheme.onSurface,
        height: 1.45,
      ),
      codeBuilder: (BuildContext context, String name, String code, bool closed) =>
          _CodeBlock(language: name, code: code),
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

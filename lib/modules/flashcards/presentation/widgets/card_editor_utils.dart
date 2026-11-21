import 'package:flutter/services.dart';

/// Inserts finalized speech into the current text selection without losing
/// surrounding text. A small separator is added when needed.
TextEditingValue insertSpeechText(
  TextEditingValue value,
  String spoken,
) {
  final String phrase = spoken.trim();
  if (phrase.isEmpty) return value;

  final TextSelection selection = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: value.text.length);
  final int start = selection.start.clamp(0, value.text.length);
  final int end = selection.end.clamp(start, value.text.length);
  final bool needsLeadingSpace =
      start > 0 && !value.text.substring(0, start).endsWith(' ');
  final String insertion = (needsLeadingSpace ? ' ' : '') + phrase;
  final String next = value.text.replaceRange(start, end, insertion);
  final int caret = start + insertion.length;

  return TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(offset: caret),
    composing: TextRange.empty,
  );
}

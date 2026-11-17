import 'package:flutter/material.dart';

final RegExp _fcImageToken = RegExp(r'\[img:([^\]]+)\]');
final RegExp _fcMarkupToken = RegExp(r'\[(b|i|u)\](.*?)\[/\1\]', dotAll: true);

String fcApplyMarkup(String text, int start, int end, String tag) {
  final int a = start.clamp(0, text.length);
  final int b = end.clamp(a, text.length);
  if (a == b) return text;
  final String selected = text.substring(a, b);
  return text.replaceRange(a, b, '[' + tag + ']' + selected + '[/' + tag + ']');
}

String fcClearFormatting(String text) =>
    text.replaceAllMapped(_fcMarkupToken, (Match m) => m.group(2)!);

List<FcContentPart> fcContentParts(String text) {
  final List<FcContentPart> out = <FcContentPart>[];
  int cursor = 0;
  for (final RegExpMatch m in _fcImageToken.allMatches(text)) {
    if (m.start > cursor) out.add(FcContentPart.text(text.substring(cursor, m.start)));
    out.add(FcContentPart.image(m.group(1)!));
    cursor = m.end;
  }
  if (cursor < text.length) out.add(FcContentPart.text(text.substring(cursor)));
  return out;
}

List<InlineSpan> fcMarkupSpans(
  String text,
  TextStyle base, {
  TextStyle? Function(String tag, TextStyle base)? styleForTag,
}) {
  final List<InlineSpan> out = <InlineSpan>[];
  int cursor = 0;
  for (final RegExpMatch m in _fcMarkupToken.allMatches(text)) {
    if (m.start > cursor) out.add(TextSpan(text: text.substring(cursor, m.start)));
    final String tag = m.group(1)!;
    final TextStyle style = styleForTag?.call(tag, base) ??
        switch (tag) {
          'b' => base.copyWith(fontWeight: FontWeight.w800),
          'i' => base.copyWith(fontStyle: FontStyle.italic),
          'u' => base.copyWith(decoration: TextDecoration.underline),
          _ => base,
        };
    out.add(TextSpan(text: m.group(2), style: style));
    cursor = m.end;
  }
  if (cursor < text.length) out.add(TextSpan(text: text.substring(cursor)));
  return out;
}

class FcContentPart {
  const FcContentPart.text(this.value) : isImage = false;
  const FcContentPart.image(this.value) : isImage = true;
  final String value;
  final bool isImage;
}

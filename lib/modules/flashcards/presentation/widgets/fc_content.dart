import 'package:flutter/material.dart';

final RegExp _fcImageToken = RegExp(r'\[img:([^\]]+)\]');
final RegExp _fcMarkupToken = RegExp(r'\[(b|i|u)\]|\[/(b|i|u)\]');

class _FcFormatRange {
  _FcFormatRange(this.start, this.end, this.tag);
  int start;
  int end;
  final String tag;
}

/// Plain-text editing with formatting ranges. The editable value remains plain
/// so Flutter cursor/selection offsets stay correct; persisted cards use the
/// existing [b]/[i]/[u] markup.
class FcRichTextController extends TextEditingController {
  FcRichTextController({String? text}) : super(text: text);

  final List<_FcFormatRange> _ranges = <_FcFormatRange>[];
  final Set<String> _activeFormats = <String>{};
  static const List<String> _formatOrder = <String>['b', 'i', 'u'];

  bool get isBoldActive => _activeFormats.contains('b');
  bool get isItalicActive => _activeFormats.contains('i');
  bool get isUnderlineActive => _activeFormats.contains('u');

  void loadMarkup(String markup) {
    _ranges.clear();
    _activeFormats.clear();

    final StringBuffer plain = StringBuffer();
    final List<String> stack = <String>[];
    int cursor = 0;

    for (final RegExpMatch match in _fcMarkupToken.allMatches(markup)) {
      _appendMarkupText(plain, markup.substring(cursor, match.start), stack);
      final String? open = match.group(1);
      final String? close = match.group(2);
      if (open != null) {
        stack.add(open);
      } else if (close != null) {
        for (int i = stack.length - 1; i >= 0; i--) {
          if (stack[i] == close) {
            stack.removeAt(i);
            break;
          }
        }
      }
      cursor = match.end;
    }

    _appendMarkupText(plain, markup.substring(cursor), stack);
    super.value = TextEditingValue(
      text: plain.toString(),
      selection: TextSelection.collapsed(offset: plain.length),
    );
  }

  void _appendMarkupText(StringBuffer plain, String segment, List<String> activeTags) {
    if (segment.isEmpty) return;
    final int start = plain.length;
    plain.write(segment);
    final int end = plain.length;
    for (final String tag in activeTags.toSet()) {
      _ranges.add(_FcFormatRange(start, end, tag));
    }
  }

  String get markupText {
    if (text.isEmpty || _ranges.isEmpty) return text;

    final Set<int> boundaries = <int>{0, text.length};
    for (final _FcFormatRange r in _ranges) {
      boundaries.add(r.start.clamp(0, text.length));
      boundaries.add(r.end.clamp(0, text.length));
    }
    final List<int> points = boundaries.toList()..sort();
    final StringBuffer out = StringBuffer();
    Set<String> previous = <String>{};

    for (int i = 0; i < points.length - 1; i++) {
      final int start = points[i];
      final int end = points[i + 1];
      if (start == end) continue;

      final Set<String> current = _formatsAt(start);
      // Close the previous style stack completely, then open the current
      // stack. This keeps overlapping formatting ranges validly nested.
      for (final String tag in _formatOrder.reversed) {
        if (previous.contains(tag)) out.write('[/$tag]');
      }
      for (final String tag in _formatOrder) {
        if (current.contains(tag)) out.write('[$tag]');
      }
      out.write(text.substring(start, end));
      previous = current;
    }

    for (final String tag in _formatOrder.reversed) {
      if (previous.contains(tag)) out.write('[/$tag]');
    }
    return out.toString();
  }

  Set<String> _formatsAt(int offset) {
    final Set<String> tags = <String>{};
    for (final _FcFormatRange r in _ranges) {
      if (offset >= r.start && offset < r.end) tags.add(r.tag);
    }
    return tags;
  }

  bool isFormatted(TextRange selection, String tag) {
    if (!selection.isValid || selection.isCollapsed) return _activeFormats.contains(tag);
    final int start = selection.start.clamp(0, text.length);
    final int end = selection.end.clamp(start, text.length);
    if (start == end) return _activeFormats.contains(tag);

    int cursor = start;
    final List<_FcFormatRange> tagged = _ranges
        .where((r) => r.tag == tag && r.end > start && r.start < end)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final _FcFormatRange r in tagged) {
      if (r.start > cursor) break;
      if (r.end > cursor) cursor = r.end;
      if (cursor >= end) return true;
    }
    return false;
  }

  void toggleFormat(String tag, TextRange selection) {
    if (!selection.isValid || selection.isCollapsed) {
      if (_activeFormats.contains(tag)) {
        _activeFormats.remove(tag);
      } else {
        _activeFormats.add(tag);
      }
      notifyListeners();
      return;
    }

    final int start = selection.start.clamp(0, text.length);
    final int end = selection.end.clamp(start, text.length);
    if (start == end) return;

    final bool remove = isFormatted(TextRange(start: start, end: end), tag);
    if (remove) {
      _removeFormat(start, end, tag);
      _activeFormats.remove(tag);
    } else {
      _addFormat(start, end, tag);
      _activeFormats.add(tag);
    }
    super.value = value.copyWith(selection: selection);
  }

  void _addFormat(int start, int end, String tag) {
    _ranges.add(_FcFormatRange(start, end, tag));
    _mergeRanges(tag);
  }

  void _removeFormat(int start, int end, String tag) {
    final List<_FcFormatRange> next = <_FcFormatRange>[];
    for (final _FcFormatRange r in _ranges) {
      if (r.tag != tag || r.end <= start || r.start >= end) {
        next.add(r);
        continue;
      }
      if (r.start < start) next.add(_FcFormatRange(r.start, start, tag));
      if (r.end > end) next.add(_FcFormatRange(end, r.end, tag));
    }
    _ranges
      ..clear()
      ..addAll(next);
  }

  void _mergeRanges(String tag) {
    final List<_FcFormatRange> tagged =
        _ranges.where((r) => r.tag == tag).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    if (tagged.length < 2) return;

    final List<_FcFormatRange> merged = <_FcFormatRange>[];
    for (final _FcFormatRange r in tagged) {
      if (merged.isEmpty || r.start > merged.last.end) {
        merged.add(_FcFormatRange(r.start, r.end, tag));
      } else {
        merged.last.end = merged.last.end > r.end ? merged.last.end : r.end;
      }
    }
    _ranges.removeWhere((r) => r.tag == tag);
    _ranges.addAll(merged);
  }

  void clearFormatting() {
    _ranges.clear();
    _activeFormats.clear();
    notifyListeners();
  }

  @override
  set value(TextEditingValue newValue) {
    final String oldText = text;
    final String newText = newValue.text;
    if (oldText != newText && _ranges.isNotEmpty) {
      _adjustRangesForEdit(oldText, newText);
    }

    super.value = newValue;

    if (oldText != newText && _activeFormats.isNotEmpty) {
      final ({int start, int end}) edit = _changedRange(oldText, newText);
      if (edit.end > edit.start) {
        for (final String tag in _activeFormats) {
          _addFormat(edit.start, edit.end, tag);
        }
      }
    }
    _clampRanges();
  }

  ({int start, int end}) _changedRange(String oldText, String newText) {
    int prefix = 0;
    final int maxPrefix = oldText.length < newText.length ? oldText.length : newText.length;
    while (prefix < maxPrefix && oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) prefix++;

    int oldEnd = oldText.length;
    int newEnd = newText.length;
    while (oldEnd > prefix &&
        newEnd > prefix &&
        oldText.codeUnitAt(oldEnd - 1) == newText.codeUnitAt(newEnd - 1)) {
      oldEnd--;
      newEnd--;
    }
    return (start: prefix, end: newEnd);
  }

  void _adjustRangesForEdit(String oldText, String newText) {
    int prefix = 0;
    final int maxPrefix = oldText.length < newText.length ? oldText.length : newText.length;
    while (prefix < maxPrefix && oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) prefix++;

    int oldEnd = oldText.length;
    int newEnd = newText.length;
    while (oldEnd > prefix &&
        newEnd > prefix &&
        oldText.codeUnitAt(oldEnd - 1) == newText.codeUnitAt(newEnd - 1)) {
      oldEnd--;
      newEnd--;
    }

    final int delta = (newEnd - prefix) - (oldEnd - prefix);
    for (final _FcFormatRange r in _ranges) {
      if (oldEnd <= r.start) {
        r.start += delta;
        r.end += delta;
      } else if (prefix >= r.end) {
        // The range is entirely before the edit.
      } else {
        r.start = r.start < prefix ? r.start : prefix;
        r.end = (r.end + delta).clamp(r.start, newText.length);
      }
    }
    _clampRanges();
  }

  void _clampRanges() {
    _ranges.removeWhere((r) => r.start >= text.length || r.end <= 0 || r.start >= r.end);
    for (final _FcFormatRange r in _ranges) {
      r.start = r.start.clamp(0, text.length);
      r.end = r.end.clamp(r.start, text.length);
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextStyle base = style ?? const TextStyle();
    final Set<int> boundaries = <int>{0, text.length};
    for (final _FcFormatRange r in _ranges) {
      boundaries.add(r.start.clamp(0, text.length));
      boundaries.add(r.end.clamp(0, text.length));
    }
    final List<int> points = boundaries.toList()..sort();
    final List<InlineSpan> children = <InlineSpan>[];

    for (int i = 0; i < points.length - 1; i++) {
      final int start = points[i];
      final int end = points[i + 1];
      if (start == end) continue;

      TextStyle segmentStyle = base;
      for (final String tag in _formatsAt(start)) {
        segmentStyle = switch (tag) {
          'b' => segmentStyle.copyWith(fontWeight: FontWeight.w800),
          'i' => segmentStyle.copyWith(fontStyle: FontStyle.italic),
          'u' => segmentStyle.copyWith(decoration: TextDecoration.underline),
          _ => segmentStyle,
        };
      }
      children.add(TextSpan(text: text.substring(start, end), style: segmentStyle));
    }

    if (children.isEmpty && text.isNotEmpty) {
      children.add(TextSpan(text: text, style: base));
    }
    return TextSpan(style: base, children: children);
  }
}

String fcApplyMarkup(String text, int start, int end, String tag) {
  final int a = start.clamp(0, text.length);
  final int b = end.clamp(a, text.length);
  if (a == b) return text;
  return text.replaceRange(a, b, '[' + tag + ']' + text.substring(a, b) + '[/' + tag + ']');
}

String fcClearFormatting(String text) {
  final FcRichTextController controller = FcRichTextController();
  controller.loadMarkup(text);
  final String plain = controller.text;
  controller.dispose();
  return plain;
}

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
  final List<String> stack = <String>[];
  int cursor = 0;

  void addSegment(String segment, List<String> tags) {
    if (segment.isEmpty) return;
    TextStyle style = base;
    for (final String tag in tags.toSet()) {
      style = styleForTag?.call(tag, style) ??
          switch (tag) {
            'b' => style.copyWith(fontWeight: FontWeight.w800),
            'i' => style.copyWith(fontStyle: FontStyle.italic),
            'u' => style.copyWith(decoration: TextDecoration.underline),
            _ => style,
          };
    }
    out.add(TextSpan(text: segment, style: style));
  }

  for (final RegExpMatch match in _fcMarkupToken.allMatches(text)) {
    addSegment(text.substring(cursor, match.start), stack);
    final String? open = match.group(1);
    final String? close = match.group(2);
    if (open != null) {
      stack.add(open);
    } else if (close != null) {
      for (int i = stack.length - 1; i >= 0; i--) {
        if (stack[i] == close) {
          stack.removeAt(i);
          break;
        }
      }
    }
    cursor = match.end;
  }
  addSegment(text.substring(cursor), stack);
  return out;
}

class FcContentPart {
  const FcContentPart.text(this.value) : isImage = false;
  const FcContentPart.image(this.value) : isImage = true;
  final String value;
  final bool isImage;
}

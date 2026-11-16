/// Cloze deletions, written `{{c1::answer}}` or `{{c1::answer::hint}}`.
///
/// Nested clozes are not supported. Plain text outside the markers is kept as
/// is. The `cN` number groups deletions: a card that is "about" c2 hides only
/// the c2 deletions and shows the others as normal text.
library;

final RegExp _clozeRe =
    RegExp(r'\{\{c(\d+)::(.*?)(?:::(.*?))?\}\}', dotAll: true);

/// One cloze deletion found in a text.
class ClozeSpan {
  const ClozeSpan({
    required this.start,
    required this.end,
    required this.index,
    required this.answer,
    this.hint,
  });

  final int start;
  final int end;
  final int index;
  final String answer;
  final String? hint;
}

/// A rendered piece of a cloze card.
class ClozeSegment {
  const ClozeSegment(this.text, {this.isBlank = false, this.isAnswer = false});

  final String text;

  /// A hidden deletion shown as `[…]` / `[hint]` on the question side.
  final bool isBlank;

  /// A deletion revealed on the answer side (highlight it in the UI).
  final bool isAnswer;
}

List<ClozeSpan> parseCloze(String text) => <ClozeSpan>[
      for (final RegExpMatch m in _clozeRe.allMatches(text))
        ClozeSpan(
          start: m.start,
          end: m.end,
          index: int.parse(m.group(1)!),
          answer: m.group(2)!,
          hint: (m.group(3) == null || m.group(3)!.isEmpty) ? null : m.group(3),
        ),
    ];

bool hasCloze(String text) => _clozeRe.hasMatch(text);

/// Sorted distinct cloze numbers present in [text].
List<int> clozeIndices(String text) =>
    (parseCloze(text).map((ClozeSpan s) => s.index).toSet().toList()..sort());

/// The next free cloze number (max + 1, or 1).
int nextClozeIndex(String text) {
  final List<int> all = clozeIndices(text);
  return all.isEmpty ? 1 : all.last + 1;
}

/// Splits [text] into segments for display.
///
/// [activeIndex] null means "every deletion is active" (all hidden at once).
/// When [revealed] is false active deletions become blanks; when true they are
/// shown as highlighted answers. Non-active deletions are always plain text.
List<ClozeSegment> renderCloze(
  String text, {
  int? activeIndex,
  required bool revealed,
}) {
  final List<ClozeSegment> out = <ClozeSegment>[];
  int cursor = 0;
  for (final ClozeSpan s in parseCloze(text)) {
    if (s.start > cursor) out.add(ClozeSegment(text.substring(cursor, s.start)));
    final bool active = activeIndex == null || s.index == activeIndex;
    if (!active) {
      out.add(ClozeSegment(s.answer));
    } else if (revealed) {
      out.add(ClozeSegment(s.answer, isAnswer: true));
    } else {
      out.add(ClozeSegment(s.hint == null ? '[…]' : '[${s.hint}]',
          isBlank: true));
    }
    cursor = s.end;
  }
  if (cursor < text.length) out.add(ClozeSegment(text.substring(cursor)));
  return out;
}

/// The text with every cloze marker replaced by its answer.
String clozePlainText(String text) =>
    text.replaceAllMapped(_clozeRe, (Match m) => m.group(2)!);

/// Plain-text question for search/TTS: active deletions read as "blank".
String clozeQuestionText(String text, {int? activeIndex}) => renderCloze(
      text,
      activeIndex: activeIndex,
      revealed: false,
    ).map((ClozeSegment s) => s.isBlank ? 'blank' : s.text).join();

/// Wraps `[selStart, selEnd)` of [text] as cloze number [index].
/// Returns the new text and the caret position after the closing braces.
({String text, int caret}) wrapSelectionAsCloze(
  String text,
  int selStart,
  int selEnd,
  int index,
) {
  final int a = selStart.clamp(0, text.length);
  final int b = selEnd.clamp(a, text.length);
  final String selected = text.substring(a, b);
  final String wrapped = '{{c$index::$selected}}';
  return (
    text: text.replaceRange(a, b, wrapped),
    caret: a + wrapped.length,
  );
}

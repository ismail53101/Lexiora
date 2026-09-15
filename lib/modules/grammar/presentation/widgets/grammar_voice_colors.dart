import 'package:flutter/material.dart';

// Shared sentence-coloring for grammar lessons.
//
// Active Voice example sentences render in a clear blue; Passive Voice
// example sentences render in a bright-but-soft green. Both are theme-aware
// so they stay clearly readable on dark and light backgrounds without ever
// looking neon.

const Color _activeBlueDark = Color(0xFF64B5F6); // light blue on dark bg
const Color _activeBlueLight = Color(0xFF1976D2); // deeper blue on white bg
const Color _passiveGreenDark = Color(0xFF4ADE80); // soft bright green on dark
const Color _passiveGreenLight = Color(0xFF15803D); // deep green on white bg

/// Purple used for grammar headings and voice labels in tables.
const Color kGrammarHeadingPurple = Color(0xFFAB47BC);

/// Color for Active Voice example sentences in the current theme.
Color activeVoiceColor(BuildContext context) =>
    activeVoiceColorFor(Theme.of(context).brightness);

/// Color for Passive Voice example sentences in the current theme.
Color passiveVoiceColor(BuildContext context) =>
    passiveVoiceColorFor(Theme.of(context).brightness);

/// Brightness-based variants for widgets that only have a [ThemeData].
Color activeVoiceColorFor(Brightness brightness) =>
    brightness == Brightness.dark ? _activeBlueDark : _activeBlueLight;

Color passiveVoiceColorFor(Brightness brightness) =>
    brightness == Brightness.dark ? _passiveGreenDark : _passiveGreenLight;

final RegExp _urduChars = RegExp(r'[\u0600-\u06FF]');
final RegExp _beVerb = RegExp(
  r'\b(?:is|am|are|was|were|be|been|being)\b',
  caseSensitive: false,
);
final RegExp _byAgent = RegExp(r'\bby\s+\S+', caseSensitive: false);

/// True when the text reads like a passive-voice sentence
/// (a be-verb plus a "by …" agent, e.g. "A letter is written by Ali.").
/// Pattern/formula cells ("Object + is/am/are + V3 + by + Subject") never
/// match — they contain '+' and stay uncolored.
bool isPassiveVoiceSentence(String text) {
  final String value = text.replaceAll('**', '').replaceAll('__', '').trim();
  if (value.isEmpty || _urduChars.hasMatch(value) || value.contains('+')) {
    return false;
  }
  return _beVerb.hasMatch(value) && _byAgent.hasMatch(value);
}

/// True when the text reads like a plain English example sentence
/// (not a pattern/formula cell such as "Subject + V1 + Object").
bool looksLikeEnglishSentence(String text) {
  final String value = text.replaceAll('**', '').replaceAll('__', '').trim();
  if (value.isEmpty || _urduChars.hasMatch(value)) return false;
  if (value.contains('+') || value.contains('|')) return false;
  return value.endsWith('.') || value.endsWith('?') || value.endsWith('!');
}

final RegExp _pronounStart = RegExp(
  r'^(I|He|She|It|We|They|You|Ali|Sara|Ahmed|Amina|John|Do |Does |Did |Is |Are |Was |Were |Will |Has |Have |Had |The teacher|The boy|The girl|The students|The lesson|The door|English|Cricket|Dinner|A letter|The room|The homework)\b',
);

/// True when the text starts like a standalone example sentence
/// (pronoun/name/typical subject) — used to keep Active examples blue in
/// free-form text blocks without coloring ordinary explanations.
bool looksLikeExampleSentence(String text) {
  final String value = text.replaceAll('**', '').replaceAll('__', '').trim();
  if (value.isEmpty || _urduChars.hasMatch(value)) return false;
  return _pronounStart.hasMatch(value) &&
      (value.endsWith('.') || value.endsWith('?') || value.endsWith('!'));
}

/// Voice-aware example color: passive green for passive sentences,
/// otherwise the active blue.
Color voiceSentenceColor(BuildContext context, String text) =>
    isPassiveVoiceSentence(text)
        ? passiveVoiceColor(context)
        : activeVoiceColor(context);

/// Color for a grammar table body cell, derived from its column header and
/// cell text:
/// - a "Passive Voice" header column renders green ("Active Voice" → blue);
/// - an "Example" column colors each sentence by voice detection;
/// - "Active Voice"/"Passive Voice" label cells render in the heading purple.
Color? grammarTableCellColor(
  BuildContext context,
  List<String> headers,
  int index,
  String cell,
) {
  final String header =
      (index >= 0 && index < headers.length ? headers[index] : '')
          .toLowerCase();
  if (header.contains('example')) {
    if (isPassiveVoiceSentence(cell)) return passiveVoiceColor(context);
    if (looksLikeEnglishSentence(cell)) return activeVoiceColor(context);
    return null;
  }
  if (header.contains('passive')) return passiveVoiceColor(context);
  if (header.contains('active')) return activeVoiceColor(context);
  final String plain = cell.replaceAll('**', '').trim().toLowerCase();
  if (plain.startsWith('active voice') || plain.startsWith('passive voice')) {
    return kGrammarHeadingPurple;
  }
  if (isPassiveVoiceSentence(cell)) return passiveVoiceColor(context);
  return null;
}

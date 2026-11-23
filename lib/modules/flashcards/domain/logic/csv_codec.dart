import 'package:lexiora/modules/flashcards/domain/logic/cloze.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';

/// Minimal RFC-4180 style reader/writer for comma, tab or semicolon files
/// (Anki's "Notes in Plain Text" export is tab-separated).

/// Picks the delimiter that appears most in the first non-empty line.
String detectDelimiter(String text) {
  final String firstLine = text
      .split(RegExp(r'\r?\n'))
      .firstWhere((String l) => l.trim().isNotEmpty, orElse: () => '');
  int count(String ch) {
    int n = 0;
    bool inQuotes = false;
    for (int i = 0; i < firstLine.length; i++) {
      final String c = firstLine[i];
      if (c == '"') inQuotes = !inQuotes;
      if (!inQuotes && c == ch) n++;
    }
    return n;
  }

  final int tabs = count('\t'), commas = count(','), semis = count(';');
  if (tabs >= commas && tabs >= semis && tabs > 0) return '\t';
  if (semis > commas) return ';';
  return ',';
}

/// Parses [text] into rows. Quoted fields may contain delimiters, quotes
/// (doubled) and line breaks. Blank lines are skipped.
List<List<String>> parseDelimited(String text, {String? delimiter}) {
  final String sep = delimiter ?? detectDelimiter(text);
  final List<List<String>> rows = <List<String>>[];
  List<String> row = <String>[];
  final StringBuffer field = StringBuffer();
  bool inQuotes = false;
  bool fieldWasQuoted = false;

  void endField() {
    row.add(field.toString());
    field.clear();
    fieldWasQuoted = false;
  }

  void endRow() {
    endField();
    final bool blank = row.length == 1 && row.first.trim().isEmpty;
    if (!blank) rows.add(row);
    row = <String>[];
  }

  final String s = text.startsWith('\uFEFF') ? text.substring(1) : text;
  for (int i = 0; i < s.length; i++) {
    final String c = s[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < s.length && s[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"' && field.isEmpty && !fieldWasQuoted) {
      inQuotes = true;
      fieldWasQuoted = true;
    } else if (c == sep) {
      endField();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < s.length && s[i + 1] == '\n') i++;
      endRow();
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

String encodeDelimited(List<List<String>> rows, {String delimiter = ','}) {
  String cell(String v) {
    final bool needs = v.contains(delimiter) ||
        v.contains('"') ||
        v.contains('\n') ||
        v.contains('\r');
    return needs ? '"${v.replaceAll('"', '""')}"' : v;
  }

  return rows.map((List<String> r) => r.map(cell).join(delimiter)).join('\n');
}

/// A card parsed from an import file, before it gets an id.
class CardDraft {
  const CardDraft({
    required this.front,
    required this.back,
    this.type = FcCardType.basic,
    this.tags = const <String>[],
    this.notes,
  });

  final String front;
  final String back;
  final FcCardType type;
  final List<String> tags;
  final String? notes;
}

class DraftParseResult {
  const DraftParseResult(this.drafts, this.skipped);
  final List<CardDraft> drafts;

  /// Rows ignored because they had no usable front.
  final int skipped;
}

const Map<String, String> _headerAliases = <String, String>{
  'front': 'front', 'question': 'front', 'q': 'front', 'word': 'front',
  'term': 'front', 'prompt': 'front', 'text': 'front',
  'back': 'back', 'answer': 'back', 'a': 'back', 'definition': 'back',
  'meaning': 'back',
  'tags': 'tags', 'tag': 'tags', 'labels': 'tags',
  'notes': 'notes', 'note': 'notes', 'extra': 'notes', 'hint': 'notes',
  'type': 'type', 'kind': 'type',
};

/// Maps parsed rows to card drafts. A header row (front/back/tags/notes/type
/// in any order) is detected automatically; without one the columns are
/// front, back, tags, notes. Texts containing `{{c1::…}}` become cloze cards.
DraftParseResult draftsFromRows(List<List<String>> rows) {
  if (rows.isEmpty) return const DraftParseResult(<CardDraft>[], 0);

  final List<String> head =
      rows.first.map((String h) => h.trim().toLowerCase()).toList();
  final List<String?> mapped =
      head.map((String h) => _headerAliases[h]).toList();
  final bool hasHeader = mapped.contains('front') && mapped.contains('back');

  int idx(String key, int fallback) {
    if (hasHeader) return mapped.indexOf(key);
    return fallback;
  }

  final int fi = idx('front', 0);
  final int bi = idx('back', 1);
  final int ti = idx('tags', 2);
  final int ni = idx('notes', 3);
  final int yi = idx('type', -1);

  String at(List<String> r, int i) =>
      (i >= 0 && i < r.length) ? r[i].trim() : '';

  final List<CardDraft> out = <CardDraft>[];
  int skipped = 0;
  for (final List<String> r in hasHeader ? rows.skip(1) : rows) {
    final String front = at(r, fi);
    final String back = at(r, bi);
    if (front.isEmpty) {
      skipped++;
      continue;
    }
    final String typeText = at(r, yi).toLowerCase();
    FcCardType type = FcCardType.basic;
    if (hasCloze(front) || typeText == 'cloze') {
      type = FcCardType.cloze;
    } else if (typeText == 'typed' || typeText == 'type') {
      type = FcCardType.typed;
    }
    if (type != FcCardType.cloze && back.isEmpty) {
      skipped++;
      continue;
    }
    final List<String> tags = at(r, ti)
        .split(RegExp(r'[,; ]+'))
        .map((String t) => t.trim())
        .where((String t) => t.isNotEmpty)
        .toList();
    final String notes = at(r, ni);
    out.add(CardDraft(
      front: front,
      back: back,
      type: type,
      tags: tags,
      notes: notes.isEmpty ? null : notes,
    ));
  }
  return DraftParseResult(out, skipped);
}

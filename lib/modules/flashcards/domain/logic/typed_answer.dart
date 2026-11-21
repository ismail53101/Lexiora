/// Checking an answer the user typed (for "Type the answer" cards).
library;

enum TypedResult {
  /// Same text after ignoring case, accents-free punctuation and spacing.
  correct,

  /// One or two typos away.
  close,
  wrong,
}

final RegExp _punct = RegExp(r'[\s\p{P}\p{S}]+', unicode: true);

/// Lower-cases and removes punctuation/extra spaces so "  Paris! " == "paris".
String normaliseAnswer(String s) =>
    s.toLowerCase().replaceAll(_punct, ' ').trim();

/// Edit distance between two strings (insert / delete / substitute = 1).
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  List<int> prev = List<int>.generate(b.length + 1, (int i) => i);
  for (int i = 1; i <= a.length; i++) {
    final List<int> cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (int j = 1; j <= b.length; j++) {
      final int cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      int best = prev[j - 1] + cost;
      if (prev[j] + 1 < best) best = prev[j] + 1;
      if (cur[j - 1] + 1 < best) best = cur[j - 1] + 1;
      cur[j] = best;
    }
    prev = cur;
  }
  return prev[b.length];
}

TypedResult checkTypedAnswer(String typed, String expected) {
  final String a = normaliseAnswer(typed);
  final List<String> accepted = expected
      .split('|')
      .map(normaliseAnswer)
      .where((String s) => s.isNotEmpty)
      .toList();
  if (a.isEmpty || accepted.isEmpty) return TypedResult.wrong;
  for (final String b in accepted) {
    if (a == b) return TypedResult.correct;
  }
  int best = 999999;
  int bestLength = 0;
  for (final String b in accepted) {
    final int d = levenshtein(a, b);
    if (d < best) {
      best = d;
      bestLength = b.length;
    }
  }
  final int allowed = bestLength <= 4 ? 0 : (bestLength <= 9 ? 1 : 2);
  return best <= allowed ? TypedResult.close : TypedResult.wrong;
}

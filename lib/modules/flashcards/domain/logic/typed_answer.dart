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
  final String b = normaliseAnswer(expected);
  if (a.isEmpty) return TypedResult.wrong;
  if (a == b) return TypedResult.correct;
  final int d = levenshtein(a, b);
  final int allowed = b.length <= 4 ? 0 : (b.length <= 9 ? 1 : 2);
  return d <= allowed ? TypedResult.close : TypedResult.wrong;
}

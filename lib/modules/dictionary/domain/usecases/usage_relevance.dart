import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';

/// Returns whether [sentence] contains the searched [headword] or a normal
/// grammatical form of it. Synonyms are intentionally not accepted: a usage
/// example must be attributable to the displayed headword itself.
bool usageContainsHeadword(String headword, String sentence) {
  final String h = _clean(headword);
  if (h.isEmpty || sentence.trim().isEmpty) return false;

  final List<String> headwordParts = _tokens(h);
  final List<String> sentenceTokens = _tokens(sentence);
  if (headwordParts.isEmpty || sentenceTokens.isEmpty) return false;

  // Multi-word headwords must appear as a contiguous phrase, allowing normal
  // punctuation between words.
  if (headwordParts.length > 1) {
    for (int i = 0; i <= sentenceTokens.length - headwordParts.length; i++) {
      bool matches = true;
      for (int j = 0; j < headwordParts.length; j++) {
        if (!_sameLexeme(headwordParts[j], sentenceTokens[i + j])) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  return sentenceTokens.any((String token) => _sameLexeme(headwordParts.first, token));
}

/// Returns [usage] only when it is a real sentence and belongs to [headword].
WordUsage? validatedUsage(String headword, WordUsage? usage) {
  if (usage == null || usage.english.trim().isEmpty) return null;
  final int words = _tokens(usage.english).length;
  if (words < 3 || !usageContainsHeadword(headword, usage.english)) return null;
  return usage;
}

String _clean(String value) => value.trim().toLowerCase();

List<String> _tokens(String value) => RegExp(r"[a-z]+(?:['’-][a-z]+)?")
    .allMatches(_clean(value))
    .map((Match m) => m.group(0)!.replaceAll('’', "'"))
    .toList(growable: false);

bool _sameLexeme(String headword, String token) {
  final Set<String> headForms = _forms(headword);
  final Set<String> tokenForms = _forms(token);
  return headForms.intersection(tokenForms).isNotEmpty;
}

Set<String> _forms(String value) {
  final String word = _clean(value).replaceAll(RegExp(r"['’-]"), '');
  final Set<String> forms = <String>{word};
  if (word.length < 4) return forms;

  if (word.endsWith('ies') && word.length > 4) forms.add('${word.substring(0, word.length - 3)}y');
  if (word.endsWith('es') && word.length > 4) forms.add(word.substring(0, word.length - 2));
  if (word.endsWith('s') && word.length > 3) forms.add(word.substring(0, word.length - 1));
  if (word.endsWith('ied') && word.length > 5) forms.add('${word.substring(0, word.length - 3)}y');
  if (word.endsWith('ed') && word.length > 4) forms.add(word.substring(0, word.length - 2));
  if (word.endsWith('ing') && word.length > 5) forms.add(word.substring(0, word.length - 3));
  if (word.endsWith('er') && word.length > 5) forms.add(word.substring(0, word.length - 2));
  if (word.endsWith('or') && word.length > 5) forms.add(word.substring(0, word.length - 2));
  if (word.endsWith('ly') && word.length > 5) forms.add(word.substring(0, word.length - 2));

  final List<String> snapshot = forms.toList(growable: false);
  for (final String form in snapshot) {
    if (form.endsWith('e') && form.length > 4) forms.add(form.substring(0, form.length - 1));
  }
  return forms;
}

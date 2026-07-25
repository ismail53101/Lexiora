import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';

/// A contiguous A–Z section of words that share the same first [letter].
class VocabularySection {
  const VocabularySection(this.letter, this.words);
  final String letter;
  final List<VocabularyWord> words;
}

/// Pure, instant filter over [words] by [query], matching the English word OR
/// the Urdu meaning. Order is preserved. Empty query returns [words] unchanged.
List<VocabularyWord> filterVocabulary(
  List<VocabularyWord> words,
  String query,
) {
  final String q = query.trim();
  if (q.isEmpty) return words;
  return words
      .where((VocabularyWord w) => w.matches(q))
      .toList(growable: false);
}

/// Groups an already-ordered [words] list into A–Z sections, preserving order.
/// Assumes [words] is sorted so words of the same letter are contiguous.
List<VocabularySection> groupByLetter(List<VocabularyWord> words) {
  final List<VocabularySection> out = <VocabularySection>[];
  String? current;
  List<VocabularyWord> bucket = <VocabularyWord>[];
  for (final VocabularyWord w in words) {
    if (w.letter != current) {
      if (current != null && bucket.isNotEmpty) {
        out.add(VocabularySection(current, bucket));
      }
      current = w.letter;
      bucket = <VocabularyWord>[];
    }
    bucket.add(w);
  }
  if (current != null && bucket.isNotEmpty) {
    out.add(VocabularySection(current, bucket));
  }
  return out;
}

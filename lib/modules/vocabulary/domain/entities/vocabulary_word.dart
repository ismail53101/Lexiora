import 'package:equatable/equatable.dart';

/// A single vocabulary word — a learning card, not a dictionary entry.
///
/// Holds only what the Vocabulary module shows: the English [word], its [ipa]
/// pronunciation, a short [urduMeaning], a short [englishMeaning], and the
/// [partOfSpeech]. Richer data (examples, synonyms, idioms, …) is the
/// Dictionary module's concern.
class VocabularyWord extends Equatable {
  const VocabularyWord({
    required this.id,
    required this.listId,
    required this.word,
    required this.letter,
    required this.urduMeaning,
    required this.englishMeaning,
    this.ipa,
    this.partOfSpeech,
  });

  final String id;
  final String listId;
  final String word;

  /// Uppercase A–Z bucket (or `#`) used for section headers and the jump rail.
  final String letter;
  final String urduMeaning;
  final String englishMeaning;
  final String? ipa;
  final String? partOfSpeech;

  /// Instant, case-insensitive match on the English word OR the Urdu meaning.
  /// Empty query matches everything.
  bool matches(String query) {
    final String q = query.trim();
    if (q.isEmpty) return true;
    return word.toLowerCase().contains(q.toLowerCase()) ||
        urduMeaning.contains(q);
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        listId,
        word,
        letter,
        urduMeaning,
        englishMeaning,
        ipa,
        partOfSpeech,
      ];
}

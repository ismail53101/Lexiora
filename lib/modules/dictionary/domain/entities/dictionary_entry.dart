import 'package:equatable/equatable.dart';

/// A single dictionary **sense** — one meaning of a word, with its grammatical
/// category and (when available) an IPA pronunciation and example sentence.
///
/// A headword with several meanings is represented by several [DictionaryEntry]
/// instances that share the same [word].
class DictionaryEntry extends Equatable {
  const DictionaryEntry({
    required this.id,
    required this.word,
    required this.meaning,
    this.partOfSpeech,
    this.ipaPronunciation,
    this.exampleSentence,
  });

  final int id;
  final String word;
  final String meaning;
  final String? partOfSpeech;
  final String? ipaPronunciation;
  final String? exampleSentence;

  @override
  List<Object?> get props =>
      [id, word, meaning, partOfSpeech, ipaPronunciation, exampleSentence];
}

/// A headword summary used in search results and the favorites list: one item
/// per word, with a representative part of speech and meaning, the number of
/// senses, and whether the word is saved.
class DictionaryResult extends Equatable {
  const DictionaryResult({
    required this.word,
    required this.wordLower,
    required this.meaning,
    required this.isFavorite,
    this.partOfSpeech,
    this.senseCount = 1,
  });

  final String word;
  final String wordLower;
  final String meaning;
  final bool isFavorite;
  final String? partOfSpeech;

  /// Number of senses for this headword (1 when unknown, e.g. in favorites).
  final int senseCount;

  @override
  List<Object?> get props =>
      [word, wordLower, meaning, isFavorite, partOfSpeech, senseCount];
}

/// Full details for a single headword: every sense plus the saved state.
class WordDetails extends Equatable {
  const WordDetails({
    required this.word,
    required this.wordLower,
    required this.senses,
    required this.isFavorite,
  });

  final String word;
  final String wordLower;
  final List<DictionaryEntry> senses;
  final bool isFavorite;

  DictionaryEntry? get primary => senses.isEmpty ? null : senses.first;

  /// IPA taken from the first sense that has one, when present.
  String? get ipaPronunciation {
    for (final DictionaryEntry s in senses) {
      final String? ipa = s.ipaPronunciation;
      if (ipa != null && ipa.isNotEmpty) return ipa;
    }
    return null;
  }

  @override
  List<Object?> get props => [word, wordLower, senses, isFavorite];
}

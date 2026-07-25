import 'package:equatable/equatable.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';

/// An additional distinct sense of a word (Dictionary v2 "Other meanings").
class OtherMeaning extends Equatable {
  const OtherMeaning({required this.urdu, this.english});

  final List<String> urdu;
  final String? english;

  @override
  List<Object?> get props => <Object?>[urdu, english];
}

/// A single, exam-relevant usage example with its context tag and translation.
class WordUsage extends Equatable {
  const WordUsage({
    required this.context,
    required this.english,
    required this.urdu,
  });

  /// e.g. "Economic", "Governance", "Legal".
  final String context;
  final String english;
  final String urdu;

  @override
  List<Object?> get props => <Object?>[context, english, urdu];
}

/// Curated, exam-oriented content for a word (from the bundled exam pack).
///
/// Every list is non-null (possibly empty) and optional scalars are nullable, so
/// the UI can simply hide sections that have no data.
class ExamWordData extends Equatable {
  const ExamWordData({
    required this.word,
    this.urduMeanings = const <String>[],
    this.englishDefinition,
    this.pronunciation,
    this.pronunciationUk,
    this.pronunciationUs,
    this.partOfSpeech,
    this.otherMeanings = const <OtherMeaning>[],
    this.synonyms = const <String>[],
    this.antonyms = const <String>[],
    this.usage,
    this.collocations = const <String>[],
    this.wordForms = const <String>[],
    this.idioms = const <String>[],
    this.examNote,
  });

  final String word;
  final List<String> urduMeanings;
  final String? englishDefinition;
  final String? pronunciation;

  /// Optional accent-specific IPA (shown when available; "prefer both").
  final String? pronunciationUk;
  final String? pronunciationUs;
  final String? partOfSpeech;
  final List<OtherMeaning> otherMeanings;
  final List<String> synonyms;
  final List<String> antonyms;
  final WordUsage? usage;
  final List<String> collocations;
  final List<String> wordForms;
  final List<String> idioms;
  final String? examNote;

  @override
  List<Object?> get props => <Object?>[
        word,
        urduMeanings,
        englishDefinition,
        pronunciation,
        pronunciationUk,
        pronunciationUs,
        partOfSpeech,
        otherMeanings,
        synonyms,
        antonyms,
        usage,
        collocations,
        wordForms,
        idioms,
        examNote,
      ];
}

/// The aggregated, offline word profile the Word Details screen renders.
///
/// Combines the curated exam data (when present), the base dictionary senses
/// (definition/POS/example/IPA), and locally-derived related words. Urdu
/// meanings and the bookmark state are supplied reactively by dedicated
/// providers (hybrid translation + favorites) rather than baked in here.
class WordProfile extends Equatable {
  const WordProfile({
    required this.word,
    required this.wordLower,
    this.exam,
    this.base,
    this.relatedWords = const <String>[],
  });

  final String word;
  final String wordLower;
  final ExamWordData? exam;
  final WordDetails? base;
  final List<String> relatedWords;

  /// True when the word exists in any local data set (base or curated).
  bool get existsLocally => base != null || exam != null;

  /// Best display headword: the exam pack's casing, else the base word, else the
  /// lowercased search term.
  String get displayWord => exam?.word ?? base?.word ?? word;

  /// English definition: curated first, then the base primary sense.
  String? get englishDefinition =>
      exam?.englishDefinition ?? base?.primary?.meaning;

  /// Pronunciation (IPA): curated first, then the base IPA when present.
  String? get pronunciation => exam?.pronunciation ?? base?.ipaPronunciation;

  /// Part of speech: curated first, then the base primary sense.
  String? get partOfSpeech =>
      exam?.partOfSpeech ?? base?.primary?.partOfSpeech;

  @override
  List<Object?> get props =>
      <Object?>[word, wordLower, exam, base, relatedWords];
}

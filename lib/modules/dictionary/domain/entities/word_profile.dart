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

/// Structured content returned by the direct AI dictionary lookup.
///
/// It is kept separate from curated [ExamWordData] so an AI failure never
/// damages or overwrites the bundled offline content.
class AiWordProfile extends Equatable {
  const AiWordProfile({
    required this.word,
    this.source = 'ai',
    this.englishDefinition,
    this.urduMeanings = const <String>[],
    this.partOfSpeech,
    this.synonyms = const <String>[],
    this.antonyms = const <String>[],
    this.exampleSentence,
    this.exampleSentenceUrdu,
    this.collocations = const <String>[],
    this.wordForms = const <String>[],
    this.examNote,
  });

  factory AiWordProfile.fromJson(Map<String, dynamic> json) => AiWordProfile(
        word: json['word']?.toString() ?? '',
        source: json['source']?.toString() ?? 'ai',
        englishDefinition: _text(json['englishDefinition']),
        urduMeanings: _strings(json['urduMeanings']),
        partOfSpeech: _text(json['partOfSpeech']),
        synonyms: _strings(json['synonyms']),
        antonyms: _strings(json['antonyms']),
        exampleSentence: _text(json['exampleSentence']),
        exampleSentenceUrdu: _text(json['exampleSentenceUrdu']),
        collocations: _strings(json['collocations']),
        wordForms: _strings(json['wordForms']),
        examNote: _text(json['examNote']),
      );

  final String word;
  final String source;
  final String? englishDefinition;
  final List<String> urduMeanings;
  final String? partOfSpeech;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? exampleSentence;
  final String? exampleSentenceUrdu;
  final List<String> collocations;
  final List<String> wordForms;
  final String? examNote;

  bool get hasContent =>
      englishDefinition != null ||
      urduMeanings.isNotEmpty ||
      synonyms.isNotEmpty ||
      antonyms.isNotEmpty ||
      exampleSentence != null ||
      collocations.isNotEmpty ||
      wordForms.isNotEmpty ||
      examNote != null;

  @override
  List<Object?> get props => <Object?>[
        word,
        source,
        englishDefinition,
        urduMeanings,
        partOfSpeech,
        synonyms,
        antonyms,
        exampleSentence,
        exampleSentenceUrdu,
        collocations,
        wordForms,
        examNote,
      ];

  static String? _text(Object? value) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((Object? item) => item?.toString().trim() ?? '')
        .where((String item) => item.isNotEmpty)
        .take(8)
        .toList(growable: false);
  }
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
    this.ai,
  });

  final String word;
  final String wordLower;
  final ExamWordData? exam;
  final WordDetails? base;
  final List<String> relatedWords;
  final AiWordProfile? ai;

  WordProfile copyWith({AiWordProfile? ai}) => WordProfile(
        word: word,
        wordLower: wordLower,
        exam: exam,
        base: base,
        relatedWords: relatedWords,
        ai: ai ?? this.ai,
      );

  /// True when the word exists in any local data set (base or curated).
  bool get existsLocally => base != null || exam != null;

  /// Best display headword: the exam pack's casing, else the base word, else the
  /// lowercased search term.
  String get displayWord => exam?.word ?? base?.word ?? word;

  /// English definition: curated first, then the base primary sense.
  String? get englishDefinition =>
      exam?.englishDefinition ?? ai?.englishDefinition ?? base?.primary?.meaning;

  /// Pronunciation (IPA): curated first, then the base IPA when present.
  String? get pronunciation => exam?.pronunciation ?? base?.ipaPronunciation;

  /// Part of speech: curated first, then the base primary sense.
  String? get partOfSpeech =>
      exam?.partOfSpeech ?? ai?.partOfSpeech ?? base?.primary?.partOfSpeech;

  List<String> get synonyms =>
      exam?.synonyms.isNotEmpty == true ? exam!.synonyms : ai?.synonyms ?? const <String>[];

  List<String> get antonyms =>
      exam?.antonyms.isNotEmpty == true ? exam!.antonyms : ai?.antonyms ?? const <String>[];

  List<String> get collocations => exam?.collocations.isNotEmpty == true
      ? exam!.collocations
      : ai?.collocations ?? const <String>[];

  String? get examNote => exam?.examNote ?? ai?.examNote;

  @override
  List<Object?> get props =>
      <Object?>[word, wordLower, exam, base, relatedWords, ai];
}

import 'package:equatable/equatable.dart';

/// How far the user has progressed through a lesson. The [index] is persisted.
enum GrammarProgressStatus {
  notStarted,
  inProgress,
  completed;

  static GrammarProgressStatus fromIndex(int? value) {
    if (value == null ||
        value < 0 ||
        value >= GrammarProgressStatus.values.length) {
      return GrammarProgressStatus.notStarted;
    }
    return GrammarProgressStatus.values[value];
  }
}

/// A worked example: the example [text], an optional [urdu] translation, plus
/// an optional short [note].
class GrammarExample extends Equatable {
  const GrammarExample({required this.text, this.urdu, this.note});
  final String text;

  /// Urdu translation of [text], shown right-to-left beneath it. Optional.
  final String? urdu;
  final String? note;
  @override
  List<Object?> get props => <Object?>[text, urdu, note];
}

/// A common mistake: an incorrect form paired with its correction.
class GrammarMistake extends Equatable {
  const GrammarMistake({required this.wrong, required this.right, this.note});
  final String wrong;
  final String right;
  final String? note;
  @override
  List<Object?> get props => <Object?>[wrong, right, note];
}

/// A multiple-choice question (used for both Practice and Quiz).
class GrammarQuestion extends Equatable {
  const GrammarQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
    this.explanation,
  });
  final String question;
  final List<String> options;
  final int answerIndex;
  final String? explanation;

  String get answer =>
      (answerIndex >= 0 && answerIndex < options.length) ? options[answerIndex] : '';

  @override
  List<Object?> get props =>
      <Object?>[question, options, answerIndex, explanation];
}

/// A named sub-type or structural note within a lesson (e.g. "Proper Noun",
/// or a tense's "Structure").
class GrammarType extends Equatable {
  const GrammarType({
    required this.name,
    required this.description,
    this.urduExplanation = '',
    this.subjectVerbAgreement = '',
    this.examples = const <GrammarExample>[],
    this.rules = const <String>[],
    this.commonMistakes = const <GrammarMistake>[],
    this.practice = const <GrammarQuestion>[],
  });

  final String name;
  final String description;
  final String urduExplanation;
  final String subjectVerbAgreement;
  final List<GrammarExample> examples;
  final List<String> rules;
  final List<GrammarMistake> commonMistakes;
  final List<GrammarQuestion> practice;

  bool get hasDetailedContent =>
      urduExplanation.isNotEmpty ||
      subjectVerbAgreement.isNotEmpty ||
      examples.isNotEmpty ||
      rules.isNotEmpty ||
      commonMistakes.isNotEmpty ||
      practice.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[
        name,
        description,
        urduExplanation,
        subjectVerbAgreement,
        examples,
        rules,
        commonMistakes,
        practice,
      ];
}

/// A single dedicated grammar lesson (a leaf in the topic tree). Sections that
/// are empty are hidden by the UI. Every field is non-null (possibly empty).
class GrammarLesson extends Equatable {
  const GrammarLesson({
    required this.id,
    required this.title,
    this.introduction = '',
    this.urduExplanation = '',
    this.englishExplanation = '',
    this.types = const <GrammarType>[],
    this.rules = const <String>[],
    this.structure = const <String>[],
    this.examples = const <GrammarExample>[],
    this.commonMistakes = const <GrammarMistake>[],
    this.examTips = const <String>[],
    this.practice = const <GrammarQuestion>[],
    this.quiz = const <GrammarQuestion>[],
    this.summary = '',
  });

  final String id;
  final String title;
  final String introduction;
  final String urduExplanation;
  final String englishExplanation;
  final List<GrammarType> types;
  final List<String> rules;

  /// The structural pattern/formula for this topic (e.g. "Subject + can + V1"),
  /// shown where applicable. Optional — empty for lessons that don't need it.
  final List<String> structure;
  final List<GrammarExample> examples;
  final List<GrammarMistake> commonMistakes;

  /// Exam-focused tips for CSS/PMS/BPSC/FPSC/IELTS. Optional.
  final List<String> examTips;
  final List<GrammarQuestion> practice;
  final List<GrammarQuestion> quiz;
  final String summary;

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        introduction,
        urduExplanation,
        englishExplanation,
        types,
        rules,
        structure,
        examples,
        commonMistakes,
        examTips,
        practice,
        quiz,
        summary,
      ];
}

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
  const GrammarExample({required this.text, this.urdu, this.note, this.referenceText, this.referenceUrdu});
  final String text;

  /// Urdu translation of [text], shown right-to-left beneath it. Optional.
  final String? urdu;
  final String? note;

  /// Optional noun-based reference sentence shown before a Pronoun example.
  final String? referenceText;
  final String? referenceUrdu;
  @override
  List<Object?> get props => <Object?>[text, urdu, note, referenceText, referenceUrdu];
}

/// A common mistake: an incorrect form paired with its correction.
class GrammarMistake extends Equatable {
  const GrammarMistake({required this.wrong, required this.right, this.note, this.urdu});
  final String wrong;
  final String right;
  final String? note;
  final String? urdu;
  @override
  List<Object?> get props => <Object?>[wrong, right, note, urdu];
}

/// A multiple-choice question (used for both Practice and Quiz).
class GrammarPronounRow extends Equatable {
  const GrammarPronounRow({required this.person, required this.subject, required this.object});
  final String person;
  final String subject;
  final String object;

  @override
  List<Object?> get props => <Object?>[person, subject, object];
}

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

class GrammarTableRow extends Equatable {
  const GrammarTableRow({required this.cells});
  final List<String> cells;
  @override
  List<Object?> get props => <Object?>[cells];
}

/// A named sub-type or structural note within a lesson (e.g. "Proper Noun",
/// or a tense's "Structure").
class GrammarTableGroup extends Equatable {
  const GrammarTableGroup({
    required this.title,
    this.columns = const <String>[],
    this.rows = const <GrammarTableRow>[],
  });

  final String title;
  final List<String> columns;
  final List<GrammarTableRow> rows;

  @override
  List<Object?> get props => <Object?>[title, columns, rows];
}

class GrammarType extends Equatable {
  const GrammarType({
    required this.name,
    required this.description,
    this.urduExplanation = '',
    this.wordFocus = '',
    this.exampleWords = '',
    this.pronounTable = const <GrammarPronounRow>[],
    this.tableTitle = '',
    this.tableColumns = const <String>[],
    this.tableRows = const <GrammarTableRow>[],
    this.tableGroups = const <GrammarTableGroup>[],
    this.childTypes = const <GrammarType>[],
    this.subjectVerbAgreement = '',
    this.subjectVerbAgreementUrdu = '',
    this.examples = const <GrammarExample>[],
    this.rules = const <String>[],
    this.ruleExamples = const <String>[],
    this.commonMistakes = const <GrammarMistake>[],
    this.practice = const <GrammarQuestion>[],
  });

  final String name;
  final String description;
  final String urduExplanation;
  final String wordFocus;
  /// Short category-specific words shown after the English and Urdu definitions.
  final String exampleWords;
  final List<GrammarPronounRow> pronounTable;
  final String tableTitle;
  final List<String> tableColumns;
  final List<GrammarTableRow> tableRows;
  final List<GrammarTableGroup> tableGroups;
  final List<GrammarType> childTypes;
  final String subjectVerbAgreement;
  final String subjectVerbAgreementUrdu;
  final List<GrammarExample> examples;
  final List<String> rules;
  /// Optional example sentence aligned by index with [rules].
  final List<String> ruleExamples;
  final List<GrammarMistake> commonMistakes;
  final List<GrammarQuestion> practice;

  bool get hasDetailedContent =>
      urduExplanation.isNotEmpty ||
      wordFocus.isNotEmpty ||
      pronounTable.isNotEmpty ||
      tableRows.isNotEmpty ||
      tableGroups.isNotEmpty ||
      childTypes.isNotEmpty ||
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
        wordFocus,
        exampleWords,
        pronounTable,
        tableTitle,
        tableColumns,
        tableRows,
        tableGroups,
        childTypes,
        subjectVerbAgreement,
        subjectVerbAgreementUrdu,
        examples,
        rules,
        ruleExamples,
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
    this.additionalTypes = const <GrammarType>[],
    this.degreeTypes = const <GrammarType>[],
    this.degreeNote = '',
    this.degreeExamples = const <String>[],
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
  final List<GrammarType> additionalTypes;
  final List<GrammarType> degreeTypes;
  final String degreeNote;
  final List<String> degreeExamples;
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
        additionalTypes,
        degreeTypes,
        degreeNote,
        degreeExamples,
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

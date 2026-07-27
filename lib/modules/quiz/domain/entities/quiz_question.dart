import 'package:equatable/equatable.dart';

/// The universal question type. MCQ (single), True/False and Fill-in-the-Blank
/// are supported now; [matching] and [multiCorrect] are reserved for later and
/// are intentionally NOT graded in this version.
enum QuestionType {
  mcqSingle,
  trueFalse,
  fillBlank,
  matching, // reserved — architecture only
  multiCorrect; // reserved — architecture only

  static QuestionType fromIndex(int? i) =>
      (i == null || i < 0 || i >= QuestionType.values.length)
          ? QuestionType.mcqSingle
          : QuestionType.values[i];

  /// Whether this version implements grading/rendering for the type.
  bool get isImplemented =>
      this == QuestionType.mcqSingle ||
      this == QuestionType.trueFalse ||
      this == QuestionType.fillBlank;

  String get label => switch (this) {
        QuestionType.mcqSingle => 'Multiple choice',
        QuestionType.trueFalse => 'True / False',
        QuestionType.fillBlank => 'Fill in the blank',
        QuestionType.matching => 'Matching',
        QuestionType.multiCorrect => 'Multi-correct',
      };

  String get shortLabel => switch (this) {
        QuestionType.mcqSingle => 'MCQ',
        QuestionType.trueFalse => 'T/F',
        QuestionType.fillBlank => 'Blank',
        QuestionType.matching => 'Match',
        QuestionType.multiCorrect => 'Multi',
      };
}

/// User-set difficulty (also carried from imported content).
enum QuizDifficulty {
  none,
  easy,
  medium,
  hard;

  static QuizDifficulty fromIndex(int? i) =>
      (i == null || i < 0 || i >= QuizDifficulty.values.length)
          ? QuizDifficulty.none
          : QuizDifficulty.values[i];

  String get label => switch (this) {
        QuizDifficulty.none => 'None',
        QuizDifficulty.easy => 'Easy',
        QuizDifficulty.medium => 'Medium',
        QuizDifficulty.hard => 'Hard',
      };
}

/// A user's answer to a question, in a single uniform shape across types.
class QuizGivenAnswer extends Equatable {
  const QuizGivenAnswer({this.index, this.boolValue, this.text, this.indexes});

  const QuizGivenAnswer.choice(int index)
      : this(index: index);
  const QuizGivenAnswer.boolean(bool value)
      : this(boolValue: value);
  const QuizGivenAnswer.blank(String text)
      : this(text: text);

  final int? index; // mcqSingle
  final bool? boolValue; // trueFalse
  final String? text; // fillBlank
  final List<int>? indexes; // multiCorrect (reserved)

  bool get isEmpty =>
      index == null &&
      boolValue == null &&
      (text == null || text!.trim().isEmpty) &&
      (indexes == null || indexes!.isEmpty);

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (index != null) 'index': index,
        if (boolValue != null) 'bool': boolValue,
        if (text != null) 'text': text,
        if (indexes != null) 'indexes': indexes,
      };

  static QuizGivenAnswer? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    return QuizGivenAnswer(
      index: m['index'] as int?,
      boolValue: m['bool'] as bool?,
      text: m['text'] as String?,
      indexes: (m['indexes'] as List<dynamic>?)?.map((dynamic e) => e as int).toList(),
    );
  }

  @override
  List<Object?> get props => <Object?>[index, boolValue, text, indexes];
}

/// A universal, immutable question. The answer is exposed as typed, nullable
/// fields chosen by [type]; the engine never hardcodes any content.
class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.id,
    required this.bankId,
    required this.type,
    required this.prompt,
    required this.createdAt,
    required this.updatedAt,
    this.options = const <String>[],
    this.answerIndex,
    this.answerBool,
    this.answerTexts = const <String>[],
    this.answerIndexes = const <int>[],
    this.explanation,
    this.subject,
    this.topic,
    this.tags,
    this.difficulty = QuizDifficulty.none,
    this.bookmarked = false,
    this.externalId,
    this.subjectId,
    this.topicId,
  });

  final String id;
  final String bankId;
  final QuestionType type;
  final String prompt;
  final List<String> options;

  final int? answerIndex; // mcqSingle
  final bool? answerBool; // trueFalse
  final List<String> answerTexts; // fillBlank (accepted answers)
  final List<int> answerIndexes; // multiCorrect (reserved)

  final String? explanation;
  final String? subject;
  final String? topic;
  final String? tags;
  final QuizDifficulty difficulty;
  final bool bookmarked;
  final String? externalId;

  /// Links into the Subject → Topic hierarchy (v0.9.1).
  final String? subjectId;
  final String? topicId;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<String> get tagList => (tags ?? '')
      .split(',')
      .map((String t) => t.trim())
      .where((String t) => t.isNotEmpty)
      .toList();

  /// Pure grading. Reserved types ([matching], [multiCorrect]) are not graded in
  /// this version and always return false.
  bool isCorrect(QuizGivenAnswer given) {
    switch (type) {
      case QuestionType.mcqSingle:
        return given.index != null && given.index == answerIndex;
      case QuestionType.trueFalse:
        return given.boolValue != null && given.boolValue == answerBool;
      case QuestionType.fillBlank:
        final String? g = given.text?.trim().toLowerCase();
        if (g == null || g.isEmpty) return false;
        return answerTexts.any((String a) => a.trim().toLowerCase() == g);
      case QuestionType.matching:
      case QuestionType.multiCorrect:
        return false; // reserved — not implemented this version
    }
  }

  QuizQuestion copyWith({
    QuestionType? type,
    String? prompt,
    List<String>? options,
    int? answerIndex,
    bool? answerBool,
    List<String>? answerTexts,
    List<int>? answerIndexes,
    String? explanation,
    String? subject,
    String? topic,
    String? tags,
    QuizDifficulty? difficulty,
    bool? bookmarked,
    String? subjectId,
    String? topicId,
    DateTime? updatedAt,
  }) {
    return QuizQuestion(
      id: id,
      bankId: bankId,
      type: type ?? this.type,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      answerIndex: answerIndex ?? this.answerIndex,
      answerBool: answerBool ?? this.answerBool,
      answerTexts: answerTexts ?? this.answerTexts,
      answerIndexes: answerIndexes ?? this.answerIndexes,
      explanation: explanation ?? this.explanation,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      bookmarked: bookmarked ?? this.bookmarked,
      externalId: externalId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, bankId, type, prompt, options, answerIndex, answerBool, answerTexts,
        answerIndexes, explanation, subject, topic, tags, difficulty, bookmarked,
        externalId, subjectId, topicId, createdAt, updatedAt,
      ];
}

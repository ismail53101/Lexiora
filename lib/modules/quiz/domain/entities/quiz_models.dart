import 'package:equatable/equatable.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';

/// How a quiz session behaves. Only the two shells exist in this foundation —
/// content and per-mode rules are layered on later.
enum QuizMode {
  practice,
  exam;

  static QuizMode fromIndex(int? i) =>
      (i == null || i < 0 || i >= QuizMode.values.length)
          ? QuizMode.practice
          : QuizMode.values[i];

  String get label => switch (this) {
        QuizMode.practice => 'Practice',
        QuizMode.exam => 'Exam',
      };

  String get description => switch (this) {
        QuizMode.practice => 'Instant feedback, no timer pressure.',
        QuizMode.exam => 'Answer all, then see your score.',
      };
}

enum QuizSort {
  recent,
  alphabetical;

  String get label => switch (this) {
        QuizSort.recent => 'Recently added',
        QuizSort.alphabetical => 'Alphabetical',
      };
}

/// A composable browse/search filter over questions. All fields combine (AND).
class QuizFilter extends Equatable {
  const QuizFilter({
    this.query = '',
    this.bankId,
    this.subjectId,
    this.topicId,
    this.subject,
    this.topic,
    this.tag,
    this.type,
    this.difficulty,
    this.onlyBookmarked = false,
    this.onlyWrong = false,
    this.createdAfter,
    this.sort = QuizSort.recent,
  });

  final String query;
  final String? bankId;
  final String? subjectId;
  final String? topicId;
  final String? subject;
  final String? topic;
  final String? tag;
  final QuestionType? type;
  final QuizDifficulty? difficulty;
  final bool onlyBookmarked;
  final bool onlyWrong;
  final DateTime? createdAfter;
  final QuizSort sort;

  QuizFilter copyWith({
    String? query,
    String? bankId,
    String? subjectId,
    String? topicId,
    String? subject,
    String? topic,
    String? tag,
    QuestionType? type,
    QuizDifficulty? difficulty,
    bool? onlyBookmarked,
    bool? onlyWrong,
    DateTime? createdAfter,
    QuizSort? sort,
    bool clearBank = false,
    bool clearSubjectId = false,
    bool clearTopicId = false,
    bool clearSubject = false,
    bool clearTopic = false,
    bool clearTag = false,
    bool clearType = false,
    bool clearDifficulty = false,
    bool clearCreatedAfter = false,
  }) {
    return QuizFilter(
      query: query ?? this.query,
      bankId: clearBank ? null : (bankId ?? this.bankId),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      subject: clearSubject ? null : (subject ?? this.subject),
      topic: clearTopic ? null : (topic ?? this.topic),
      tag: clearTag ? null : (tag ?? this.tag),
      type: clearType ? null : (type ?? this.type),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      onlyBookmarked: onlyBookmarked ?? this.onlyBookmarked,
      onlyWrong: onlyWrong ?? this.onlyWrong,
      createdAfter: clearCreatedAfter ? null : (createdAfter ?? this.createdAfter),
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        query, bankId, subjectId, topicId, subject, topic, tag, type, difficulty,
        onlyBookmarked, onlyWrong, createdAfter, sort,
      ];
}

/// One quiz attempt / result.
class QuizAttempt extends Equatable {
  const QuizAttempt({
    required this.id,
    required this.mode,
    required this.totalQuestions,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.startedAt,
    required this.durationMs,
    this.bankId,
    this.title,
    this.finishedAt,
  });

  final String id;
  final String? bankId;
  final QuizMode mode;
  final String? title;
  final int totalQuestions;
  final int correct;
  final int wrong;
  final int skipped;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int durationMs;

  int get answered => correct + wrong;
  double get accuracy => answered == 0 ? 0 : (correct / answered) * 100;
  bool get isFinished => finishedAt != null;

  @override
  List<Object?> get props => <Object?>[
        id, bankId, mode, title, totalQuestions, correct, wrong, skipped,
        startedAt, finishedAt, durationMs,
      ];
}

/// A per-subject accuracy tally (for strongest/weakest subject analytics).
class SubjectAccuracy extends Equatable {
  const SubjectAccuracy({
    required this.subject,
    required this.correct,
    required this.total,
  });

  final String subject;
  final int correct;
  final int total;

  double get accuracy => total == 0 ? 0 : (correct / total) * 100;

  @override
  List<Object?> get props => <Object?>[subject, correct, total];
}

/// Aggregate Quiz Engine analytics. Ships all-zero (no sample data).
class QuizStats extends Equatable {
  const QuizStats({
    required this.totalQuizzes,
    required this.questionsSolved,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.totalTimeMs,
    required this.dailyQuizzes,
    required this.weeklyQuizzes,
    required this.monthlyQuizzes,
    this.strongestSubject,
    this.weakestSubject,
  });

  final int totalQuizzes;
  final int questionsSolved;
  final int correct;
  final int wrong;
  final int skipped;
  final int totalTimeMs;
  final int dailyQuizzes;
  final int weeklyQuizzes;
  final int monthlyQuizzes;
  final SubjectAccuracy? strongestSubject;
  final SubjectAccuracy? weakestSubject;

  double get accuracy =>
      (correct + wrong) == 0 ? 0 : (correct / (correct + wrong)) * 100;

  /// Average time per quiz, in seconds.
  int get avgSecondsPerQuiz =>
      totalQuizzes == 0 ? 0 : (totalTimeMs / totalQuizzes / 1000).round();

  static const QuizStats empty = QuizStats(
    totalQuizzes: 0, questionsSolved: 0, correct: 0, wrong: 0, skipped: 0,
    totalTimeMs: 0, dailyQuizzes: 0, weeklyQuizzes: 0, monthlyQuizzes: 0,
  );

  @override
  List<Object?> get props => <Object?>[
        totalQuizzes, questionsSolved, correct, wrong, skipped, totalTimeMs,
        dailyQuizzes, weeklyQuizzes, monthlyQuizzes, strongestSubject,
        weakestSubject,
      ];
}

/// A question paired with the answer given in an attempt (Review Answers).
class AnsweredQuestion extends Equatable {
  const AnsweredQuestion({
    required this.question,
    required this.isCorrect,
    required this.skipped,
    this.given,
  });

  final QuizQuestion question;
  final QuizGivenAnswer? given;
  final bool isCorrect;
  final bool skipped;

  @override
  List<Object?> get props => <Object?>[question, given, isCorrect, skipped];
}

/// A Wrong-Answer Notebook entry (question + how often it was missed).
class WrongAnswerEntry extends Equatable {
  const WrongAnswerEntry({
    required this.question,
    required this.wrongCount,
    required this.lastWrongAt,
    this.lastGiven,
  });

  final QuizQuestion question;
  final int wrongCount;
  final DateTime lastWrongAt;
  final QuizGivenAnswer? lastGiven;

  @override
  List<Object?> get props =>
      <Object?>[question, wrongCount, lastWrongAt, lastGiven];
}

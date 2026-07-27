import 'package:equatable/equatable.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';

/// Quiz Engine preferences. Persisted in a key-value table so new settings
/// never require a migration. All values have safe defaults, so the engine is
/// fully functional out of the box (with zero content).
class QuizSettings extends Equatable {
  const QuizSettings({
    this.defaultMode = QuizMode.practice,
    this.questionsPerQuiz = 0, // 0 = all available
    this.shuffleQuestions = true,
    this.shuffleOptions = false,
    this.showExplanations = true,
    this.timerEnabled = false,
    this.secondsPerQuestion = 60,
    this.negativeMarking = false,
  });

  final QuizMode defaultMode;
  final int questionsPerQuiz;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool showExplanations;
  final bool timerEnabled;
  final int secondsPerQuestion;
  final bool negativeMarking;

  static const QuizSettings defaults = QuizSettings();

  QuizSettings copyWith({
    QuizMode? defaultMode,
    int? questionsPerQuiz,
    bool? shuffleQuestions,
    bool? shuffleOptions,
    bool? showExplanations,
    bool? timerEnabled,
    int? secondsPerQuestion,
    bool? negativeMarking,
  }) {
    return QuizSettings(
      defaultMode: defaultMode ?? this.defaultMode,
      questionsPerQuiz: questionsPerQuiz ?? this.questionsPerQuiz,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      shuffleOptions: shuffleOptions ?? this.shuffleOptions,
      showExplanations: showExplanations ?? this.showExplanations,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      secondsPerQuestion: secondsPerQuestion ?? this.secondsPerQuestion,
      negativeMarking: negativeMarking ?? this.negativeMarking,
    );
  }

  Map<String, String> toMap() => <String, String>{
        'defaultMode': '${defaultMode.index}',
        'questionsPerQuiz': '$questionsPerQuiz',
        'shuffleQuestions': '$shuffleQuestions',
        'shuffleOptions': '$shuffleOptions',
        'showExplanations': '$showExplanations',
        'timerEnabled': '$timerEnabled',
        'secondsPerQuestion': '$secondsPerQuestion',
        'negativeMarking': '$negativeMarking',
      };

  factory QuizSettings.fromMap(Map<String, String> m) {
    int asInt(String k, int d) => int.tryParse(m[k] ?? '') ?? d;
    bool asBool(String k, bool d) =>
        m.containsKey(k) ? m[k] == 'true' : d;
    return QuizSettings(
      defaultMode: QuizMode.fromIndex(asInt('defaultMode', 0)),
      questionsPerQuiz: asInt('questionsPerQuiz', 0),
      shuffleQuestions: asBool('shuffleQuestions', true),
      shuffleOptions: asBool('shuffleOptions', false),
      showExplanations: asBool('showExplanations', true),
      timerEnabled: asBool('timerEnabled', false),
      secondsPerQuestion: asInt('secondsPerQuestion', 60),
      negativeMarking: asBool('negativeMarking', false),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        defaultMode, questionsPerQuiz, shuffleQuestions, shuffleOptions,
        showExplanations, timerEnabled, secondsPerQuestion, negativeMarking,
      ];
}

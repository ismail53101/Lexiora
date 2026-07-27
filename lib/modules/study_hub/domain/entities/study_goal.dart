import 'package:equatable/equatable.dart';

/// Category of a daily goal (used for icons and for the "Vocabulary Learned"
/// metric, which sums progress on goals of type [GoalType.vocabulary]).
enum GoalType {
  vocabulary,
  reading,
  grammar,
  mcq,
  custom;

  static GoalType fromKey(String? key) => switch (key) {
        'vocabulary' => GoalType.vocabulary,
        'reading' => GoalType.reading,
        'grammar' => GoalType.grammar,
        'mcq' => GoalType.mcq,
        _ => GoalType.custom,
      };

  String get key => name;

  String get label => switch (this) {
        GoalType.vocabulary => 'Vocabulary',
        GoalType.reading => 'Reading',
        GoalType.grammar => 'Grammar',
        GoalType.mcq => 'MCQs',
        GoalType.custom => 'Custom',
      };
}

/// A daily goal with progress, e.g. "Learn 20 vocabulary words".
class StudyGoal extends Equatable {
  const StudyGoal({
    required this.id,
    required this.day,
    required this.title,
    required this.targetCount,
    required this.createdAt,
    required this.updatedAt,
    this.type = GoalType.custom,
    this.currentCount = 0,
    this.unit,
  });

  final String id;
  final String day;
  final String title;
  final GoalType type;
  final int targetCount;
  final int currentCount;
  final String? unit;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Progress in the range 0..1.
  double get progress =>
      targetCount <= 0 ? 0 : (currentCount / targetCount).clamp(0.0, 1.0);

  bool get achieved => targetCount > 0 && currentCount >= targetCount;

  StudyGoal copyWith({
    String? title,
    GoalType? type,
    int? targetCount,
    int? currentCount,
    String? unit,
    DateTime? updatedAt,
    bool clearUnit = false,
  }) {
    return StudyGoal(
      id: id,
      day: day,
      title: title ?? this.title,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      unit: clearUnit ? null : (unit ?? this.unit),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        day,
        title,
        type,
        targetCount,
        currentCount,
        unit,
        createdAt,
        updatedAt,
      ];
}

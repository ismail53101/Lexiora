import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';

/// A Topic within a Subject (v0.9.1). Unlimited per subject; fully editable and
/// orderable from the Admin CMS.
class QuizTopic extends Equatable {
  const QuizTopic({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.icon,
    this.color,
    this.orderIndex = 0,
    this.archived = false,
  });

  final String id;
  final String subjectId;
  final String name;
  final String? description;
  final int? icon;
  final int? color;
  final int orderIndex;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color? get colorValue => color == null ? null : Color(color!);

  QuizTopic copyWith({
    String? subjectId,
    String? name,
    String? description,
    int? icon,
    int? color,
    int? orderIndex,
    bool? archived,
    DateTime? updatedAt,
    bool clearDescription = false,
    bool clearIcon = false,
    bool clearColor = false,
  }) {
    return QuizTopic(
      id: id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      icon: clearIcon ? null : (icon ?? this.icon),
      color: clearColor ? null : (color ?? this.color),
      orderIndex: orderIndex ?? this.orderIndex,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, subjectId, name, description, icon, color, orderIndex, archived,
        createdAt, updatedAt,
      ];
}

/// A topic plus its computed quiz and question counts.
class QuizTopicSummary extends Equatable {
  const QuizTopicSummary({
    required this.topic,
    required this.quizCount,
    required this.questionCount,
  });

  final QuizTopic topic;
  final int quizCount;
  final int questionCount;

  @override
  List<Object?> get props => <Object?>[topic, quizCount, questionCount];
}

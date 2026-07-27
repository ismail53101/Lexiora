import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';

/// A top-level Quiz Subject (v0.9.1). Everything is data-driven and editable
/// from the Admin CMS — nothing here is hardcoded in the app.
class QuizSubject extends Equatable {
  const QuizSubject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.icon,
    this.color,
    this.orderIndex = 0,
    this.archived = false,
    this.source = 'manual',
  });

  final String id;
  final String name;
  final String? description;
  final int? icon;
  final int? color;
  final int orderIndex;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Not persisted on the row; set by the seeder-created rows via `searchText`
  /// tagging is used instead — kept here only for in-memory demo marking.
  final String source;

  Color? get colorValue => color == null ? null : Color(color!);

  QuizSubject copyWith({
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
    return QuizSubject(
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      icon: clearIcon ? null : (icon ?? this.icon),
      color: clearColor ? null : (color ?? this.color),
      orderIndex: orderIndex ?? this.orderIndex,
      archived: archived ?? this.archived,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, name, description, icon, color, orderIndex, archived, createdAt,
        updatedAt,
      ];
}

/// A subject plus its computed topic and question counts, for list rendering.
class QuizSubjectSummary extends Equatable {
  const QuizSubjectSummary({
    required this.subject,
    required this.topicCount,
    required this.questionCount,
  });

  final QuizSubject subject;
  final int topicCount;
  final int questionCount;

  @override
  List<Object?> get props => <Object?>[subject, topicCount, questionCount];
}

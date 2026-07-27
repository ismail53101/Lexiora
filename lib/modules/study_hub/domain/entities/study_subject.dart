import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';

/// A user-defined subject with a custom colour. Nothing is hardcoded — subjects
/// come from what the user types; a colour is optional and assignable anytime.
class StudySubject extends Equatable {
  const StudySubject({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
  });

  final String id;
  final String name;

  /// ARGB colour value.
  final int color;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color get colorValue => Color(color);

  StudySubject copyWith({
    String? name,
    int? color,
    bool? archived,
    DateTime? updatedAt,
  }) =>
      StudySubject(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        archived: archived ?? this.archived,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props =>
      <Object?>[id, name, color, archived, createdAt, updatedAt];
}

import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';

/// A user-created deck. Colour is optional (else the subject colour is used).
class Deck extends Equatable {
  const Deck({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.subject,
    this.topic,
    this.color,
    this.icon,
    this.archived = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? subject;
  final String? topic;
  final int? color;
  final int? icon;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color? get colorValue => color == null ? null : Color(color!);

  Deck copyWith({
    String? name,
    String? description,
    String? subject,
    String? topic,
    int? color,
    int? icon,
    bool? archived,
    DateTime? updatedAt,
    bool clearDescription = false,
    bool clearSubject = false,
    bool clearTopic = false,
    bool clearColor = false,
  }) {
    return Deck(
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      subject: clearSubject ? null : (subject ?? this.subject),
      topic: clearTopic ? null : (topic ?? this.topic),
      color: clearColor ? null : (color ?? this.color),
      icon: icon ?? this.icon,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, name, description, subject, topic, color, icon, archived,
        createdAt, updatedAt,
      ];
}

/// A deck plus its card and due-today counts, for list rendering.
class DeckSummary extends Equatable {
  const DeckSummary({
    required this.deck,
    required this.cardCount,
    required this.dueCount,
  });

  final Deck deck;
  final int cardCount;
  final int dueCount;

  @override
  List<Object?> get props => <Object?>[deck, cardCount, dueCount];
}

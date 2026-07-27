import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';

/// A user/Admin/import-created Question Bank. Nothing is hardcoded — subject,
/// topic, tags, colour and version are all data-driven. The question count is
/// computed on demand (see [QuizBankSummary]), never stored.
class QuizBank extends Equatable {
  const QuizBank({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.subject,
    this.topic,
    this.description,
    this.color,
    this.tags,
    this.version,
    this.source = 'manual',
    this.externalId,
    this.subjectId,
    this.topicId,
    this.orderIndex = 0,
    this.archived = false,
  });

  final String id;
  final String name;
  final String? subject;
  final String? topic;
  final String? description;
  final int? color;
  final String? tags;
  final String? version;

  /// 'manual' | 'local_json' | 'admin' | 'cloud' | 'demo'.
  final String source;
  final String? externalId;

  /// Links into the Subject → Topic hierarchy (v0.9.1).
  final String? subjectId;
  final String? topicId;
  final int orderIndex;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color? get colorValue => color == null ? null : Color(color!);

  List<String> get tagList => (tags ?? '')
      .split(',')
      .map((String t) => t.trim())
      .where((String t) => t.isNotEmpty)
      .toList();

  QuizBank copyWith({
    String? name,
    String? subject,
    String? topic,
    String? description,
    int? color,
    String? tags,
    String? version,
    String? source,
    String? subjectId,
    String? topicId,
    int? orderIndex,
    bool? archived,
    DateTime? updatedAt,
    bool clearSubject = false,
    bool clearTopic = false,
    bool clearDescription = false,
    bool clearColor = false,
    bool clearSubjectId = false,
    bool clearTopicId = false,
  }) {
    return QuizBank(
      id: id,
      name: name ?? this.name,
      subject: clearSubject ? null : (subject ?? this.subject),
      topic: clearTopic ? null : (topic ?? this.topic),
      description: clearDescription ? null : (description ?? this.description),
      color: clearColor ? null : (color ?? this.color),
      tags: tags ?? this.tags,
      version: version ?? this.version,
      source: source ?? this.source,
      externalId: externalId,
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      orderIndex: orderIndex ?? this.orderIndex,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, name, subject, topic, description, color, tags, version, source,
        externalId, subjectId, topicId, orderIndex, archived, createdAt,
        updatedAt,
      ];
}

/// A bank plus its (computed) total question count, for list rendering.
class QuizBankSummary extends Equatable {
  const QuizBankSummary({required this.bank, required this.questionCount});

  final QuizBank bank;
  final int questionCount;

  @override
  List<Object?> get props => <Object?>[bank, questionCount];
}

import 'package:equatable/equatable.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';

/// A reusable study routine (e.g. "CSS Routine"). Applying it copies its
/// [items] into a day as fully editable sessions/breaks — it never locks data.
class StudyTemplate extends Equatable {
  const StudyTemplate({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => <Object?>[id, name, itemCount, createdAt, updatedAt];
}

/// A single session/break inside a [StudyTemplate].
class StudyTemplateItem extends Equatable {
  const StudyTemplateItem({
    required this.id,
    required this.templateId,
    required this.title,
    this.kind = SessionKind.session,
    this.subject,
    this.topic,
    this.startMinute,
    this.endMinute,
    this.priority = TaskPriority.medium,
    this.notes,
    this.orderIndex = 0,
  });

  final String id;
  final String templateId;
  final String title;
  final SessionKind kind;
  final String? subject;
  final String? topic;
  final int? startMinute;
  final int? endMinute;
  final TaskPriority priority;
  final String? notes;
  final int orderIndex;

  @override
  List<Object?> get props => <Object?>[
        id,
        templateId,
        title,
        kind,
        subject,
        topic,
        startMinute,
        endMinute,
        priority,
        notes,
        orderIndex,
      ];
}

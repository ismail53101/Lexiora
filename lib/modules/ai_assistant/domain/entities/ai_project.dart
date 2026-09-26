import 'package:equatable/equatable.dart';

/// One AI Assistant project: a named folder that groups conversations.
class AiProject extends Equatable {
  const AiProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiProject copyWith({String? name, DateTime? updatedAt}) => AiProject(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => <Object?>[id, name, createdAt, updatedAt];
}

/// A project plus a lightweight preview for the sidebar list.
class AiProjectSummary extends Equatable {
  const AiProjectSummary({
    required this.project,
    required this.conversationCount,
    this.lastActivity,
  });

  final AiProject project;

  /// Conversations currently inside the project.
  final int conversationCount;

  /// The most recent conversation activity inside the project (null if empty).
  final DateTime? lastActivity;

  @override
  List<Object?> get props => <Object?>[project, conversationCount, lastActivity];
}

import 'package:equatable/equatable.dart';

/// Chat roles, mirroring the OpenAI-compatible schema.
enum AiRole {
  system,
  user,
  assistant;

  static AiRole fromIndex(int? i) =>
      (i == null || i < 0 || i >= AiRole.values.length)
          ? AiRole.user
          : AiRole.values[i];

  /// Wire value used in the request payload.
  String get wire => name;
}

/// Lifecycle of a message in the UI/persistence layer.
enum AiMessageStatus {
  /// Being sent / awaiting the first token.
  sending,

  /// Assistant reply is streaming in.
  streaming,

  /// Complete and persisted.
  done,

  /// Failed (carries an error message).
  error;

  /// Value persisted to the DB (only done/error are ever stored).
  int get stored => this == AiMessageStatus.error ? 1 : 0;

  static AiMessageStatus fromStored(int? i) =>
      i == 1 ? AiMessageStatus.error : AiMessageStatus.done;
}

/// A single chat message.
class AiMessage extends Equatable {
  const AiMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = AiMessageStatus.done,
    this.error,
    this.orderIndex = 0,
  });

  final String id;
  final String conversationId;
  final AiRole role;
  final String content;
  final AiMessageStatus status;
  final String? error;
  final int orderIndex;
  final DateTime createdAt;

  bool get isUser => role == AiRole.user;
  bool get isAssistant => role == AiRole.assistant;

  AiMessage copyWith({
    String? content,
    AiMessageStatus? status,
    String? error,
    int? orderIndex,
  }) =>
      AiMessage(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content ?? this.content,
        status: status ?? this.status,
        error: error ?? this.error,
        orderIndex: orderIndex ?? this.orderIndex,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      <Object?>[id, conversationId, role, content, status, error, orderIndex, createdAt];
}

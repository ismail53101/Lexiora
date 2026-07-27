import 'package:equatable/equatable.dart';

/// A chat session.
class AiConversation extends Equatable {
  const AiConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.model,
    this.pinned = false,
  });

  final String id;
  final String title;
  final String? model;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiConversation copyWith({
    String? title,
    String? model,
    bool? pinned,
    DateTime? updatedAt,
  }) =>
      AiConversation(
        id: id,
        title: title ?? this.title,
        model: model ?? this.model,
        pinned: pinned ?? this.pinned,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props =>
      <Object?>[id, title, model, pinned, createdAt, updatedAt];
}

/// A conversation plus a lightweight preview for the conversation list.
class AiConversationSummary extends Equatable {
  const AiConversationSummary({
    required this.conversation,
    required this.messageCount,
    this.lastMessage,
  });

  final AiConversation conversation;
  final int messageCount;
  final String? lastMessage;

  @override
  List<Object?> get props => <Object?>[conversation, messageCount, lastMessage];
}

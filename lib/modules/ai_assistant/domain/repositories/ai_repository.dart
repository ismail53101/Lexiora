import 'package:lexiora/modules/ai_assistant/domain/entities/ai_chat.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_message.dart';

/// The AI Assistant's domain contract: offline-first conversation/message
/// persistence plus streaming chat orchestration. Provider-agnostic — it never
/// exposes where replies come from.
abstract interface class AiRepository {
  /// Whether a provider API key is configured.
  bool get isConfigured;

  /// Provider description (name + capabilities), for the UI.
  AiProviderInfo get providerInfo;

  // ── Conversations ─────────────────────────────────────────────────────────
  /// All conversations (most-recent first), optionally filtered by [query]
  /// (matches title and message text).
  Stream<List<AiConversationSummary>> watchConversations({String query});
  Future<AiConversation> createConversation({String? title});
  Future<AiConversation?> conversation(String id);
  Future<void> renameConversation(String id, String title);
  Future<void> deleteConversation(String id);
  Future<void> deleteAllConversations();

  // ── Messages (paginated for long chats) ─────────────────────────────────────
  /// The latest [limit] messages of a conversation (ascending for display).
  /// Increase [limit] to lazily load older messages.
  Stream<List<AiMessage>> watchMessages(String conversationId, {int limit});
  Future<void> deleteMessage(String id);

  // ── Chat lifecycle ──────────────────────────────────────────────────────────
  /// Persists the user message, then streams the assistant reply, persisting the
  /// final (or partial, if stopped) result. Emits [AiStreamEvent]s for the UI.
  Stream<AiStreamEvent> sendMessage({
    required String conversationId,
    required String userText,
    AiCancelToken? cancel,
  });

  /// Removes the last assistant reply (if any) and streams a fresh one from the
  /// existing history.
  Stream<AiStreamEvent> regenerate({
    required String conversationId,
    AiCancelToken? cancel,
  });
}

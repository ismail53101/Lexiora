import 'package:lexiora/modules/ai_assistant/domain/entities/ai_chat.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_message.dart';

/// The provider-agnostic chat transport.
///
/// The UI and repository depend only on this interface, so a different backend
/// (another OpenAI-compatible endpoint, a Dio-based client, an on-device model,
/// or future vision/voice providers) can be swapped in by implementing it —
/// nothing in the presentation layer changes.
abstract interface class AiChatService {
  /// Describes this provider and what it supports.
  AiProviderInfo get info;

  /// Streams an assistant reply for the given [messages] (full history).
  ///
  /// Emits [AiDelta]s as text arrives, a final [AiDone], or an [AiError].
  /// If the transport cannot stream, it should still emit a single [AiDelta]
  /// followed by [AiDone]. Cancellation is cooperative via [cancel].
  Stream<AiStreamEvent> streamChat(
    List<AiMessage> messages, {
    String? model,
    AiCancelToken? cancel,
  });
}

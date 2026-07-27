import 'package:lexiora/modules/ai_assistant/domain/entities/ai_failure.dart';

/// Capabilities a provider can advertise. The UI can adapt to these, and future
/// providers (vision, image generation, voice, reasoning) add to this set
/// without any change to the chat surface.
enum AiCapability {
  chat,
  streaming,
  vision,
  imageGeneration,
  speechToText,
  textToSpeech,
  reasoning,
}

/// Static description of a chat provider (name + what it supports).
class AiProviderInfo {
  const AiProviderInfo({
    required this.id,
    required this.name,
    required this.capabilities,
  });

  final String id;
  final String name;
  final Set<AiCapability> capabilities;

  bool supports(AiCapability c) => capabilities.contains(c);
}

/// One event from a streaming chat reply.
sealed class AiStreamEvent {
  const AiStreamEvent();
}

/// An incremental text delta.
class AiDelta extends AiStreamEvent {
  const AiDelta(this.text);
  final String text;
}

/// The stream finished successfully; [fullText] is the complete reply.
class AiDone extends AiStreamEvent {
  const AiDone(this.fullText);
  final String fullText;
}

/// The stream failed. [partialText] holds anything received before the failure.
class AiError extends AiStreamEvent {
  const AiError(this.failure, {this.partialText = ''});
  final AiFailure failure;
  final String partialText;
}

/// A cooperative cancellation handle passed into a streaming call so the UI can
/// "stop generating". Implementations abort the underlying request when
/// [cancel] is invoked.
class AiCancelToken {
  bool _cancelled = false;
  void Function()? _onCancel;

  bool get isCancelled => _cancelled;

  /// Registered by the transport so [cancel] can abort the in-flight request.
  void attach(void Function() onCancel) {
    _onCancel = onCancel;
    if (_cancelled) onCancel();
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _onCancel?.call();
  }
}

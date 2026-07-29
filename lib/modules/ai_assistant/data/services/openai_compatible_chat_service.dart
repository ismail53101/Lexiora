import 'dart:convert';

import 'package:lexiora/modules/ai_assistant/config/ai_config.dart';
import 'package:lexiora/modules/ai_assistant/data/services/ai_api_client.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_chat.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_failure.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_message.dart';
import 'package:lexiora/modules/ai_assistant/domain/services/ai_chat_service.dart';

/// An OpenAI-compatible [AiChatService] (chat/completions with SSE streaming).
///
/// Streaming is attempted first; if the endpoint returns nothing streamable it
/// transparently falls back to a single non-streaming completion. Parsing is
/// isolated in pure static helpers so it is unit-testable without a network.
class OpenAiCompatibleChatService implements AiChatService {
  OpenAiCompatibleChatService(this._client, this._config);

  final AiApiClient _client;
  final AiConfig _config;

  @override
  AiProviderInfo get info => const AiProviderInfo(
        id: 'openai_compatible',
        name: 'OpenAI-compatible',
        capabilities: <AiCapability>{
          AiCapability.chat,
          AiCapability.streaming,
        },
      );

  @override
  Stream<AiStreamEvent> streamChat(
    List<AiMessage> messages, {
    String? model,
    AiCancelToken? cancel,
  }) async* {
    final List<Map<String, String>> wire = messages
        .where((AiMessage m) => m.content.trim().isNotEmpty)
        .map((AiMessage m) =>
            <String, String>{'role': m.role.wire, 'content': m.content})
        .toList();
    final String useModel = model ?? _config.model;
    final StringBuffer acc = StringBuffer();

    try {
      await for (final String payload in _client.streamSse(
        <String, dynamic>{
          'model': useModel,
          'messages': wire,
          'stream': true,
          'provider': _config.provider.wireValue,
        },
        cancel: cancel,
      )) {
        final String? delta = parseStreamDelta(payload);
        if (delta != null && delta.isNotEmpty) {
          acc.write(delta);
          yield AiDelta(delta);
        }
      }

      // Fallback: endpoint didn't stream any content — do one plain completion.
      if (acc.isEmpty && !(cancel?.isCancelled ?? false)) {
        final Map<String, dynamic> json = await _client.postJson(
          <String, dynamic>{
            'model': useModel,
            'messages': wire,
            'provider': _config.provider.wireValue,
          },
          cancel: cancel,
        );
        final String content = parseFullContent(json);
        if (content.isNotEmpty) {
          acc.write(content);
          yield AiDelta(content);
        }
      }

      yield AiDone(acc.toString());
    } on AiFailure catch (f) {
      if (cancel?.isCancelled ?? false) {
        yield AiDone(acc.toString());
      } else {
        yield AiError(f, partialText: acc.toString());
      }
    } catch (_) {
      if (cancel?.isCancelled ?? false) {
        yield AiDone(acc.toString());
      } else {
        yield AiError(
          const AiFailure(AiFailureKind.unknown,
              'Something went wrong contacting the AI. Please try again.'),
          partialText: acc.toString(),
        );
      }
    }
  }

  // ── Pure parsers (unit-testable) ────────────────────────────────────────────

  /// Extracts the incremental `choices[0].delta.content` from one SSE payload.
  /// Returns null when the payload carries no text delta (e.g. role-only chunk
  /// or unparseable JSON).
  static String? parseStreamDelta(String payload) {
    Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final Object? choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final Object? first = choices.first;
    if (first is! Map) return null;
    final Object? delta = first['delta'];
    if (delta is Map) {
      final Object? content = delta['content'];
      if (content is String) return content;
    }
    // Some providers use `message` even in streaming — tolerate it.
    final Object? message = first['message'];
    if (message is Map && message['content'] is String) {
      return message['content'] as String;
    }
    return null;
  }

  /// Extracts `choices[0].message.content` from a full completion body.
  static String parseFullContent(Map<String, dynamic> json) {
    final Object? choices = json['choices'];
    if (choices is! List || choices.isEmpty) return '';
    final Object? first = choices.first;
    if (first is! Map) return '';
    final Object? message = first['message'];
    if (message is Map && message['content'] is String) {
      return (message['content'] as String).trim();
    }
    // Fallback for text-completion shapes.
    if (first['text'] is String) return (first['text'] as String).trim();
    return '';
  }
}

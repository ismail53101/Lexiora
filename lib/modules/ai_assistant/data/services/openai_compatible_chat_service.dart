import 'dart:convert';
import 'dart:io';

import 'package:lexiora/modules/ai_assistant/config/ai_config.dart';
import 'package:lexiora/modules/ai_assistant/data/services/ai_api_client.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_attachment.dart';
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

  static const int _maxTransientRetries = 2;

  /// Whether a failure is worth an automatic retry: server-side problems
  /// (5xx, including Cloudflare's 52x family), timeouts and network drops.
  /// Auth, rate-limit and not-found errors are never retried.
  static bool isTransientFailure(AiFailure f) =>
      f.kind == AiFailureKind.server ||
      f.kind == AiFailureKind.timeout ||
      f.kind == AiFailureKind.network;

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
    final List<Map<String, dynamic>> wire = await _buildWireMessages(messages);
    final String useModel = model ?? _config.model;
    final StringBuffer acc = StringBuffer();
    String? sourcesHeader;

    try {
      // Transient gateway/upstream failures (Cloudflare 502/503/504/520-524,
      // timeouts, dropped connections) are retried a couple of times as long
      // as nothing has been shown to the user yet. A free upstream model that
      // is momentarily unreachable then no longer surfaces as "error 522".
      for (int attempt = 0;; attempt++) {
        try {
          await for (final String payload in _client.streamSse(
            <String, dynamic>{
              'model': useModel,
              'messages': wire,
              'stream': true,
              'provider': _config.provider.wireValue,
            },
            cancel: cancel,
            onSources: (String raw) => sourcesHeader = raw,
          )) {
            final String? delta = parseStreamDelta(payload);
            if (delta != null && delta.isNotEmpty) {
              acc.write(delta);
              yield AiDelta(delta);
            }
          }
          break;
        } on AiFailure catch (f) {
          final bool canRetry = acc.isEmpty &&
              attempt < _maxTransientRetries &&
              isTransientFailure(f) &&
              !(cancel?.isCancelled ?? false);
          if (!canRetry) rethrow;
          await Future<void>.delayed(
            Duration(milliseconds: 1500 * (attempt + 1)),
          );
          if (cancel?.isCancelled ?? false) {
            yield AiDone(acc.toString());
            return;
          }
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

      // Web search was used: append a "Sources" list to the reply. It is saved
      // with the message (no DB change) and rendered as tappable Markdown links.
      if (acc.isNotEmpty && sourcesHeader != null) {
        final String block =
            sourcesMarkdown(parseSourcesHeader(sourcesHeader!));
        if (block.isNotEmpty) {
          acc.write(block);
          yield AiDelta(block);
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

  // ── Wire message construction ───────────────────────────────────────────────

  /// Converts stored [AiMessage]s into the OpenAI-compatible `messages` array,
  /// expanding any image attachment (see [AiAttachment]) into the standard
  /// vision content-parts shape:
  /// `[{"type":"text",...},{"type":"image_url","image_url":{"url":"data:..."}}]`.
  /// A model/provider that doesn't support vision simply won't understand the
  /// extra part — this never breaks plain-text messages, which stay exactly
  /// the simple `content: "..."` shape they always were.
  Future<List<Map<String, dynamic>>> _buildWireMessages(
    List<AiMessage> messages,
  ) async {
    final List<Map<String, dynamic>> wire = <Map<String, dynamic>>[];
    for (final AiMessage m in messages) {
      final AiAttachment att = AiAttachment.parse(
        m.role == AiRole.assistant ? stripSources(m.content) : m.content,
      );
      final String text = _textWithPdfContext(att);

      if (!att.hasImage) {
        if (text.isEmpty) continue;
        wire.add(<String, dynamic>{'role': m.role.wire, 'content': text});
        continue;
      }

      final String? dataUrl = await _readImageAsDataUrl(att.imagePath!);
      if (dataUrl == null) {
        // Image file missing/unreadable (e.g. deleted from storage) — degrade
        // to text-only rather than dropping or failing the whole request.
        if (text.isEmpty) continue;
        wire.add(<String, dynamic>{'role': m.role.wire, 'content': text});
        continue;
      }

      wire.add(<String, dynamic>{
        'role': m.role.wire,
        'content': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'text',
            'text': text.isEmpty ? 'Describe this image.' : text,
          },
          <String, dynamic>{
            'type': 'image_url',
            'image_url': <String, String>{'url': dataUrl},
          },
        ],
      });
    }
    // Brand identity belongs in the system role, not in a user-visible
    // message, so every new request consistently identifies the assistant.
    wire.insert(0, <String, dynamic>{
      'role': 'system',
      'content': '''You are DarsNexa AI, the built-in study assistant for the DarsNexa educational app. Your name is DarsNexa AI. If asked who you are or which app you belong to, say you are DarsNexa AI, DarsNexa's built-in study assistant. Never identify yourself as Sapiora or claim to belong to Sapiora. Help users learn with accurate, clear, well-structured answers. Use Markdown when it improves readability.''',
    });
    return wire;
  }

  String _textWithPdfContext(AiAttachment attachment) {
    final String question = attachment.text.trim();
    final String pdfContext = attachment.pdfText?.trim() ?? '';
    if (pdfContext.isEmpty) return question;
    if (question.isEmpty) {
      return 'Please answer using the attached PDF.\n\nAttached PDF text:\n$pdfContext';
    }
    return '$question\n\nAttached PDF text:\n$pdfContext';
  }

  Future<String?> _readImageAsDataUrl(String path) async {
    try {
      final File file = File(path);
      if (!await file.exists()) return null;
      final List<int> bytes = await file.readAsBytes();
      final String mime = path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      return 'data:$mime;base64,${base64Encode(bytes)}';
    } on Object {
      return null;
    }
  }

  // ── Web-search sources (Worker → app) ───────────────────────────────────────

  static const String _sourcesMarker = '\n\n---\n**Sources**\n';

  /// Decodes the Worker's `X-Sapiora-Sources` header (URL-encoded JSON list of
  /// `{title, url}`). Never throws; returns only http(s) links.
  static List<({String title, String url})> parseSourcesHeader(String raw) {
    try {
      final Object? decoded = jsonDecode(Uri.decodeComponent(raw));
      if (decoded is! List) return const <({String title, String url})>[];
      final List<({String title, String url})> out =
          <({String title, String url})>[];
      for (final Object? item in decoded) {
        if (item is! Map) continue;
        final String url = '${item['url'] ?? ''}'.trim();
        final Uri? uri = Uri.tryParse(url);
        if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
          continue;
        }
        final String title = '${item['title'] ?? ''}'.trim();
        out.add((title: title.isEmpty ? uri.host : title, url: url));
      }
      return out;
    } on Object {
      return const <({String title, String url})>[];
    }
  }

  /// Numbered to match the `[1]`, `[2]` citations the model writes.
  static String sourcesMarkdown(List<({String title, String url})> sources) {
    if (sources.isEmpty) return '';
    final StringBuffer b = StringBuffer(_sourcesMarker);
    for (int i = 0; i < sources.length; i++) {
      final String title = sources[i].title
          .replaceAll(RegExp(r'[\[\]\n\r]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      b.writeln('${i + 1}. [$title](${sources[i].url})');
    }
    return b.toString().trimRight();
  }

  /// Removes the Sources block so it isn't re-sent to the model as history.
  static String stripSources(String content) {
    final int i = content.indexOf(_sourcesMarker);
    return i < 0 ? content : content.substring(0, i);
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
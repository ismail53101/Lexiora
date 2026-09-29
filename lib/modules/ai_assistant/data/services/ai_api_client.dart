import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/modules/ai_assistant/config/ai_config.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_chat.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_failure.dart';

/// Low-level HTTP transport for the OpenAI-compatible provider.
///
/// Uses the cross-platform [http.Client] for Server-Sent Events streaming and
/// mid-stream cancellation. The API key is attached to the Authorization header
/// but is NEVER printed, logged, or included in any error/toString output.
class AiApiClient {
  AiApiClient(this._config);

  final AiConfig _config;

  /// Streams raw SSE `data:` payloads (the text after `data: `, excluding the
  /// terminal `[DONE]`). Throws [AiFailure] for HTTP/network/timeout errors.
  Stream<String> streamSse(
    Map<String, dynamic> body, {
    AiCancelToken? cancel,
  }) async* {
    if (!_config.isConfigured) throw AiFailure.notConfigured;

    final http.Client client = http.Client();
    cancel?.attach(() {
      try {
        client.close();
      } catch (_) {/* already closing */}
    });

    http.StreamedResponse response;
    try {
      final http.Request req = http.Request('POST', _config.chatCompletionsUri)
        ..headers.addAll(<String, String>{
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          'Authorization': 'Bearer ${_config.apiKey}',
          'X-AI-Provider': _config.provider.wireValue,
        })
        ..body = jsonEncode(body);
      response = await client.send(req).timeout(AiConstants.idleTimeout);
    } on http.ClientException {
      client.close();
      throw AiFailure.network;
    } on TimeoutException {
      client.close();
      throw AiFailure.timeout;
    }

    if (response.statusCode != 200) {
      final int code = response.statusCode;
      await response.stream.drain<void>().catchError((_) {});
      client.close();
      throw AiFailure.fromStatus(code);
    }

    try {
      final Stream<String> lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final String line in lines) {
        if (cancel?.isCancelled ?? false) return;
        final String trimmed = line.trim();
        if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
        final String payload = trimmed.substring(5).trim();
        if (payload == '[DONE]') return;
        yield payload;
      }
    } on Object {
      if (cancel?.isCancelled ?? false) return;
      throw AiFailure.network;
    } finally {
      client.close();
    }
  }

  /// Non-streaming request; returns the decoded JSON body. Throws [AiFailure].
  Future<Map<String, dynamic>> postJson(
    Map<String, dynamic> body, {
    AiCancelToken? cancel,
  }) async {
    if (!_config.isConfigured) throw AiFailure.notConfigured;

    final http.Client client = http.Client();
    cancel?.attach(() {
      try {
        client.close();
      } catch (_) {}
    });

    try {
      final http.Response response = await client.post(
        _config.chatCompletionsUri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiKey}',
          'X-AI-Provider': _config.provider.wireValue,
        },
        body: jsonEncode(body),
      ).timeout(AiConstants.idleTimeout);
      final String raw = response.body;
      if (response.statusCode != 200) {
        throw AiFailure.fromStatus(response.statusCode);
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) throw AiFailure.malformed;
      return decoded;
    } on FormatException {
      throw AiFailure.malformed;
    } on http.ClientException {
      throw AiFailure.network;
    } on TimeoutException {
      throw AiFailure.timeout;
    } finally {
      client.close();
    }
  }
}

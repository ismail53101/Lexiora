import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/modules/ai_assistant/config/ai_config.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_chat.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_failure.dart';

/// Low-level HTTP transport for the OpenAI-compatible provider.
///
/// Uses `dart:io` [HttpClient] (matching the codebase's zero-extra-dependency
/// HTTP approach) which natively supports Server-Sent Events streaming and
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

    final HttpClient client = HttpClient()
      ..connectionTimeout = AiConstants.connectTimeout;
    cancel?.attach(() {
      try {
        client.close(force: true);
      } catch (_) {/* already closing */}
    });

    HttpClientResponse response;
    try {
      final HttpClientRequest req = await client
          .postUrl(_config.chatCompletionsUri)
          .timeout(AiConstants.connectTimeout);
      req.headers
        ..set(HttpHeaders.contentTypeHeader, 'application/json')
        ..set(HttpHeaders.acceptHeader, 'text/event-stream')
        ..set(HttpHeaders.authorizationHeader, 'Bearer ${_config.apiKey}');
      req.add(utf8.encode(jsonEncode(body)));
      response = await req.close().timeout(AiConstants.idleTimeout);
    } on SocketException {
      client.close(force: true);
      throw AiFailure.network;
    } on TimeoutException {
      client.close(force: true);
      throw AiFailure.timeout;
    } on HttpException {
      client.close(force: true);
      throw AiFailure.network;
    }

    if (response.statusCode != HttpStatus.ok) {
      final int code = response.statusCode;
      await response.drain<void>().catchError((_) {});
      client.close(force: true);
      throw AiFailure.fromStatus(code);
    }

    try {
      final Stream<String> lines =
          response.transform(utf8.decoder).transform(const LineSplitter());
      await for (final String line in lines) {
        if (cancel?.isCancelled ?? false) return;
        final String trimmed = line.trim();
        if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
        final String payload = trimmed.substring(5).trim();
        if (payload == '[DONE]') return;
        yield payload;
      }
    } on Object {
      if (cancel?.isCancelled ?? false) return; // forced-close during abort
      throw AiFailure.network;
    } finally {
      client.close(force: true);
    }
  }

  /// Non-streaming request; returns the decoded JSON body. Throws [AiFailure].
  Future<Map<String, dynamic>> postJson(
    Map<String, dynamic> body, {
    AiCancelToken? cancel,
  }) async {
    if (!_config.isConfigured) throw AiFailure.notConfigured;

    final HttpClient client = HttpClient()
      ..connectionTimeout = AiConstants.connectTimeout;
    cancel?.attach(() {
      try {
        client.close(force: true);
      } catch (_) {}
    });

    try {
      final HttpClientRequest req = await client
          .postUrl(_config.chatCompletionsUri)
          .timeout(AiConstants.connectTimeout);
      req.headers
        ..set(HttpHeaders.contentTypeHeader, 'application/json')
        ..set(HttpHeaders.authorizationHeader, 'Bearer ${_config.apiKey}');
      req.add(utf8.encode(jsonEncode(body)));
      final HttpClientResponse response =
          await req.close().timeout(AiConstants.idleTimeout);

      final String raw = await response
          .transform(utf8.decoder)
          .join()
          .timeout(AiConstants.idleTimeout);
      if (response.statusCode != HttpStatus.ok) {
        throw AiFailure.fromStatus(response.statusCode);
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) throw AiFailure.malformed;
      return decoded;
    } on FormatException {
      throw AiFailure.malformed;
    } on SocketException {
      throw AiFailure.network;
    } on TimeoutException {
      throw AiFailure.timeout;
    } on HttpException {
      throw AiFailure.network;
    } finally {
      client.close(force: true);
    }
  }
}

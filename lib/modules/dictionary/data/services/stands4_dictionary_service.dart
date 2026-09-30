import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lexiora/modules/ai_assistant/config/ai_config.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';

/// Non-AI fallback for words missing from the bundled Dictionary.
///
/// Credentials stay in Cloudflare Worker secrets. The app sends only the
/// Worker's shared authorization key and never calls STANDS4 directly.
class Stands4DictionaryService {
  const Stands4DictionaryService(this._config);

  final AiConfig _config;

  Future<AiWordProfile?> define(String word) async {
    final String query = word.trim();
    if (query.isEmpty || !_config.isConfigured) return null;

    final String base = _config.baseUrl.endsWith('/')
        ? _config.baseUrl.substring(0, _config.baseUrl.length - 1)
        : _config.baseUrl;
    final Uri uri = Uri.parse('$base/api/dictionary/lookup').replace(
      queryParameters: <String, String>{'word': query},
    );
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);
    try {
      final HttpClientRequest request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 8));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set(HttpHeaders.authorizationHeader, 'Bearer ${_config.apiKey}');
      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 10));
      final String raw = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != HttpStatus.ok) return null;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final String returnedWord = decoded['word']?.toString().trim() ?? '';
      if (returnedWord.toLowerCase() != query.toLowerCase()) return null;
      final AiWordProfile profile = AiWordProfile.fromJson(<String, dynamic>{
        ...decoded,
        'source': 'stands4',
      });
      return profile.hasContent ? profile : null;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

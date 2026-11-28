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

      if (response.statusCode != HttpStatus.ok || raw.trim().isEmpty) {
        return null;
      }

      final Object? decoded = jsonDecode(raw);
      final Map<String, dynamic>? normalized =
          _normalizeResponse(decoded, query);
      if (normalized == null) return null;

      final AiWordProfile profile = AiWordProfile.fromJson(normalized);
      return profile.hasContent ? profile : null;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Accept both the Worker-normalized response and the native STANDS4 JSON
  /// shape. STANDS4 returns:
  ///   {"results":{"result":{"term":"...","synonyms":"a, b","antonyms":"c"}}}
  ///
  /// The native API uses comma-delimited strings, while AiWordProfile expects
  /// lists. Supporting both shapes prevents a valid STANDS4 synonym response
  /// from being discarded before it reaches the dictionary UI.
  Map<String, dynamic>? _normalizeResponse(Object? decoded, String query) {
    if (decoded is! Map) return null;

    final Map<String, dynamic> root = <String, dynamic>{
      for (final MapEntry<Object?, Object?> entry in decoded.entries)
        entry.key.toString(): entry.value,
    };

    // Already normalized by the Worker.
    final String returnedWord = root['word']?.toString().trim() ?? '';
    if (returnedWord.isNotEmpty) {
      if (returnedWord.toLowerCase() != query.toLowerCase()) return null;
      return <String, dynamic>{
        ...root,
        'source': 'stands4',
        'synonyms': _asStringList(root['synonyms']),
        'antonyms': _asStringList(root['antonyms']),
      };
    }

    // Native STANDS4 response: results.result can be either one object or a
    // list of result objects depending on the response/query.
    Object? results = root['results'];
    if (results is Map) {
      results = results['result'];
    }

    final List<Map<String, dynamic>> candidates = <Map<String, dynamic>>[];
    if (results is Map) {
      candidates.add(_stringKeyedMap(results));
    } else if (results is List) {
      for (final Object? item in results) {
        if (item is Map) candidates.add(_stringKeyedMap(item));
      }
    }

    if (candidates.isEmpty) return null;

    Map<String, dynamic>? selected;
    for (final Map<String, dynamic> item in candidates) {
      final String term = item['term']?.toString().trim() ?? '';
      if (term.toLowerCase() == query.toLowerCase()) {
        selected = item;
        break;
      }
    }
    selected ??= candidates.first;

    final String term = selected['term']?.toString().trim() ?? '';
    if (term.isEmpty || !term.toLowerCase().contains(query.toLowerCase())) {
      return null;
    }

    return <String, dynamic>{
      'word': query,
      'source': 'stands4',
      'englishDefinition': _nullableText(selected['definition']),
      'partOfSpeech': _nullableText(selected['partofspeech']),
      'synonyms': _asStringList(selected['synonyms']),
      'antonyms': _asStringList(selected['antonyms']),
      'exampleSentence': _nullableText(selected['example']),
    };
  }

  Map<String, dynamic> _stringKeyedMap(Map value) => <String, dynamic>{
        for (final MapEntry<Object?, Object?> entry in value.entries)
          entry.key.toString(): entry.value,
      };

  List<String> _asStringList(Object? value) {
    if (value is List) {
      return value
          .map((Object? item) => item?.toString().trim() ?? '')
          .where((String item) => item.isNotEmpty)
          .take(8)
          .toList(growable: false);
    }

    final String text = value?.toString().trim() ?? '';
    if (text.isEmpty) return const <String>[];

    return text
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .take(8)
        .toList(growable: false);
  }

  String? _nullableText(Object? value) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

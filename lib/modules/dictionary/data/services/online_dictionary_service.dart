import 'dart:convert';
import 'dart:io';

/// A single online English definition — just enough to display in the
/// translate popup's "ENGLISH MEANING" section.
class OnlineDefinition {
  const OnlineDefinition({required this.meaning, this.partOfSpeech});

  final String meaning;
  final String? partOfSpeech;
}

/// Fetches an English definition from the free, keyless Free Dictionary API
/// (https://dictionaryapi.dev) — mirrors [HttpTranslationService]'s pattern
/// (plain `dart:io` HTTP, no extra package, a pure/testable response parser)
/// so the app's two "online, free, no API key" fallbacks — Urdu translation
/// and English definitions — work the same way and fail the same way: any
/// error (offline, timeout, word not found) simply yields `null`, and the
/// caller falls back to not showing that section rather than an error.
class OnlineDictionaryService {
  OnlineDictionaryService({Duration? timeout, HttpClient? client})
      : _timeout = timeout ?? const Duration(seconds: 8),
        _client = client ?? HttpClient();

  static const String _baseUrl =
      'https://api.dictionaryapi.dev/api/v2/entries/en';

  final Duration _timeout;
  final HttpClient _client;

  Future<OnlineDefinition?> define(String word) async {
    final String q = word.trim();
    if (q.isEmpty) return null;

    try {
      final Uri uri = Uri.parse('$_baseUrl/${Uri.encodeComponent(q)}');
      final HttpClientRequest request =
          await _client.getUrl(uri).timeout(_timeout);
      final HttpClientResponse response =
          await request.close().timeout(_timeout);
      if (response.statusCode != HttpStatus.ok) {
        // 404 means "not an English word we know" — not an error to log.
        return null;
      }
      final String body =
          await response.transform(utf8.decoder).join().timeout(_timeout);
      return parseDefinition(body);
    } on Object {
      // Offline, timed out, malformed response, ... — no English meaning
      // available right now is a normal, silent outcome, not a crash.
      return null;
    }
  }

  /// Parses a Free Dictionary API response, returning the first definition
  /// (with its part of speech) or `null` when the payload has none. Pure and
  /// static so it's unit-testable without any network access.
  static OnlineDefinition? parseDefinition(String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (decoded is! List || decoded.isEmpty) return null;
    final Object? first = decoded.first;
    if (first is! Map<String, dynamic>) return null;

    final Object? meanings = first['meanings'];
    if (meanings is! List || meanings.isEmpty) return null;
    final Object? firstMeaning = meanings.first;
    if (firstMeaning is! Map<String, dynamic>) return null;

    final Object? pos = firstMeaning['partOfSpeech'];
    final Object? definitions = firstMeaning['definitions'];
    if (definitions is! List || definitions.isEmpty) return null;
    final Object? firstDefinition = definitions.first;
    if (firstDefinition is! Map<String, dynamic>) return null;

    final Object? text = firstDefinition['definition'];
    if (text is! String || text.trim().isEmpty) return null;

    return OnlineDefinition(
      meaning: text.trim(),
      partOfSpeech: pos is String && pos.isNotEmpty ? pos : null,
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/modules/translation/domain/services/remote_translation_service.dart';

/// Default [RemoteTranslationService] backed by a configurable HTTP endpoint
/// (Google Translate's keyless web endpoint by default — free, no API key),
/// using `dart:io` so no extra package dependency is required.
///
/// The response parsing is isolated in the pure, static [parseTranslation] so it
/// can be unit-tested without any network access. Both the Google Translate and
/// the legacy MyMemory response shapes are understood, so the endpoint can be
/// swapped (e.g. back to MyMemory) without touching the parser.
class HttpTranslationService implements RemoteTranslationService {
  HttpTranslationService({
    String? endpoint,
    Duration? timeout,
    HttpClient? client,
  })  : _endpoint = endpoint ?? TranslationConstants.remoteEndpoint,
        _timeout = timeout ?? TranslationConstants.remoteTimeout,
        _client = client ?? HttpClient();

  final String _endpoint;
  final Duration _timeout;
  final HttpClient _client;

  @override
  String get providerName => TranslationConstants.remoteProviderName;

  @override
  Future<String?> translate({
    required String word,
    required String targetLanguageCode,
  }) async {
    final String q = word.trim();
    if (q.isEmpty || targetLanguageCode.isEmpty) return null;

    // Google-style query parameters. If the configured endpoint is a
    // different provider, only this block needs adjusting.
    final Uri uri = Uri.parse(_endpoint).replace(
      queryParameters: <String, String>{
        'client': 'gtx',
        'sl': 'en',
        'tl': targetLanguageCode,
        'dt': 't',
        'q': q,
      },
    );

    final HttpClientRequest request = await _client.getUrl(uri).timeout(_timeout);
    final HttpClientResponse response = await request.close().timeout(_timeout);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Translation provider returned HTTP ${response.statusCode}',
        uri: uri,
      );
    }
    final String body =
        await response.transform(utf8.decoder).join().timeout(_timeout);
    return parseTranslation(body);
  }

  /// Parses a translation response, returning the translated text or `null`
  /// when the payload carries no usable translation. Pure and static so it is
  /// trivially unit-testable.
  ///
  /// Understands both response shapes:
  ///  * Google Translate (`translate_a/single`):
  ///    `[ [ [ "translated", "original", ... ], ... ], null, "en", ... ]`
  ///  * MyMemory (`/get`): `{ "responseData": { "translatedText": "..." } }`
  static String? parseTranslation(String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }

    // ── Google Translate shape ──────────────────────────────────────────────
    // A top-level list whose first element is the list of sentence groups;
    // each group's first element is its translated text.
    if (decoded is List) {
      final Object? sentences = decoded.isEmpty ? null : decoded.first;
      if (sentences is! List) return null;
      final StringBuffer buffer = StringBuffer();
      for (final Object? sentence in sentences) {
        if (sentence is! List || sentence.isEmpty) continue;
        final Object? text = sentence.first;
        if (text is String && text.isNotEmpty) buffer.write(text);
      }
      final String joined = buffer.toString().trim();
      return joined.isEmpty ? null : joined;
    }

    // ── MyMemory shape ──────────────────────────────────────────────────────
    if (decoded is! Map<String, dynamic>) return null;
    final Object? data = decoded['responseData'];
    if (data is! Map<String, dynamic>) return null;
    final Object? text = data['translatedText'];
    if (text is! String) return null;

    final String trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // MyMemory places diagnostics in this field when it cannot translate.
    final String upper = trimmed.toUpperCase();
    const List<String> failureMarkers = <String>[
      'NO QUERY SPECIFIED',
      'INVALID',
      'MYMEMORY WARNING',
      "'AUTOMATED TRANSLATION'",
    ];
    for (final String marker in failureMarkers) {
      if (upper.contains(marker)) return null;
    }
    return trimmed;
  }
}

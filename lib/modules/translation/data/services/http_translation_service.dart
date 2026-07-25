import 'dart:convert';
import 'dart:io';

import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/modules/translation/domain/services/remote_translation_service.dart';

/// Default [RemoteTranslationService] backed by a configurable HTTP endpoint
/// (MyMemory by default — free and keyless), using `dart:io` so no extra
/// package dependency is required.
///
/// The response parsing is isolated in the pure, static [parseTranslation] so it
/// can be unit-tested without any network access.
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

    final Uri uri = Uri.parse(_endpoint).replace(
      queryParameters: <String, String>{
        'q': q,
        'langpair': 'en|$targetLanguageCode',
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

  /// Parses a MyMemory-style JSON response, returning the translated text or
  /// `null` when the payload carries no usable translation. Pure and static so
  /// it is trivially unit-testable.
  static String? parseTranslation(String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }
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

import 'dart:convert';

import 'package:lexiora/modules/ai_assistant/config/ai_config.dart';
import 'package:lexiora/modules/ai_assistant/data/services/ai_api_client.dart';

class AiWordTranslationService {
  const AiWordTranslationService(this._client, this._config);
  final AiApiClient _client;
  final AiConfig _config;

  Future<String?> translate({
    required String word,
    required String targetLanguageCode,
  }) async {
    final String query = word.trim();
    final String target = targetLanguageCode.trim().toLowerCase();
    if (query.isEmpty || target != 'ur' || !_config.isConfigured) return null;
    try {
      final StringBuffer output = StringBuffer();
      await for (final String payload in _client.streamSse(<String, dynamic>{
        'model': _config.model,
        'provider': _config.provider.wireValue,
        'stream': true,
        'temperature': 0.1,
        'max_tokens': 120,
        'messages': <Map<String, String>>[
          <String, String>{
            'role': 'system',
            'content': 'Translate ONE English word to natural Urdu for Pakistani students. Return ONLY JSON: {"translation":"..."}. Give concise Urdu meanings, not a sentence or explanation.',
          },
          <String, String>{
            'role': 'user',
            'content': 'Translate this single English word to Urdu: "$query"',
          },
        ],
      })) {
        final String? delta = _streamDelta(payload);
        if (delta != null) output.write(delta);
      }
      return _parse(output.toString());
    } on Object {
      return null;
    }
  }

  static String? _streamDelta(String payload) {
    try {
      final Object? decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final Object? choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final Object? first = choices.first;
      if (first is! Map) return null;
      final Object? delta = first['delta'];
      if (delta is Map && delta['content'] is String) return delta['content'] as String;
      final Object? message = first['message'];
      if (message is Map && message['content'] is String) return message['content'] as String;
    } on Object {}
    return null;
  }

  static String? _parse(String raw) {
    final int start = raw.indexOf('{');
    final int end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final Object? decoded = jsonDecode(raw.substring(start, end + 1));
      if (decoded is! Map<String, dynamic>) return null;
      final String value = decoded['translation']?.toString().trim() ?? '';
      if (value.isEmpty) return null;
      final bool hasUrdu = value.runes.any((int r) => (r >= 0x0600 && r <= 0x06FF) || (r >= 0x0750 && r <= 0x077F));
      return hasUrdu ? value : null;
    } on Object {
      return null;
    }
  }
}
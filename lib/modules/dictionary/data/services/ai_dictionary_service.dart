import 'dart:convert';

import 'package:lexiora/modules/ai_assistant/config/ai_config.dart';
import 'package:lexiora/modules/ai_assistant/data/services/ai_api_client.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';

/// Requests a strict, exam-focused word profile directly from the existing AI
/// Worker. This is intentionally separate from the conversational Assistant UI.
class AiDictionaryService {
  const AiDictionaryService(this._client, this._config);

  final AiApiClient _client;
  final AiConfig _config;

  Future<AiWordProfile?> define(
    String word, {
    List<String> missingFields = const <String>[],
  }) async {
    final String query = word.trim();
    if (query.isEmpty || !_config.isConfigured) return null;

    try {
      final List<String> fields = missingFields.isEmpty
          ? const <String>[
              'englishDefinition',
              'urduMeanings',
              'partOfSpeech',
              'synonyms',
              'antonyms',
              'exampleSentence',
              'exampleSentenceUrdu',
              'collocations',
              'wordForms',
              'examNote',
            ]
          : missingFields;
      final StringBuffer content = StringBuffer();
      await for (final String payload in _client.streamSse(
        <String, dynamic>{
          'model': _config.model,
          'provider': _config.provider.wireValue,
          'stream': true,
          'temperature': 0.1,
          'max_tokens': 600,
          'messages': <Map<String, String>>[
            <String, String>{
              'role': 'system',
              'content': '''You are Lexiora's exam English dictionary. Return ONLY valid JSON, with no markdown and no commentary. Give the most common, precise meaning intended for CSS/BPSC/competitive-exam learners. Do not invent a rare meaning. Use short natural Urdu meanings. Use empty arrays or null only when genuinely unavailable. The JSON keys must be exactly: word, englishDefinition, urduMeanings, partOfSpeech, synonyms, antonyms, exampleSentence, exampleSentenceUrdu, collocations, wordForms, examNote. For exampleSentence, write one natural competitive-exam English sentence containing the headword; exampleSentenceUrdu must be a faithful Urdu translation of that exact sentence. For wordForms, give useful derivational/inflectional family forms when they genuinely exist; do not invent forms. If a requested field genuinely has no reliable answer (for example a word has no natural antonym), return an empty array or null rather than inventing one.''',
            },
            <String, String>{
              'role': 'user',
              'content': 'Create the dictionary profile for the English word "$query". Fill these missing fields: ${fields.join(', ')}. Return empty values for all other fields. Confirm that the returned word is the same headword.',
            },
          ],
        },
      )) {
        final String? delta = _streamDelta(payload);
        if (delta != null) content.write(delta);
      }

      final String raw = content.toString().trim();
      if (raw.isEmpty) return null;
      return _parse(raw, query);
    } on Object {
      // AI is an optional enhancement. The caller keeps the offline profile.
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
      if (delta is Map && delta['content'] is String) {
        return (delta['content'] as String);
      }
      final Object? message = first['message'];
      if (message is Map && message['content'] is String) {
        return (message['content'] as String);
      }
      return null;
    } on Object {
      return null;
    }
  }

  static String? _content(Map<String, dynamic> response) {
    final Object? choices = response['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final Object? first = choices.first;
    if (first is! Map<String, dynamic>) return null;
    final Object? message = first['message'];
    if (message is Map<String, dynamic>) {
      final Object? value = message['content'];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    final Object? text = first['text'];
    return text is String && text.trim().isNotEmpty ? text.trim() : null;
  }

  static AiWordProfile? _parse(String raw, String requestedWord) {
    String jsonText = raw.trim();
    if (jsonText.startsWith('```')) {
      jsonText = jsonText.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      jsonText = jsonText.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final int start = jsonText.indexOf('{');
    final int end = jsonText.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final Object? decoded = jsonDecode(jsonText.substring(start, end + 1));
      if (decoded is! Map<String, dynamic>) return null;
      final String returnedWord = decoded['word']?.toString().trim().toLowerCase() ?? '';
      if (returnedWord.isEmpty || returnedWord != requestedWord.toLowerCase()) return null;
      return AiWordProfile.fromJson(decoded);
    } on Object {
      return null;
    }
  }
}

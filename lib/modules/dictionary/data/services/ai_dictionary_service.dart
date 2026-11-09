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
      final Map<String, dynamic> response = await _client.postJson(
        <String, dynamic>{
          'model': _config.model,
          'provider': _config.provider.wireValue,
          'stream': false,
          'temperature': 0.1,
          'max_tokens': 900,
          'messages': <Map<String, String>>[
            <String, String>{
              'role': 'system',
              'content': '''You are DarsNexa's exam English dictionary. Return ONLY one valid JSON object, with no markdown, commentary, or extra text. The response MUST contain every key: word, englishDefinition, urduMeanings, partOfSpeech, synonyms, antonyms, exampleSentence, exampleSentenceUrdu, collocations, wordForms, examNote. Give a precise common meaning for CSS/BPSC learners. Give a short natural Urdu meaning. Give 3-5 semantically accurate synonyms and 2-4 accurate antonyms when they genuinely exist; never invent. Give useful word-family forms when they genuinely exist. Give one natural competitive-exam English sentence containing the headword and a faithful Urdu translation. Give a concise exam note. If a field genuinely has no reliable value, use an empty array or null, but never omit a required key.''',
            },
            <String, String>{
              'role': 'user',
              'content': 'Create the COMPLETE dictionary profile for the English word "$query". Fill every field. The returned word must exactly match the requested headword.',
            },
          ],
        },
      );
      final String raw = (_content(response) ?? '').trim();
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

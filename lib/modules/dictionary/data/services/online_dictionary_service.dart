import 'dart:convert';
import 'dart:io';

import 'package:lexiora/modules/dictionary/data/services/definition_sense.dart';

/// A single online English definition — just enough to display in the
/// translate popup's "ENGLISH MEANING" section.
class OnlineDefinition {
  const OnlineDefinition({
    required this.meaning,
    this.partOfSpeech,
    this.phonetic,
    this.audioUrl,
    this.senses = const <OnlineSense>[],
    this.synonyms = const <String>[],
    this.antonyms = const <String>[],
  });

  final String meaning;
  final String? partOfSpeech;
  final String? phonetic;
  final String? audioUrl;
  final List<OnlineSense> senses;
  final List<String> synonyms;
  final List<String> antonyms;
}

class OnlineSense {
  const OnlineSense({
    required this.meaning,
    this.partOfSpeech,
    this.example,
  });

  final String meaning;
  final String? partOfSpeech;
  final String? example;
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

  /// Parses a Free Dictionary API response. The first definition remains the
  /// translation service's best meaning, while the complete useful payload is
  /// retained for the dictionary's non-authoritative enrichment path.
  ///
  /// The API orders senses by corpus frequency, which often puts a rare,
  /// literary or technical sense first ("attention" → "treatment", "tragedy" →
  /// "a type of drama"). [pickBestDefinitionIndex] re-ranks them so the sense
  /// shown to CSS/BPSC readers is the general one.
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

    final List<String> defs = <String>[];
    final List<String?> poses = <String?>[];
    final List<OnlineSense> senses = <OnlineSense>[];
    final Set<String> synonyms = <String>{};
    final Set<String> antonyms = <String>{};
    for (final Object? m in meanings) {
      if (m is! Map<String, dynamic>) continue;
      final Object? pos = m['partOfSpeech'];
      final String? posStr = pos is String && pos.isNotEmpty ? pos : null;
      _addStrings(synonyms, m['synonyms']);
      _addStrings(antonyms, m['antonyms']);
      final Object? definitions = m['definitions'];
      if (definitions is! List) continue;
      for (final Object? d in definitions) {
        if (d is! Map<String, dynamic>) continue;
        final Object? text = d['definition'];
        if (text is String && text.trim().isNotEmpty) {
          final String definition = text.trim();
          final String? example = _text(d['example']);
          defs.add(definition);
          poses.add(posStr);
          senses.add(OnlineSense(
            meaning: definition,
            partOfSpeech: posStr,
            example: example,
          ));
        }
      }
    }
    if (defs.isEmpty) return null;
    final int? best = pickBestDefinitionIndex(defs);
    if (best == null) return null;
    return OnlineDefinition(
      meaning: defs[best],
      partOfSpeech: poses[best],
      phonetic: _text(first['phonetic']) ?? _firstPhonetic(first['phonetics']),
      audioUrl: _firstAudio(first['phonetics']),
      senses: senses,
      synonyms: synonyms.toList(growable: false),
      antonyms: antonyms.toList(growable: false),
    );
  }

  static void _addStrings(Set<String> target, Object? value) {
    if (value is! List) return;
    for (final Object? item in value) {
      final String? text = _text(item);
      if (text != null) target.add(text);
    }
  }

  static String? _firstPhonetic(Object? value) {
    if (value is! List) return null;
    for (final Object? item in value) {
      if (item is Map) {
        final String? phonetic = _text(item['text']);
        if (phonetic != null) return phonetic;
      }
    }
    return null;
  }

  static String? _firstAudio(Object? value) {
    if (value is! List) return null;
    for (final Object? item in value) {
      if (item is Map) {
        final String? audio = _text(item['audio']);
        if (audio != null) return audio;
      }
    }
    return null;
  }

  static String? _text(Object? value) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

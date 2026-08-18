import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Deterministic daily word selection from the bundled Dictionary data.
///
/// Picks one word per day based on the UTC date, so the same word stays
/// visible all day and changes automatically at midnight.  Works fully
/// offline — reads the bundled JSON asset once and caches it.
class WordOfDayService {
  WordOfDayService._();

  static List<Map<String, dynamic>>? _cache;

  /// Returns today's word as a map with keys:
  /// `word`, `englishDefinition`, `urduMeanings`, `partOfSpeech`.
  /// Returns `null` if the asset can't be loaded.
  static Future<Map<String, dynamic>?> today() async {
    final List<Map<String, dynamic>> entries = await _load();
    if (entries.isEmpty) return null;

    // Deterministic index: days since Unix epoch mod entry count.
    final int dayIndex =
        DateTime.now().toUtc().difference(DateTime.utc(1970, 1, 1)).inDays;
    final int index = dayIndex % entries.length;
    return entries[index];
  }

  static Future<List<Map<String, dynamic>>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final String raw =
          await rootBundle.loadString('assets/dictionary/gre_high_frequency.json');
      final List<dynamic> decoded = jsonDecode(raw);
      _cache = decoded
          .whereType<Map<String, dynamic>>()
          .where((Map<String, dynamic> e) {
        final String word = (e['word'] as String?)?.trim() ?? '';
        final String def = (e['englishDefinition'] as String?)?.trim() ?? '';
        return word.isNotEmpty && def.isNotEmpty;
      }).toList();
    } catch (_) {
      _cache = <Map<String, dynamic>>[];
    }
    return _cache!;
  }
}

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
  static Future<Map<String, dynamic>?> today() async =>
      forDate(DateTime.now());

  /// Returns the same deterministic entry that [today] would use for [date].
  /// The calendar day is normalized in UTC to match the Home card's existing
  /// day boundary and avoid device-timezone-dependent selection changes.
  static Future<Map<String, dynamic>?> forDate(DateTime date) async {
    final List<Map<String, dynamic>> entries = await _load();
    if (entries.isEmpty) return null;

    return entries[indexForDate(date, entries.length)];
  }

  /// Returns the deterministic entry index for a calendar date and pool size.
  /// Kept pure so the date contract can be verified without asset loading.
  static int indexForDate(DateTime date, int poolLength) {
    if (poolLength <= 0) return 0;
    final DateTime utcDay = DateTime.utc(date.year, date.month, date.day);
    // The bundled pack is alphabetically ordered. Walking it with
    // `dayIndex % poolLength` makes Word of the Day visibly move A→B→C.
    // Hash the calendar date instead: selection remains stable for a day and
    // fully deterministic/offline, but no longer follows asset order.
    final String key =
        '${utcDay.year.toString().padLeft(4, '0')}-'
        '${utcDay.month.toString().padLeft(2, '0')}-'
        '${utcDay.day.toString().padLeft(2, '0')}';
    var hash = 2166136261;
    for (final int codeUnit in key.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash % poolLength;
  }

  static Future<List<Map<String, dynamic>>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final String raw =
          await rootBundle.loadString('assets/dictionary/gre_high_frequency.json');
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
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

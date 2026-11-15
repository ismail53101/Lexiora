import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/database/tables.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';

/// Persistent on-device cache for successful AI dictionary lookups.
///
/// Cached profiles use the existing Settings key/value table, so no schema
/// migration is required. The cache survives app restarts.
class AiDictionaryCache {
  AiDictionaryCache(this._db);

  final AppDatabase _db;

  static const String _prefix = 'ai_dictionary_cache_v1:';

  String _key(String wordLower) => '$_prefix$wordLower';

  Future<AiWordProfile?> get(String word) async {
    final String wordLower = word.trim().toLowerCase();
    if (wordLower.isEmpty) return null;

    final SettingRow? row = await (_db.select(_db.settings)
          ..where((Settings table) => table.key.equals(_key(wordLower))))
        .getSingleOrNull();

    if (row == null || row.value.trim().isEmpty) return null;

    try {
      final Object? decoded = jsonDecode(row.value);
      if (decoded is! Map<String, dynamic>) return null;

      final AiWordProfile profile = AiWordProfile.fromJson(decoded);
      if (profile.word.trim().toLowerCase() != wordLower ||
          !profile.hasContent) {
        return null;
      }
      return profile;
    } on Object {
      return null;
    }
  }

  Future<void> put(AiWordProfile profile) async {
    final String wordLower = profile.word.trim().toLowerCase();
    if (wordLower.isEmpty || !profile.hasContent) return;

    final Map<String, dynamic> json = profile.toJson();
    json['cacheVersion'] = 1;

    await _db.into(_db.settings).insert(
          SettingsCompanion.insert(
            key: _key(wordLower),
            value: jsonEncode(json),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}

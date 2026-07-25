import 'package:drift/drift.dart';
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';

/// Local-database access for offline translations. Lookups hit the
/// `(lang_code, word_lower)` composite index, so a single-word translation is
/// fast even across the full multi-language table.
class TranslationLocalDataSource {
  TranslationLocalDataSource(this._db);

  final AppDatabase _db;

  /// Offline lookup: the bundled data set first, then the online cache. Both
  /// are local (no network), so a hit from either is an "offline" result.
  Future<String?> translate(String word, String languageCode) async {
    final String wl = word.trim().toLowerCase();
    if (wl.isEmpty || languageCode.isEmpty) return null;
    final TranslationEntryRow? row = await (_db.select(_db.translationEntries)
          ..where((t) =>
              t.langCode.equals(languageCode) & t.wordLower.equals(wl))
          ..limit(1))
        .getSingleOrNull();
    if (row != null) return row.translation;
    final TranslationCacheRow? cached = await _cacheRow(wl, languageCode);
    return cached?.translation;
  }

  // ── Online cache (Hybrid Translation System) ────────────────────────────────

  Future<TranslationCacheRow?> _cacheRow(String wordLower, String languageCode) =>
      (_db.select(_db.translationCache)
            ..where((t) =>
                t.langCode.equals(languageCode) & t.wordLower.equals(wordLower))
            ..limit(1))
          .getSingleOrNull();

  /// Whether an online translation is already cached for this word/language.
  Future<bool> isCached(String word, String languageCode) async {
    final String wl = word.trim().toLowerCase();
    if (wl.isEmpty || languageCode.isEmpty) return false;
    return await _cacheRow(wl, languageCode) != null;
  }

  /// Inserts (or refreshes) a cached translation. The composite primary key
  /// makes this an upsert, so the same word/language is never duplicated.
  Future<void> cacheTranslation({
    required String word,
    required String languageCode,
    required String translation,
    String source = 'online',
  }) async {
    final String wl = word.trim().toLowerCase();
    if (wl.isEmpty || languageCode.isEmpty) return;
    await _db.into(_db.translationCache).insert(
          TranslationCacheCompanion.insert(
            langCode: languageCode,
            wordLower: wl,
            word: word.trim(),
            translation: translation,
            source: Value<String>(source),
            createdAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Number of cached (online-fetched) translations — diagnostics / tests.
  Future<int> cachedCount() async {
    final Expression<int> countExp = _db.translationCache.wordLower.count();
    final query = _db.selectOnly(_db.translationCache)
      ..addColumns(<Expression<Object>>[countExp]);
    final TypedResult row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<int> entryCount() async {
    final Expression<int> countExp = _db.translationEntries.id.count();
    final query = _db.selectOnly(_db.translationEntries)
      ..addColumns([countExp]);
    final TypedResult row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  // ── Seeding support ───────────────────────────────────────────────────────

  Future<String?> seededVersion() async {
    final SettingRow? row = await (_db.select(_db.settings)
          ..where((t) => t.key.equals(TranslationConstants.seedVersionKey))
          ..limit(1))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSeededVersion(String version) async {
    await _db.into(_db.settings).insert(
          SettingsCompanion.insert(
            key: TranslationConstants.seedVersionKey,
            value: version,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> clearEntries() => _db.delete(_db.translationEntries).go();

  Future<void> insertEntries(List<TranslationEntriesCompanion> batch) =>
      _db.batch((Batch b) => b.insertAll(_db.translationEntries, batch));
}

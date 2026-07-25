/// Domain contract for word translation.
///
/// Offline-first: [translate] consults the local database only (the bundled data
/// set first, then the online cache). The online fetch itself lives behind
/// `RemoteTranslationService` and is orchestrated by the hybrid use case, which
/// persists successful results here via [cacheTranslation] so future lookups are
/// fully offline.
abstract interface class TranslationRepository {
  /// Returns the local translation of [word] into [languageCode] (bundled data
  /// or cached online result), or `null` when none exists locally.
  Future<String?> translate(String word, String languageCode);

  /// Total number of indexed (bundled) translation rows — diagnostics / seed
  /// check.
  Future<int> entryCount();

  /// Whether an online translation is already cached for this word/language.
  Future<bool> isCached(String word, String languageCode);

  /// Saves an online-fetched translation to the local cache for offline reuse.
  /// Idempotent: re-caching the same word/language refreshes the single row.
  Future<void> cacheTranslation({
    required String word,
    required String languageCode,
    required String translation,
  });

  /// Number of cached (online-fetched) translations.
  Future<int> cachedCount();
}

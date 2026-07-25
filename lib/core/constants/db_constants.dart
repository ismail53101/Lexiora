/// Single source of truth for database identifiers and schema versioning.
abstract final class DbConstants {
  /// The Drift/SQLite database file name (without extension).
  static const String databaseName = 'lexiora';

  /// Bump this whenever the schema changes and add a migration step.
  ///
  /// v1 → v2 (Phase 2.1): adds the offline Dictionary tables
  /// (`dictionary_entries`, `dictionary_favorites`) and their indexes.
  /// v2 → v3: adds `documents.managed_file` (distinguishes app-imported copies
  /// from in-place auto-discovered files).
  /// v3 → v4: adds `translation_entries` (offline Translate feature).
  static const int schemaVersion = 4;
}

/// Constants for the bundled offline translation data set.
abstract final class TranslationConstants {
  /// Bundled, gzip-compressed JSON-Lines data set (see assets/translations).
  static const String assetPath = 'assets/translations/translations.jsonl.gz';

  /// Version tag of the bundled data set. Seeding re-runs whenever the value
  /// stored in settings differs from this. Bumped when the English→Urdu data
  /// was significantly expanded (academic/newspaper/exam vocabulary), so
  /// existing installs re-seed to pick up the larger set.
  static const String datasetVersion = 'freedict+wiktionary-ur-2026.07-exam';

  /// Settings key under which the seeded translation data-set version is kept.
  static const String seedVersionKey = 'translation_seed_version';

  /// Rows inserted per batch while seeding.
  static const int seedBatchSize = 2000;
}

/// Constants for the bundled offline dictionary data set.
abstract final class DictionaryConstants {
  /// Bundled, gzip-compressed JSON-Lines data set (see assets/dictionary).
  static const String assetPath = 'assets/dictionary/wordset.jsonl.gz';

  /// Version tag of the bundled data set. Seeding re-runs (clearing the
  /// read-only entries table, never the user's favorites) whenever the value
  /// stored in settings differs from this — so shipping a larger data set later
  /// is a one-line bump.
  static const String datasetVersion = 'wordset-2026.07';

  /// Settings key under which the seeded data-set version is recorded.
  static const String seedVersionKey = 'dictionary_seed_version';

  /// Rows inserted per batch while seeding (balances speed vs. memory).
  static const int seedBatchSize = 2000;
}

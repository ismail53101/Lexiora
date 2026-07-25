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
  /// v4 → v5 (Phase v0.4.0): adds the offline Grammar tables
  /// (`grammar_lessons`, `grammar_progress`, `grammar_favorites`) and indexes.
  /// v5 → v6 (Phase v0.4.1): adds `translation_cache` for online-fetched
  /// translations saved for offline reuse (Hybrid Translation System).
  /// v6 → v7 (Phase v0.4.2): Dictionary v2 — adds `dictionary_exam_entries`
  /// (curated exam-oriented word pack) and `dictionary_search_history`.
  /// v7 → v8 (Phase v0.5.0): Grammar hierarchy — adds `grammar_topics` (a
  /// Category → Subcategory → Lesson tree). Existing grammar_progress /
  /// grammar_favorites are reused, keyed by leaf topic id.
  static const int schemaVersion = 8;
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

  // ── Online fallback (Hybrid Translation System, v0.4.1) ─────────────────────

  /// Endpoint of the default online translation provider. It is abstracted
  /// behind `RemoteTranslationService`, so swapping providers (e.g. to
  /// LibreTranslate or a paid API) is a one-line binding change and requires no
  /// UI changes. Default is MyMemory — free and keyless.
  static const String remoteEndpoint =
      'https://api.mymemory.translated.net/get';

  /// Human-readable provider name (diagnostics/logs only; the UI shows a
  /// generic "Online" source label).
  static const String remoteProviderName = 'MyMemory';

  /// Network timeout for a single online translation request.
  static const Duration remoteTimeout = Duration(seconds: 8);
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

/// Constants for the curated, exam-oriented dictionary word packs (Dictionary v2).
///
/// A hand-authored data set that layers rich, exam-focused content (ordered Urdu
/// meanings, synonyms/antonyms, context usage, collocations, word forms, idioms,
/// exam notes) on top of the large base dictionary.
///
/// **Data-driven, multi-pack loading:** the seeder auto-discovers and merges
/// EVERY `*.json` file under [assetDir] into `dictionary_exam_entries` — not
/// just [assetPath]. To ship thousands more curated words later, drop additional
/// `*.json` packs into `assets/dictionary/` and rebuild; no Dart change is
/// needed (the directory is already declared in pubspec, and the seed version is
/// derived from the packs' content signature, so a new/edited pack re-seeds
/// automatically). Re-seeding rebuilds this table only — never favorites or
/// search history. The base dictionary ships as `.jsonl.gz` (see
/// [DictionaryConstants]) and is therefore excluded by the `.json` filter.
abstract final class ExamDictionaryConstants {
  /// Directory scanned for curated word packs (every `*.json` file within).
  static const String assetDir = 'assets/dictionary/';

  /// File extension that marks a curated word pack.
  static const String packSuffix = '.json';

  /// The original single curated pack. Still shipped and loaded; also used as a
  /// safe fallback when the asset manifest cannot be read (e.g. some tests).
  static const String assetPath = 'assets/dictionary/exam_words.json';

  /// Manual version prefix. The effective seed version appends a content
  /// signature of all discovered packs, so you rarely need to bump this — but
  /// bumping it still forces a one-off re-seed if ever required.
  static const String datasetVersion = 'exam-words-2026.07-expanded';
  static const String seedVersionKey = 'dictionary_exam_seed_version';
  static const int seedBatchSize = 200;
}

/// Constants for the local search-history feature.
abstract final class SearchHistoryConstants {
  /// Maximum number of recent searches kept; older entries are pruned.
  static const int maxEntries = 100;
}

/// Constants for the bundled offline grammar lessons data set.
///
/// The grammar corpus is small (a fixed set of curated lessons), so it ships as
/// a plain (uncompressed) JSON array and is seeded once into the
/// `grammar_lessons` table. Progress and favorites live in separate tables, so
/// the lessons can be re-seeded (to ship new/updated content) without ever
/// touching what the user has read or saved.
abstract final class GrammarConstants {
  /// Bundled hierarchical topics tree (Category → Subcategory → Lesson).
  static const String topicsAssetPath = 'assets/grammar/grammar_topics.json';
  static const String topicsDatasetVersion = 'grammar-topics-2026.07-complete';
  static const String topicsSeedVersionKey = 'grammar_topics_seed_version';

  /// Bundled JSON lessons data set (legacy flat model; superseded by the tree).
  static const String assetPath = 'assets/grammar/grammar_lessons.json';

  /// Version tag of the bundled data set. Seeding re-runs (rebuilding the
  /// read-only lessons table, never the user's progress or favorites) whenever
  /// the value stored in settings differs from this — so shipping more or
  /// updated lessons later is a one-line bump plus an updated asset.
  static const String datasetVersion = 'grammar-2026.07';

  /// Settings key under which the seeded data-set version is recorded.
  static const String seedVersionKey = 'grammar_seed_version';

  /// Rows inserted per batch while seeding.
  static const int seedBatchSize = 100;
}

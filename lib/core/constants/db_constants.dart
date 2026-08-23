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
  /// v8 → v9 (Phase v0.6.0): Vocabulary module — adds `vocabulary_lists` and
  /// `vocabulary_words` (A–Z learning word lists). Purely additive.
  /// v9 → v10 (Phase v0.7.0): Study Hub — adds `study_tasks`, `study_goals`
  /// and `study_sessions` (personal learning dashboard). Purely additive.
  /// v10 → v11 (Phase v0.7.1): Study Hub → Academic Planning System. Adds
  /// columns (topic, notes, status, duration_minutes, kind) to `study_tasks`
  /// and new `study_templates` / `study_template_items` tables. Purely additive;
  /// existing Study Hub data remains valid.
  /// v11 → v12 (Phase v0.7.2): Study Hub productivity — adds `study_subjects`
  /// (custom subject colours + archive) and indexes for fast search/filter.
  /// Purely additive.
  /// v12 → v13 (Phase v0.8.0): Flashcards module — adds `decks`, `flashcards`
  /// (SM-2-ready) and `review_logs`, plus indexes. Purely additive.
  /// v13 → v14 (Phase v0.9.0): Quiz Engine — adds `quiz_banks`,
  /// `quiz_questions`, `quiz_attempts`, `quiz_attempt_answers`,
  /// `quiz_wrong_answers` and `quiz_settings_rows`, plus indexes. Ships empty
  /// (questions are content, loaded later via JSON/Admin/Cloud). Purely additive.
  /// v14 → v15 (Phase v0.9.1): Quiz Engine subject-first hierarchy — adds
  /// `quiz_subjects` and `quiz_topics`, plus `subject_id`/`topic_id`/`order_index`
  /// columns on `quiz_banks` and `subject_id`/`topic_id` on `quiz_questions`.
  /// Purely additive; existing v14 quiz data remains valid.
  /// v15 → v16 (Phase v0.10.0): AI Assistant — adds `ai_conversations` and
  /// `ai_messages` (offline chat persistence), plus indexes. Purely additive.
  /// v16 → v17 (Phase v0.10.1): Staged Quiz progress. Purely additive.
  /// v17 → v18: Study Planner automatic/manual scheduling state. Additive;
  /// existing task rows default to manual scheduling.
  static const int schemaVersion = 18;
}

/// Constants for the Quiz Engine's one-time demo seed.
///
/// The demo ships a handful of bundled sample subjects/topics/quizzes so the
/// subject-first learning workflow is visible out of the box. It is seeded once
/// into the normal quiz tables as read-only published content the app consumes;
/// the app never authors content. Bumping [datasetVersion] re-seeds ONLY the
/// demo rows (tagged by source 'demo'), never user attempt history.
abstract final class QuizConstants {
  static const String seedVersionKey = 'quiz_demo_seed_version';
  static const String datasetVersion = 'quiz-demo-2026.08-grammar-bank-v2';

  /// Bank/subject `source` tag marking rows created by the demo seeder.
  static const String demoSource = 'demo';

  /// Compatibility name used by the Quiz seeder for bundled demo content.
  static const String bundledSource = demoSource;
}

/// Constants for the AI Assistant module (Phase v0.10.0).
///
/// The provider is OpenAI-compatible. The API key is NEVER hardcoded or stored
/// in the database — it is supplied at build time via a compile-time
/// environment define (`--dart-define=SAPIORA_AI_API_KEY=...`) and only ever
/// held in memory. Base URL and model also fall back to environment defines so
/// a different endpoint/model can be configured without code changes.
abstract final class AiConstants {
  /// Compile-time environment variable names (`String.fromEnvironment`).
  static const String envApiKey = 'SAPIORA_AI_API_KEY';
  static const String envBaseUrl = 'SAPIORA_AI_BASE_URL';
  static const String envModel = 'SAPIORA_AI_MODEL';
  static const String envProvider = 'SAPIORA_AI_PROVIDER';

  /// Defaults used when the corresponding define is not provided.
  static const String defaultBaseUrl =
      'https://sapiora-ai-worker.ismaillasharibaloch53.workers.dev';
  static const String defaultModel = 'auto';
  /// 'auto' means the Cloudflare Worker itself picks/falls back between its
  /// configured upstream providers — the app never needs to know which
  /// providers exist or choose between them.
  static const String defaultProvider = 'auto';

  /// OpenAI-compatible chat-completions path appended to the base URL.
  static const String chatCompletionsPath = '/v1/chat/completions';

  /// Network timeouts.
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration idleTimeout = Duration(seconds: 60);

  /// Messages fetched per page (lazy loading of long conversations).
  static const int messagePageSize = 40;
}

/// Constants for the bundled offline translation data set.
abstract final class TranslationConstants {
  /// Directory containing optional translation JSON packs.
  static const String assetDir = 'assets/translations/';

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

/// Constants for the bundled offline Vocabulary word packs (Phase v0.6.0).
///
/// The Vocabulary module ships organized A–Z learning lists. Like the curated
/// dictionary packs, it uses a **data-driven, multi-pack loader**: every
/// `*.json` file under [assetDir] is auto-discovered and merged (one pack per
/// list). To add a list (e.g. GRE, Oxford 3000, IELTS) drop a new `*.json` pack
/// into `assets/vocabulary/` and rebuild — no Dart change is needed (the
/// directory is declared in pubspec and the seed version is a content signature
/// of all packs, so a new/edited pack re-seeds automatically). Re-seeding
/// rebuilds the vocabulary tables only; no user data is affected.
abstract final class VocabularyConstants {
  /// Directory scanned for vocabulary packs (every `*.json` file within).
  static const String assetDir = 'assets/vocabulary/';

  /// File extension that marks a vocabulary pack.
  static const String packSuffix = '.json';

  /// Manual version prefix; the effective seed version appends a content
  /// signature of all discovered packs, so bumping this is rarely needed.
  static const String datasetVersion = 'vocabulary-2026.07';
  static const String seedVersionKey = 'vocabulary_seed_version';
  static const int seedBatchSize = 500;
}

/// Constants for the Study Hub module (Phase v0.7.0).
///
/// Study Hub stores only user data (tasks, goals, sessions) in dedicated tables.
/// The lightweight preference below (the last-used Pomodoro mode) is kept in the
/// shared key-value [Settings] store so it needs no schema of its own.
abstract final class StudyHubConstants {
  /// Settings key holding the user's last-selected Pomodoro mode label.
  static const String pomodoroModeKey = 'studyhub_pomodoro_mode';

  /// Rolling window sizes (in days) for the weekly/monthly views.
  static const int weeklyDays = 7;
  static const int monthlyDays = 30;
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
  static const String topicsDatasetVersion = 'grammar-topics-2026.08-tenses-master-v23';
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

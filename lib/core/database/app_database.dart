import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:lexiora/core/constants/db_constants.dart';
// converters.dart + normalized_rect.dart are imported so the generated part
// (app_database.g.dart) can resolve the NormalizedRectListConverter and
// NormalizedRect types used by the highlight/note rect columns.
import 'package:lexiora/core/database/converters.dart';
import 'package:lexiora/core/database/tables.dart';
import 'package:lexiora/core/models/normalized_rect.dart';

part 'app_database.g.dart';

/// The single Drift database for Lexiora.
///
/// All features share one SQLite database (one file, one source of truth) while
/// each feature's repository owns its own queries. New tables for future
/// modules are added here with a bumped [schemaVersion] and a migration step —
/// existing tables are never rewritten.
@DriftDatabase(
  tables: [
    Documents,
    Categories,
    Bookmarks,
    Highlights,
    Notes,
    ReadingProgress,
    ReadingSessions,
    Settings,
    DictionaryEntries,
    DictionaryFavorites,
    DictionaryExamEntries,
    DictionarySearchHistory,
    TranslationEntries,
    TranslationCache,
    GrammarLessons,
    GrammarProgress,
    GrammarFavorites,
    GrammarTopics,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database. A custom [executor] can be injected for
  /// tests (e.g. an in-memory database).
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => DbConstants.schemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v1 → v2: introduce the offline Dictionary tables. Purely additive —
          // existing tables and their data are left untouched.
          if (from < 2) {
            await m.createTable(dictionaryEntries);
            await m.createTable(dictionaryFavorites);
          }
          // v2 → v3: add the managed-file flag to documents. Additive; existing
          // rows default to false (in-place, never auto-deleted).
          if (from < 3) {
            await m.addColumn(documents, documents.managedFile);
          }
          // v3 → v4: add the offline translation table. Additive.
          if (from < 4) {
            await m.createTable(translationEntries);
          }
          // v4 → v5: add the offline Grammar tables. Purely additive —
          // existing tables and their data are left untouched.
          if (from < 5) {
            await m.createTable(grammarLessons);
            await m.createTable(grammarProgress);
            await m.createTable(grammarFavorites);
          }
          // v5 → v6: add the online-translation cache. Additive; the bundled
          // translation table and all existing data are untouched.
          if (from < 6) {
            await m.createTable(translationCache);
          }
          // v6 → v7: Dictionary v2 — curated exam word pack + search history.
          // Additive; existing dictionary tables and data are untouched.
          if (from < 7) {
            await m.createTable(dictionaryExamEntries);
            await m.createTable(dictionarySearchHistory);
          }
          // v7 → v8: Grammar hierarchy tree. Additive; grammar_progress and
          // grammar_favorites are reused (keyed by leaf id).
          if (from < 8) {
            await m.createTable(grammarTopics);
          }
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Search-critical indexes. Created idempotently on every open so they
          // exist on both fresh installs and upgrades without special-casing.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_dictionary_word_lower '
            'ON dictionary_entries (word_lower)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_dictionary_word_lower_id '
            'ON dictionary_entries (word_lower, id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_translation_lang_word '
            'ON translation_entries (lang_code, word_lower)',
          );
          // Grammar: fast category+order listing and substring search.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_grammar_category_order '
            'ON grammar_lessons (category, order_index)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_grammar_search '
            'ON grammar_lessons (search_text)',
          );
          // Grammar tree: fast children lookups and leaf search.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_grammar_topics_parent '
            'ON grammar_topics (parent_id, order_index)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_grammar_topics_search '
            'ON grammar_topics (search_text)',
          );
        },
      );

  static QueryExecutor _openConnection() =>
      driftDatabase(name: DbConstants.databaseName);
}

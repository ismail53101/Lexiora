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
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() =>
      driftDatabase(name: DbConstants.databaseName);
}

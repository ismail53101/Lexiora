/// Single source of truth for database identifiers and schema versioning.
abstract final class DbConstants {
  /// The Drift/SQLite database file name (without extension).
  static const String databaseName = 'lexiora';

  /// Bump this whenever the schema changes and add a migration step.
  static const int schemaVersion = 1;
}

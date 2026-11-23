/// One result row: column name → value (int, double, String or null).
typedef Row = Map<String, Object?>;

/// The tiny slice of SQL access the flashcards engine needs. In the app it is
/// backed by the shared Drift database ([DriftFcSql]); tests may supply any
/// other implementation.
abstract interface class FcSql {
  Future<List<Row>> select(String sql, [List<Object?> args]);
  Future<void> execute(String sql, [List<Object?> args]);

  /// Runs all [statements] atomically.
  Future<void> executeAll(List<({String sql, List<Object?> args})> statements);
  Future<T> transaction<T>(Future<T> Function() action);
}

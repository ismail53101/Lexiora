import 'package:drift/drift.dart';

/// One result row: column name → value (int, double, String or null).
typedef SqlRow = Map<String, Object?>;

/// The small slice of SQL access that feature modules need for their own
/// extra tables (created with plain SQL, so no Drift code generation is
/// required). In the app it is backed by the shared Drift database.
abstract interface class RawSql {
  Future<List<SqlRow>> select(String sql, [List<Object?> args]);
  Future<void> execute(String sql, [List<Object?> args]);

  /// Runs all [statements] atomically.
  Future<void> executeAll(List<({String sql, List<Object?> args})> statements);
  Future<T> transaction<T>(Future<T> Function() action);
}

class DriftRawSql implements RawSql {
  DriftRawSql(this._db);

  final GeneratedDatabase _db;

  static Variable<Object> _variable(Object? v) {
    if (v == null) return const Variable<Object>(null);
    if (v is bool) return Variable<Object>(v ? 1 : 0);
    if (v is int || v is double) return Variable<Object>(v);
    return Variable<Object>(v.toString());
  }

  @override
  Future<List<SqlRow>> select(String sql,
      [List<Object?> args = const <Object?>[]]) async {
    final List<QueryRow> rows = await _db
        .customSelect(sql, variables: args.map(_variable).toList())
        .get();
    return rows.map((QueryRow r) => r.data).toList();
  }

  @override
  Future<void> execute(String sql, [List<Object?> args = const <Object?>[]]) =>
      _db.customStatement(sql, args);

  @override
  Future<void> executeAll(
          List<({String sql, List<Object?> args})> statements) =>
      _db.batch((Batch b) {
        for (final ({String sql, List<Object?> args}) s in statements) {
          b.customStatement(s.sql, s.args);
        }
      });

  @override
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);
}

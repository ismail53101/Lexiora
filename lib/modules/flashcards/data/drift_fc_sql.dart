import 'package:drift/drift.dart';
import 'package:lexiora/modules/flashcards/data/fc_sql.dart';

/// [FcSql] backed by the app's shared Drift database.
class DriftFcSql implements FcSql {
  DriftFcSql(this._db);

  final GeneratedDatabase _db;

  static Variable<Object> _variable(Object? v) {
    if (v == null) return const Variable<Object>(null);
    if (v is bool) return Variable<Object>(v ? 1 : 0);
    if (v is int || v is double) return Variable<Object>(v);
    return Variable<Object>(v.toString());
  }

  @override
  Future<List<Row>> select(String sql, [List<Object?> args = const <Object?>[]]) async {
    final List<QueryRow> rows = await _db
        .customSelect(sql, variables: args.map(_variable).toList())
        .get();
    return rows.map((QueryRow r) => r.data).toList();
  }

  @override
  Future<void> execute(String sql, [List<Object?> args = const <Object?>[]]) =>
      _db.customStatement(sql, args);

  @override
  Future<void> executeAll(List<({String sql, List<Object?> args})> statements) =>
      _db.batch((Batch b) {
        for (final ({String sql, List<Object?> args}) s in statements) {
          b.customStatement(s.sql, s.args);
        }
      });

  @override
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);
}

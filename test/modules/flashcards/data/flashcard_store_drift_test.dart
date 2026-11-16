import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/flashcards/data/drift_fc_sql.dart';
import 'package:lexiora/modules/flashcards/data/fc_sql.dart';

import 'fc_repository_suite.dart';
import 'flashcard_store_suite.dart';

/// Runs the whole data-layer suite on the app's real Drift database
/// (in-memory), exactly as the app opens it — including `beforeOpen`.
void main() {
  final List<AppDatabase> dbs = <AppDatabase>[];

  Future<FcSql> newSql() async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    dbs.add(db);
    return DriftFcSql(db);
  }

  tearDownAll(() async {
    for (final AppDatabase d in dbs) {
      await d.close();
    }
  });

  group('store on Drift', () => defineStoreTests(newSql));
  group('repository on Drift', () => defineRepositoryTests(newSql));
}

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/features/library/data/repositories/library_repository_impl.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';

/// Regression coverage for import/discovery de-duplication and the
/// managed-vs-in-place delete semantics introduced with manual import.
void main() {
  group('libraryDedupKey', () {
    test('is case-insensitive, trimmed, and size-scoped', () {
      expect(libraryDedupKey('Report', 100), 'report|100');
      expect(libraryDedupKey('  report ', 100), 'report|100');
      expect(libraryDedupKey('Report', 101), isNot(libraryDedupKey('Report', 100)));
    });
  });

  group('LibraryRepositoryImpl', () {
    late AppDatabase db;
    late LibraryRepositoryImpl repo;
    late Directory tmp;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = LibraryRepositoryImpl(db);
      tmp = Directory.systemTemp.createTempSync('sapiora_test');
    });

    tearDown(() async {
      await db.close();
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    LibraryDocument doc({
      required String id,
      required String title,
      required String path,
      required int size,
      required bool managed,
    }) =>
        LibraryDocument(
          id: id,
          title: title,
          fileName: title,
          filePath: path,
          fileSize: size,
          pageCount: 0,
          isFavorite: false,
          importedAt: DateTime.now(),
          isManaged: managed,
        );

    test('existingKeys reflects fileName|size for all documents', () async {
      await repo.insert(doc(
          id: '1', title: 'Alpha', path: '/x/Alpha.pdf', size: 10, managed: false));
      await repo.insert(doc(
          id: '2', title: 'Beta', path: '/x/Beta.pdf', size: 20, managed: true));
      final Set<String> keys = await repo.existingKeys();
      expect(keys, containsAll(<String>['alpha|10', 'beta|20']));
    });

    test('isManaged round-trips through the database', () async {
      await repo.insert(doc(
          id: '1', title: 'A', path: '/x/A.pdf', size: 1, managed: true));
      await repo.insert(doc(
          id: '2', title: 'B', path: '/x/B.pdf', size: 2, managed: false));
      expect((await repo.getById('1'))!.isManaged, isTrue);
      expect((await repo.getById('2'))!.isManaged, isFalse);
    });

    test('delete removes a managed import copy from disk', () async {
      final File f = File('${tmp.path}/managed.pdf')..writeAsStringSync('pdf');
      await repo.insert(doc(
          id: 'm', title: 'managed', path: f.path, size: 3, managed: true));

      await repo.delete('m');

      expect(await repo.getById('m'), isNull);
      expect(f.existsSync(), isFalse, reason: 'managed copy is deleted');
    });

    test('delete preserves an in-place discovered file on disk', () async {
      final File f = File('${tmp.path}/inplace.pdf')..writeAsStringSync('pdf');
      await repo.insert(doc(
          id: 'd', title: 'inplace', path: f.path, size: 3, managed: false));

      await repo.delete('d');

      expect(await repo.getById('d'), isNull);
      expect(f.existsSync(), isTrue,
          reason: "the user's own file must never be deleted");
    });
  });
}

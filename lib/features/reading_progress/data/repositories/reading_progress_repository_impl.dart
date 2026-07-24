import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/features/reading_progress/domain/entities/reading_progress.dart';
import 'package:lexiora/features/reading_progress/domain/repositories/reading_progress_repository.dart';
import 'package:uuid/uuid.dart';

class ReadingProgressRepositoryImpl implements ReadingProgressRepository {
  ReadingProgressRepositoryImpl(this._db);

  final AppDatabase _db;
  static const Uuid _uuid = Uuid();

  @override
  Stream<ReadingProgress?> watchProgress(String documentId) =>
      (_db.select(_db.readingProgress)
            ..where((t) => t.documentId.equals(documentId)))
          .watchSingleOrNull()
          .map(_mapNullable);

  @override
  Future<ReadingProgress?> getProgress(String documentId) async {
    final ReadingProgressRow? row = await (_db.select(_db.readingProgress)
          ..where((t) => t.documentId.equals(documentId)))
        .getSingleOrNull();
    return _mapNullable(row);
  }

  @override
  Future<void> saveProgress(ReadingProgress progress) async {
    await _db.into(_db.readingProgress).insertOnConflictUpdate(
          ReadingProgressCompanion.insert(
            documentId: progress.documentId,
            lastPage: Value(progress.lastPage),
            totalPages: Value(progress.totalPages),
            percent: Value(progress.percent),
            updatedAt: progress.updatedAt,
          ),
        );
  }

  @override
  Future<void> logSession(String documentId, int pageNumber) async {
    await _db.into(_db.readingSessions).insert(
          ReadingSessionsCompanion.insert(
            id: _uuid.v4(),
            documentId: documentId,
            pageNumber: pageNumber,
            openedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> deleteForDocument(String documentId) async {
    await (_db.delete(_db.readingProgress)
          ..where((t) => t.documentId.equals(documentId)))
        .go();
    await (_db.delete(_db.readingSessions)
          ..where((t) => t.documentId.equals(documentId)))
        .go();
  }

  ReadingProgress? _mapNullable(ReadingProgressRow? row) {
    if (row == null) return null;
    return ReadingProgress(
      documentId: row.documentId,
      lastPage: row.lastPage,
      totalPages: row.totalPages,
      percent: row.percent,
      updatedAt: row.updatedAt,
    );
  }
}

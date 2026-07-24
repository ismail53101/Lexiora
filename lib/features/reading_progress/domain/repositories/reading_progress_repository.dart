import 'package:lexiora/features/reading_progress/domain/entities/reading_progress.dart';

/// Domain contract for tracking reading position, progress and history.
abstract interface class ReadingProgressRepository {
  /// Reactive progress for a single document (null until first saved).
  Stream<ReadingProgress?> watchProgress(String documentId);

  Future<ReadingProgress?> getProgress(String documentId);

  /// Inserts or updates the progress row for a document.
  Future<void> saveProgress(ReadingProgress progress);

  /// Appends a reading-history entry (used to build the history list).
  Future<void> logSession(String documentId, int pageNumber);

  /// Removes all progress/history for a document (e.g. when it is deleted).
  Future<void> deleteForDocument(String documentId);
}

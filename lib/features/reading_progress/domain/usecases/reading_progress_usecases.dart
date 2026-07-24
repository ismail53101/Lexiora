import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/features/reading_progress/domain/entities/reading_progress.dart';
import 'package:lexiora/features/reading_progress/domain/repositories/reading_progress_repository.dart';

/// Streams the reading progress for a document.
class WatchReadingProgress
    implements StreamUseCase<ReadingProgress?, String> {
  const WatchReadingProgress(this._repo);
  final ReadingProgressRepository _repo;

  @override
  Stream<ReadingProgress?> call(String documentId) =>
      _repo.watchProgress(documentId);
}

/// Parameters for [SaveReadingProgress].
class SaveProgressParams {
  const SaveProgressParams({
    required this.documentId,
    required this.lastPage,
    required this.totalPages,
  });
  final String documentId;
  final int lastPage;
  final int totalPages;
}

/// Persists the current page and derives the completion percentage.
class SaveReadingProgress implements UseCase<void, SaveProgressParams> {
  const SaveReadingProgress(this._repo);
  final ReadingProgressRepository _repo;

  @override
  ResultFuture<void> call(SaveProgressParams params) => guard(() {
        final double percent = params.totalPages <= 0
            ? 0
            : (params.lastPage / params.totalPages).clamp(0.0, 1.0);
        return _repo.saveProgress(
          ReadingProgress(
            documentId: params.documentId,
            lastPage: params.lastPage,
            totalPages: params.totalPages,
            percent: percent,
            updatedAt: DateTime.now(),
          ),
        );
      });
}

/// Parameters for [LogReadingSession].
class LogSessionParams {
  const LogSessionParams({required this.documentId, required this.pageNumber});
  final String documentId;
  final int pageNumber;
}

/// Records that a document was opened (for the reading-history list).
class LogReadingSession implements UseCase<void, LogSessionParams> {
  const LogReadingSession(this._repo);
  final ReadingProgressRepository _repo;

  @override
  ResultFuture<void> call(LogSessionParams params) =>
      guard(() => _repo.logSession(params.documentId, params.pageNumber));
}

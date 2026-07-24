import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/features/reading_progress/domain/entities/reading_progress.dart';
import 'package:lexiora/features/reading_progress/domain/repositories/reading_progress_repository.dart';
import 'package:lexiora/features/reading_progress/domain/usecases/reading_progress_usecases.dart';

final Provider<ReadingProgressRepository> readingProgressRepositoryProvider =
    Provider<ReadingProgressRepository>(
  (Ref ref) => sl<ReadingProgressRepository>(),
);

/// Reactive reading progress for a given document id.
final readingProgressProvider = StreamProvider.family<ReadingProgress?, String>(
  (Ref ref, String documentId) =>
      WatchReadingProgress(ref.watch(readingProgressRepositoryProvider))
          .call(documentId),
);

/// Command helpers for saving progress and logging history.
final Provider<SaveReadingProgress> saveReadingProgressProvider =
    Provider<SaveReadingProgress>(
  (Ref ref) => SaveReadingProgress(ref.watch(readingProgressRepositoryProvider)),
);

final Provider<LogReadingSession> logReadingSessionProvider =
    Provider<LogReadingSession>(
  (Ref ref) => LogReadingSession(ref.watch(readingProgressRepositoryProvider)),
);

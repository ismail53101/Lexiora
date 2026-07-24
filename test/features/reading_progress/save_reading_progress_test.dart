import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/features/reading_progress/domain/entities/reading_progress.dart';
import 'package:lexiora/features/reading_progress/domain/repositories/reading_progress_repository.dart';
import 'package:lexiora/features/reading_progress/domain/usecases/reading_progress_usecases.dart';

class _FakeProgressRepo implements ReadingProgressRepository {
  ReadingProgress? saved;

  @override
  Future<void> saveProgress(ReadingProgress progress) async => saved = progress;

  @override
  Future<ReadingProgress?> getProgress(String documentId) async => saved;

  @override
  Future<void> deleteForDocument(String documentId) async {}

  @override
  Future<void> logSession(String documentId, int pageNumber) async {}

  @override
  Stream<ReadingProgress?> watchProgress(String documentId) =>
      const Stream<ReadingProgress?>.empty();
}

void main() {
  group('SaveReadingProgress', () {
    test('computes completion percentage from page and total', () async {
      final _FakeProgressRepo repo = _FakeProgressRepo();
      final result = await SaveReadingProgress(repo).call(
        const SaveProgressParams(documentId: 'd', lastPage: 25, totalPages: 100),
      );
      expect(result.isOk, isTrue);
      expect(repo.saved, isNotNull);
      expect(repo.saved!.lastPage, 25);
      expect(repo.saved!.percent, closeTo(0.25, 1e-9));
    });

    test('handles an unknown total page count without dividing by zero',
        () async {
      final _FakeProgressRepo repo = _FakeProgressRepo();
      await SaveReadingProgress(repo).call(
        const SaveProgressParams(documentId: 'd', lastPage: 3, totalPages: 0),
      );
      expect(repo.saved!.percent, 0.0);
    });
  });
}

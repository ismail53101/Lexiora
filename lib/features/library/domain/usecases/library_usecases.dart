import 'package:lexiora/core/services/pdf_discovery_service.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/features/annotations/domain/repositories/annotations_repository.dart';
import 'package:lexiora/features/bookmarks/domain/repositories/bookmarks_repository.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/repositories/library_repository.dart';
import 'package:lexiora/features/notes/domain/repositories/notes_repository.dart';
import 'package:lexiora/features/reading_progress/domain/repositories/reading_progress_repository.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

String _titleOf(String fileName) {
  final String base = p.basenameWithoutExtension(fileName).trim();
  return base.isEmpty ? 'Untitled document' : base;
}

/// The result of a discovery run.
class DiscoveryOutcome {
  const DiscoveryOutcome({required this.scanned, required this.added});
  final int scanned;
  final int added;
}

/// Automatically scans the whole device for PDFs (using all-files access) and
/// indexes any not already in the library, referencing each file in place (no
/// copy). Runs on library open and pull-to-refresh; new files appear on the
/// next scan. Existing entries are never removed automatically — so a transient
/// scan miss can never delete a user's highlights/notes/bookmarks. A document
/// whose file has since been deleted surfaces the reader's error page and can
/// be removed from the library by hand.
class AutoDiscoverPdfs implements UseCase<DiscoveryOutcome, NoParams> {
  const AutoDiscoverPdfs(this._repo, this._discovery);

  final LibraryRepository _repo;
  final PdfDiscoveryService _discovery;

  @override
  ResultFuture<DiscoveryOutcome> call(NoParams params) => guard(() async {
        final List<DeviceFile> found = await _discovery.scanAll();
        AppLogger.i('AutoDiscover: scanned ${found.length} PDF(s)');
        final Set<String> existing = await _repo.existingPaths();
        final DateTime now = DateTime.now();
        int added = 0;
        for (final DeviceFile f in found) {
          if (existing.contains(f.path)) continue;
          AppLogger.i('AutoDiscover: indexing ${f.path}');
          await _repo.insert(
            LibraryDocument(
              id: _uuid.v4(),
              title: _titleOf(f.name),
              fileName: _titleOf(f.name),
              filePath: f.path,
              fileSize: f.size,
              pageCount: 0, // refined the first time the document is opened
              isFavorite: false,
              importedAt: now,
            ),
          );
          existing.add(f.path);
          added++;
        }
        AppLogger.i('AutoDiscover: added $added new PDF(s)');
        return DiscoveryOutcome(scanned: found.length, added: added);
      });
}

/// Deletes a document and all of its associated data (annotations, notes,
/// bookmarks, reading progress). The underlying file is left untouched — it is
/// the user's own file, referenced in place.
class DeleteDocument implements UseCase<void, String> {
  const DeleteDocument(
    this._library,
    this._annotations,
    this._notes,
    this._bookmarks,
    this._progress,
  );

  final LibraryRepository _library;
  final AnnotationsRepository _annotations;
  final NotesRepository _notes;
  final BookmarksRepository _bookmarks;
  final ReadingProgressRepository _progress;

  @override
  ResultFuture<void> call(String documentId) => guard(() async {
        await _annotations.deleteForDocument(documentId);
        await _notes.deleteForDocument(documentId);
        await _bookmarks.deleteForDocument(documentId);
        await _progress.deleteForDocument(documentId);
        await _library.delete(documentId);
      });
}

class ToggleFavorite implements UseCase<void, String> {
  const ToggleFavorite(this._repo);
  final LibraryRepository _repo;

  @override
  ResultFuture<void> call(String id) => guard(() => _repo.toggleFavorite(id));
}

class MarkDocumentOpened implements UseCase<void, String> {
  const MarkDocumentOpened(this._repo);
  final LibraryRepository _repo;

  @override
  ResultFuture<void> call(String id) => guard(() => _repo.markOpened(id));
}

class RenameDocumentParams {
  const RenameDocumentParams(this.id, this.title);
  final String id;
  final String title;
}

class RenameDocument implements UseCase<void, RenameDocumentParams> {
  const RenameDocument(this._repo);
  final LibraryRepository _repo;

  @override
  ResultFuture<void> call(RenameDocumentParams params) =>
      guard(() => _repo.rename(params.id, params.title));
}

class AssignCategoryParams {
  const AssignCategoryParams(this.documentId, this.categoryId);
  final String documentId;
  final String? categoryId;
}

class AssignCategory implements UseCase<void, AssignCategoryParams> {
  const AssignCategory(this._repo);
  final LibraryRepository _repo;

  @override
  ResultFuture<void> call(AssignCategoryParams params) =>
      guard(() => _repo.assignCategory(params.documentId, params.categoryId));
}

class CreateCategoryParams {
  const CreateCategoryParams(this.name, this.colorValue);
  final String name;
  final int colorValue;
}

class CreateCategory implements UseCase<void, CreateCategoryParams> {
  const CreateCategory(this._repo);
  final LibraryRepository _repo;

  @override
  ResultFuture<void> call(CreateCategoryParams params) =>
      guard(() => _repo.createCategory(params.name, params.colorValue));
}

class DeleteCategory implements UseCase<void, String> {
  const DeleteCategory(this._repo);
  final LibraryRepository _repo;

  @override
  ResultFuture<void> call(String id) => guard(() => _repo.deleteCategory(id));
}

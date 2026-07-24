import 'package:lexiora/core/reader_engine/pdf_engine.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';
import 'package:lexiora/core/services/file_import_service.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/features/annotations/domain/repositories/annotations_repository.dart';
import 'package:lexiora/features/bookmarks/domain/repositories/bookmarks_repository.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/repositories/library_repository.dart';
import 'package:lexiora/features/notes/domain/repositories/notes_repository.dart';
import 'package:lexiora/features/reading_progress/domain/repositories/reading_progress_repository.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Picks a PDF, reads its page count, and adds it to the library.
///
/// Returns the created document, or `null` when the user cancels the picker.
class ImportDocument implements UseCase<LibraryDocument?, NoParams> {
  const ImportDocument(this._repo, this._importer, this._engine);

  final LibraryRepository _repo;
  final FileImportService _importer;
  final PdfEngine _engine;

  @override
  ResultFuture<LibraryDocument?> call(NoParams params) => guard(() async {
        final ImportedFile? imported = await _importer.pickAndImportPdf();
        if (imported == null) return null;

        int pageCount = 0;
        try {
          final PdfDocumentInfo info =
              await _engine.readDocumentInfo(imported.filePath);
          pageCount = info.pageCount;
        } on Object {
          // A metadata read failure must not block import; page count is
          // refined the first time the document is opened.
          pageCount = 0;
        }

        final LibraryDocument doc = LibraryDocument(
          id: _uuid.v4(),
          title: imported.displayName,
          fileName: imported.displayName,
          filePath: imported.filePath,
          fileSize: imported.fileSize,
          pageCount: pageCount,
          isFavorite: false,
          importedAt: DateTime.now(),
        );
        await _repo.insert(doc);
        return doc;
      });
}

/// Deletes a document and *all* of its associated data (annotations, notes,
/// bookmarks, reading progress) and its file. Composed from the other feature
/// repositories so cascade behavior lives in one obvious place.
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

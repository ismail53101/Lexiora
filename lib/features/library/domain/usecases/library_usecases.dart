import 'dart:io';

import 'package:lexiora/core/services/pdf_discovery_service.dart';
import 'package:lexiora/core/services/pdf_import_service.dart';
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

/// The result of a manual import run.
class ImportOutcome {
  const ImportOutcome({
    required this.picked,
    required this.added,
    required this.duplicates,
  });

  final int picked;
  final int added;
  final int duplicates;
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
        // De-dup by content key (fileName|size) so an auto-discovered file that
        // was also manually imported — or vice versa — is never duplicated.
        final Set<String> keys = await _repo.existingKeys();
        final DateTime now = DateTime.now();
        int added = 0;
        for (final DeviceFile f in found) {
          final String title = _titleOf(f.name);
          final String key = libraryDedupKey(title, f.size);
          if (keys.contains(key)) continue;
          AppLogger.i('AutoDiscover: indexing ${f.path}');
          await _repo.insert(
            LibraryDocument(
              id: _uuid.v4(),
              title: title,
              fileName: title,
              filePath: f.path,
              fileSize: f.size,
              pageCount: 0, // refined the first time the document is opened
              isFavorite: false,
              importedAt: now,
              // isManaged defaults to false: an in-place reference to the
              // user's own file, which is never auto-deleted.
            ),
          );
          keys.add(key);
          added++;
        }
        AppLogger.i('AutoDiscover: added $added new PDF(s)');
        return DiscoveryOutcome(scanned: found.length, added: added);
      });
}

/// Opens the system file picker (multi-select) and imports the chosen PDFs.
///
/// Each file is copied into the app's private storage (so it opens reliably
/// regardless of the source provider) and indexed as a managed document —
/// deleting such a document removes the copy. Files already in the library
/// (by content key) are skipped and their just-made copies discarded, so manual
/// import and automatic discovery never produce duplicates.
class ImportPdfs implements UseCase<ImportOutcome, NoParams> {
  const ImportPdfs(this._repo, this._import);

  final LibraryRepository _repo;
  final PdfImportService _import;

  @override
  ResultFuture<ImportOutcome> call(NoParams params) => guard(() async {
        final List<DeviceFile> picked = await _import.pickAndImport();
        if (picked.isEmpty) {
          return const ImportOutcome(picked: 0, added: 0, duplicates: 0);
        }
        final Set<String> keys = await _repo.existingKeys();
        final DateTime now = DateTime.now();
        int added = 0;
        int duplicates = 0;
        for (final DeviceFile f in picked) {
          final String title = _titleOf(f.name);
          final String key = libraryDedupKey(title, f.size);
          if (keys.contains(key)) {
            duplicates++;
            _discardCopy(f.path); // avoid leaving an orphaned duplicate copy
            continue;
          }
          await _repo.insert(
            LibraryDocument(
              id: _uuid.v4(),
              title: title,
              fileName: title,
              filePath: f.path,
              fileSize: f.size,
              pageCount: 0,
              isFavorite: false,
              importedAt: now,
              // App-owned copy — removed from disk when the document is deleted.
              isManaged: true,
            ),
          );
          keys.add(key);
          added++;
        }
        AppLogger.i(
          'Import: picked ${picked.length}, added $added, duplicates $duplicates',
        );
        return ImportOutcome(
          picked: picked.length,
          added: added,
          duplicates: duplicates,
        );
      });

  void _discardCopy(String path) {
    try {
      final File file = File(path);
      if (file.existsSync()) file.deleteSync();
    } on Object catch (e) {
      AppLogger.w('Import: could not discard duplicate copy $path: $e');
    }
  }
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

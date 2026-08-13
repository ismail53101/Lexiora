import 'dart:io';

import 'package:lexiora/core/services/pdf_cover_service.dart';
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
  const DiscoveryOutcome({
    required this.scanned,
    required this.added,
    this.removed = 0,
  });
  final int scanned;
  final int added;
  final int removed;
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

/// Automatically scans the whole device for PDFs and reconciles the current
/// filesystem with the library, referencing files in place without copying.
/// Runs after Home opens, on Library open, and on pull-to-refresh. Existing
/// metadata is retained for matched documents; stale or duplicate rows are
/// removed through the existing metadata-safe delete use case.
class AutoDiscoverPdfs implements UseCase<DiscoveryOutcome, NoParams> {
  const AutoDiscoverPdfs(
    this._repo,
    this._discovery,
    this._cover,
    this._deleteDocument,
  );

  final LibraryRepository _repo;
  final PdfDiscoveryService _discovery;
  final PdfCoverService _cover;
  final DeleteDocument _deleteDocument;

  @override
  ResultFuture<DiscoveryOutcome> call(NoParams params) => guard(() async {
        final List<DeviceFile> found = await _discovery.scanAll();
        final List<LibraryDocument> existing = await _repo.watchAll().first;
        AppLogger.i('AutoDiscover: scanned ${found.length} PDF(s)');

        final Map<String, List<LibraryDocument>> byPath =
            <String, List<LibraryDocument>>{};
        final Map<String, List<LibraryDocument>> byContent =
            <String, List<LibraryDocument>>{};
        for (final LibraryDocument document in existing) {
          byPath
              .putIfAbsent(_pathKey(document.filePath), () => <LibraryDocument>[])
              .add(document);
          byContent
              .putIfAbsent(
                libraryDedupKey(document.fileName, document.fileSize),
                () => <LibraryDocument>[],
              )
              .add(document);
        }

        final Set<String> matchedIds = <String>{};
        final Set<String> scannedPaths = <String>{};
        final DateTime now = DateTime.now();
        int added = 0;
        int removed = 0;

        for (final DeviceFile file in found) {
          final String pathKey = _pathKey(file.path);
          if (!scannedPaths.add(pathKey)) continue;
          final String title = _titleOf(file.name);
          final String contentKey = libraryDedupKey(title, file.size);
          LibraryDocument? match = _firstUnmatched(
            byPath[pathKey],
            matchedIds,
          );

          // A renamed or moved in-place PDF can retain its record by matching
          // the existing name/size key. Never repoint a managed private import
          // at an external file.
          match ??= _firstUnmatched(
            byContent[contentKey],
            matchedIds,
            inPlaceOnly: true,
          );

          if (match != null) {
            matchedIds.add(match.id);
            if (_pathKey(match.filePath) != pathKey) {
              await _repo.updateFilePath(match.id, file.path);
            }
            continue;
          }

          AppLogger.i('AutoDiscover: indexing ${file.path}');
          final String id = _uuid.v4();
          final String? cover = await _cover.generateCover(
            documentId: id,
            pdfPath: file.path,
          );
          await _repo.insert(
            LibraryDocument(
              id: id,
              title: title,
              fileName: title,
              filePath: file.path,
              fileSize: file.size,
              pageCount: 0,
              isFavorite: false,
              importedAt: now,
              coverPath: cover,
            ),
          );
          matchedIds.add(id);
          added++;
        }

        // Unmatched in-place rows are stale or duplicate records. Managed
        // imports remain if their private file still exists; missing managed
        // files are cleaned using the existing metadata-safe delete use case.
        for (final LibraryDocument document in existing) {
          if (matchedIds.contains(document.id)) continue;
          final bool managedFileStillExists =
              document.isManaged && File(document.filePath).existsSync();
          if (managedFileStillExists) continue;
          final Result<void> result = await _deleteDocument.call(document.id);
          result.fold(
            (failure) => AppLogger.w(
              'AutoDiscover: could not remove stale ${document.filePath}: '
              '${failure.message}',
            ),
            (_) => removed++,
          );
        }

        AppLogger.i(
          'AutoDiscover: added $added, removed $removed stale/duplicate PDF(s)',
        );
        return DiscoveryOutcome(
          scanned: scannedPaths.length,
          added: added,
          removed: removed,
        );
      });

  static LibraryDocument? _firstUnmatched(
    List<LibraryDocument>? candidates,
    Set<String> matchedIds, {
    bool inPlaceOnly = false,
  }) {
    if (candidates == null) return null;
    for (final LibraryDocument candidate in candidates) {
      if (matchedIds.contains(candidate.id)) continue;
      if (inPlaceOnly && candidate.isManaged) continue;
      return candidate;
    }
    return null;
  }

  static String _pathKey(String path) => p.normalize(path).trim();
}

/// Opens the system file picker (multi-select) and imports the chosen PDFs.
///
/// Each file is copied into the app's private storage (so it opens reliably
/// regardless of the source provider) and indexed as a managed document —
/// deleting such a document removes the copy. Files already in the library
/// (by content key) are skipped and their just-made copies discarded, so manual
/// import and automatic discovery never produce duplicates.
class ImportPdfs implements UseCase<ImportOutcome, NoParams> {
  const ImportPdfs(this._repo, this._import, this._cover);

  final LibraryRepository _repo;
  final PdfImportService _import;
  final PdfCoverService _cover;

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
          final String id = _uuid.v4();
          final String? cover =
              await _cover.generateCover(documentId: id, pdfPath: f.path);
          await _repo.insert(
            LibraryDocument(
              id: id,
              title: title,
              fileName: title,
              filePath: f.path,
              fileSize: f.size,
              pageCount: 0,
              isFavorite: false,
              importedAt: now,
              coverPath: cover,
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

/// Same import flow as [ImportPdfs], but assigns every newly-imported
/// document to [categoryId] — used by the Admin Panel to build a curated
/// PDF collection (stored as an ordinary library category, so it reuses the
/// existing, already-working document storage/rendering/reader pipeline
/// rather than needing any separate content system).
class AdminImportPdfs {
  const AdminImportPdfs(this._repo, this._import, this._cover);

  final LibraryRepository _repo;
  final PdfImportService _import;
  final PdfCoverService _cover;

  ResultFuture<ImportOutcome> call(String categoryId) => guard(() async {
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
            _discardCopy(f.path);
            continue;
          }
          final String id = _uuid.v4();
          final String? cover =
              await _cover.generateCover(documentId: id, pdfPath: f.path);
          await _repo.insert(
            LibraryDocument(
              id: id,
              title: title,
              fileName: title,
              filePath: f.path,
              fileSize: f.size,
              pageCount: 0,
              isFavorite: false,
              importedAt: now,
              coverPath: cover,
              categoryId: categoryId,
              isManaged: true,
            ),
          );
          keys.add(key);
          added++;
        }
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
      AppLogger.w('AdminImport: could not discard duplicate copy $path: $e');
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
    this._cover,
  );

  final LibraryRepository _library;
  final AnnotationsRepository _annotations;
  final NotesRepository _notes;
  final BookmarksRepository _bookmarks;
  final ReadingProgressRepository _progress;
  final PdfCoverService _cover;

  @override
  ResultFuture<void> call(String documentId) => guard(() async {
        final LibraryDocument? doc = await _library.getById(documentId);
        await _annotations.deleteForDocument(documentId);
        await _notes.deleteForDocument(documentId);
        await _bookmarks.deleteForDocument(documentId);
        await _progress.deleteForDocument(documentId);
        await _library.delete(documentId);
        await _cover.deleteCover(doc?.coverPath);
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

/// Generates a first-page thumbnail for every library document that doesn't
/// have one yet — specifically, documents imported/discovered *before* the
/// cover-thumbnail feature existed, which otherwise show the gradient+
/// initials placeholder forever. New documents already get a cover at
/// import/discovery time; this only ever needs to touch each older document
/// once, since [LibraryRepository.updateCoverPath] persists the result.
///
/// One failed cover (corrupt file, moved/missing PDF, ...) is skipped and
/// never stops the rest of the backfill.
class BackfillCovers implements UseCase<int, NoParams> {
  const BackfillCovers(this._repo, this._cover);

  final LibraryRepository _repo;
  final PdfCoverService _cover;

  @override
  ResultFuture<int> call(NoParams params) => guard(() async {
        final List<LibraryDocument> all = await _repo.watchAll().first;
        int updated = 0;
        for (final LibraryDocument doc in all) {
          final String? existing = doc.coverPath;
          if (existing != null && existing.isNotEmpty) continue;
          final String? cover = await _cover.generateCover(
            documentId: doc.id,
            pdfPath: doc.filePath,
          );
          if (cover == null) continue;
          await _repo.updateCoverPath(doc.id, cover);
          updated++;
        }
        if (updated > 0) {
          AppLogger.i('BackfillCovers: generated $updated cover(s)');
        }
        return updated;
      });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/pdf_cover_service.dart';
import 'package:lexiora/core/services/pdf_discovery_service.dart';
import 'package:lexiora/core/services/pdf_import_service.dart';
import 'package:lexiora/core/services/permission_service.dart';
import 'package:lexiora/features/annotations/domain/repositories/annotations_repository.dart';
import 'package:lexiora/features/bookmarks/domain/repositories/bookmarks_repository.dart';
import 'package:lexiora/features/library/domain/entities/category.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/repositories/library_repository.dart';
import 'package:lexiora/features/library/domain/usecases/library_usecases.dart';
import 'package:lexiora/features/notes/domain/repositories/notes_repository.dart';
import 'package:lexiora/features/reading_progress/domain/repositories/reading_progress_repository.dart';

final Provider<LibraryRepository> libraryRepositoryProvider =
    Provider<LibraryRepository>((Ref ref) => sl<LibraryRepository>());

// ── Reactive queries ────────────────────────────────────────────────────────

final StreamProvider<List<LibraryDocument>> allDocumentsProvider =
    StreamProvider<List<LibraryDocument>>(
  (Ref ref) => ref.watch(libraryRepositoryProvider).watchAll(),
);

final StreamProvider<List<LibraryDocument>> recentDocumentsProvider =
    StreamProvider<List<LibraryDocument>>(
  (Ref ref) => ref.watch(libraryRepositoryProvider).watchRecent(limit: 12),
);

final StreamProvider<List<LibraryDocument>> favoriteDocumentsProvider =
    StreamProvider<List<LibraryDocument>>(
  (Ref ref) => ref.watch(libraryRepositoryProvider).watchFavorites(),
);

final StreamProvider<List<LibraryEntry>> continueReadingProvider =
    StreamProvider<List<LibraryEntry>>(
  (Ref ref) =>
      ref.watch(libraryRepositoryProvider).watchContinueReading(limit: 12),
);

final StreamProvider<List<Category>> categoriesProvider =
    StreamProvider<List<Category>>(
  (Ref ref) => ref.watch(libraryRepositoryProvider).watchCategories(),
);

final documentsByCategoryProvider =
    StreamProvider.family<List<LibraryDocument>, String>(
  (Ref ref, String categoryId) =>
      ref.watch(libraryRepositoryProvider).watchByCategory(categoryId),
);

final documentByIdProvider = FutureProvider.family<LibraryDocument?, String>(
  (Ref ref, String id) => ref.watch(libraryRepositoryProvider).getById(id),
);

// ── Commands (use cases) ─────────────────────────────────────────────────────

/// Automatically indexes every PDF on the device, referencing files in place.
final Provider<AutoDiscoverPdfs> autoDiscoverProvider =
    Provider<AutoDiscoverPdfs>(
  (Ref ref) => AutoDiscoverPdfs(
    ref.watch(libraryRepositoryProvider),
    sl<PdfDiscoveryService>(),
    sl<PdfCoverService>(),
    ref.watch(deleteDocumentProvider),
  ),
);

/// Manually imports PDFs chosen from the system file picker (multi-select).
final Provider<ImportPdfs> importPdfsProvider = Provider<ImportPdfs>(
  (Ref ref) => ImportPdfs(
    ref.watch(libraryRepositoryProvider),
    sl<PdfImportService>(),
    sl<PdfCoverService>(),
  ),
);

/// Imports PDFs directly into a chosen category — used by the Admin Panel.
final Provider<AdminImportPdfs> adminImportPdfsProvider =
    Provider<AdminImportPdfs>(
  (Ref ref) => AdminImportPdfs(
    ref.watch(libraryRepositoryProvider),
    sl<PdfImportService>(),
    sl<PdfCoverService>(),
  ),
);

final Provider<PermissionService> permissionServiceProvider =
    Provider<PermissionService>((Ref ref) => sl<PermissionService>());

final Provider<DeleteDocument> deleteDocumentProvider = Provider<DeleteDocument>(
  (Ref ref) => DeleteDocument(
    ref.watch(libraryRepositoryProvider),
    sl<AnnotationsRepository>(),
    sl<NotesRepository>(),
    sl<BookmarksRepository>(),
    sl<ReadingProgressRepository>(),
    sl<PdfCoverService>(),
  ),
);

final Provider<ToggleFavorite> toggleFavoriteProvider = Provider<ToggleFavorite>(
  (Ref ref) => ToggleFavorite(ref.watch(libraryRepositoryProvider)),
);

final Provider<MarkDocumentOpened> markDocumentOpenedProvider =
    Provider<MarkDocumentOpened>(
  (Ref ref) => MarkDocumentOpened(ref.watch(libraryRepositoryProvider)),
);

final Provider<RenameDocument> renameDocumentProvider =
    Provider<RenameDocument>(
  (Ref ref) => RenameDocument(ref.watch(libraryRepositoryProvider)),
);

final Provider<AssignCategory> assignCategoryProvider = Provider<AssignCategory>(
  (Ref ref) => AssignCategory(ref.watch(libraryRepositoryProvider)),
);

final Provider<CreateCategory> createCategoryProvider = Provider<CreateCategory>(
  (Ref ref) => CreateCategory(ref.watch(libraryRepositoryProvider)),
);

final Provider<DeleteCategory> deleteCategoryProvider = Provider<DeleteCategory>(
  (Ref ref) => DeleteCategory(ref.watch(libraryRepositoryProvider)),
);

/// One-off pass that generates thumbnails for documents that predate the
/// cover-thumbnail feature. Triggered once, quietly, when the library page
/// first opens (see [LibraryPage.initState]).
final Provider<BackfillCovers> backfillCoversProvider =
    Provider<BackfillCovers>(
  (Ref ref) => BackfillCovers(
    ref.watch(libraryRepositoryProvider),
    sl<PdfCoverService>(),
  ),
);

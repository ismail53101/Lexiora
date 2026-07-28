import 'package:lexiora/features/library/domain/entities/category.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';

/// Domain contract for the document library and categories.
abstract interface class LibraryRepository {
  Stream<List<LibraryDocument>> watchAll();
  Stream<List<LibraryDocument>> watchRecent({int limit});
  Stream<List<LibraryDocument>> watchFavorites();
  Stream<List<LibraryEntry>> watchContinueReading({int limit});
  Stream<List<LibraryDocument>> watchByCategory(String categoryId);

  Future<LibraryDocument?> getById(String id);

  /// Returns the set of content de-dup keys (`fileName|fileSize`, lowercased)
  /// for every document. Shared by automatic discovery and manual import so a
  /// file that is already in the library — however it got there — is never
  /// added twice. Based on the immutable [LibraryDocument.fileName], so renaming
  /// a document never breaks de-duplication.
  Future<Set<String>> existingKeys();

  Future<void> insert(LibraryDocument document);
  Future<void> toggleFavorite(String id);
  Future<void> rename(String id, String title);

  /// Repoints [id] at a different file on disk, keeping every other field
  /// (title, cover, favourite, category, ...) unchanged. Used after OCR
  /// produces a searchable copy of a scanned document — the copy becomes the
  /// document's file going forward; the original on-device file is untouched.
  Future<void> updateFilePath(String id, String filePath);

  /// Sets [id]'s generated cover thumbnail path. Used both right after import
  /// and to backfill covers for documents that predate the thumbnail feature.
  Future<void> updateCoverPath(String id, String coverPath);
  Future<void> assignCategory(String id, String? categoryId);
  Future<void> markOpened(String id);

  /// Removes the document from the library. If the document's file is an
  /// app-managed import copy it is also deleted from disk; in-place
  /// auto-discovered files (the user's own) are left on the device.
  Future<void> delete(String id);

  Stream<List<Category>> watchCategories();
  Future<void> createCategory(String name, int colorValue);
  Future<void> deleteCategory(String id);
}

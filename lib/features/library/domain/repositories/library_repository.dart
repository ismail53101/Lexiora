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
  Future<void> insert(LibraryDocument document);
  Future<void> toggleFavorite(String id);
  Future<void> rename(String id, String title);
  Future<void> assignCategory(String id, String? categoryId);
  Future<void> markOpened(String id);

  /// Deletes the document row and its file from disk.
  Future<void> delete(String id);

  Stream<List<Category>> watchCategories();
  Future<void> createCategory(String name, int colorValue);
  Future<void> deleteCategory(String id);
}

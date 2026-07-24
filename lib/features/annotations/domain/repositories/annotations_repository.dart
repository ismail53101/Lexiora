import 'package:lexiora/features/annotations/domain/entities/highlight.dart';

/// Domain contract for highlight/underline persistence.
abstract interface class AnnotationsRepository {
  /// All annotations for a document, ordered by page then creation time.
  Stream<List<Highlight>> watchForDocument(String documentId);

  /// Annotations on a single page (used to paint reader overlays efficiently).
  Stream<List<Highlight>> watchForPage(String documentId, int pageNumber);

  Future<void> add(Highlight highlight);
  Future<void> update(Highlight highlight);
  Future<void> updateColor(String id, int colorValue);
  Future<void> updateType(String id, AnnotationType type);
  Future<void> delete(String id);
  Future<void> deleteForDocument(String documentId);
  Future<int> countForDocument(String documentId);
}

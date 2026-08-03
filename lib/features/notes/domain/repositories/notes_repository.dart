import 'package:lexiora/features/notes/domain/entities/note.dart';

/// Domain contract for note persistence.
abstract interface class NotesRepository {
  /// All notes for a document, most recently updated first.
  Stream<List<Note>> watchForDocument(String documentId);

  /// Every note across every document, most recently updated first — powers
  /// the standalone Notes tab.
  Stream<List<Note>> watchAll();

  Future<void> add(Note note);
  Future<void> update(Note note);
  Future<void> delete(String id);
  Future<void> deleteForDocument(String documentId);
  Future<int> countForDocument(String documentId);
}

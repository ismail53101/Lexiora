import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/features/notes/domain/entities/note.dart';
import 'package:lexiora/features/notes/domain/repositories/notes_repository.dart';

class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Note>> watchForDocument(String documentId) {
    final query = _db.select(_db.notes)
      ..where((t) => t.documentId.equals(documentId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
          (List<NoteRow> rows) => rows.map(_mapRow).toList(growable: false),
        );
  }

  @override
  Stream<List<Note>> watchAll() {
    final query = _db.select(_db.notes)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
          (List<NoteRow> rows) => rows.map(_mapRow).toList(growable: false),
        );
  }

  @override
  Future<void> add(Note note) async {
    await _db.into(_db.notes).insert(
          NotesCompanion.insert(
            id: note.id,
            documentId: note.documentId,
            pageNumber: note.pageNumber,
            content: note.content,
            rects: note.rects,
            createdAt: note.createdAt,
            updatedAt: note.updatedAt,
            anchorType: Value(note.anchor.index),
            selectedText: Value(note.selectedText),
          ),
        );
  }

  @override
  Future<void> update(Note note) async {
    await (_db.update(_db.notes)..where((t) => t.id.equals(note.id))).write(
      NotesCompanion(
        content: Value(note.content),
        updatedAt: Value(note.updatedAt),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> deleteForDocument(String documentId) async {
    await (_db.delete(_db.notes)..where((t) => t.documentId.equals(documentId)))
        .go();
  }

  @override
  Future<int> countForDocument(String documentId) async {
    final rows = await (_db.select(_db.notes)
          ..where((t) => t.documentId.equals(documentId)))
        .get();
    return rows.length;
  }

  Note _mapRow(NoteRow r) => Note(
        id: r.id,
        documentId: r.documentId,
        pageNumber: r.pageNumber,
        content: r.content,
        anchor: NoteAnchor
            .values[r.anchorType.clamp(0, NoteAnchor.values.length - 1)],
        selectedText: r.selectedText,
        rects: r.rects,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );
}

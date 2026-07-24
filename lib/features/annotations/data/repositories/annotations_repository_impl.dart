import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/features/annotations/domain/entities/highlight.dart';
import 'package:lexiora/features/annotations/domain/repositories/annotations_repository.dart';

class AnnotationsRepositoryImpl implements AnnotationsRepository {
  AnnotationsRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Highlight>> watchForDocument(String documentId) {
    final query = _db.select(_db.highlights)
      ..where((t) => t.documentId.equals(documentId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.pageNumber),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return query.watch().map(_mapRows);
  }

  @override
  Stream<List<Highlight>> watchForPage(String documentId, int pageNumber) {
    final query = _db.select(_db.highlights)
      ..where((t) =>
          t.documentId.equals(documentId) & t.pageNumber.equals(pageNumber));
    return query.watch().map(_mapRows);
  }

  @override
  Future<void> add(Highlight h) async {
    await _db.into(_db.highlights).insert(
          HighlightsCompanion.insert(
            id: h.id,
            documentId: h.documentId,
            pageNumber: h.pageNumber,
            colorValue: h.colorValue,
            rects: h.rects,
            createdAt: h.createdAt,
            updatedAt: h.updatedAt,
            type: Value(h.type.index),
            selectedText: Value(h.selectedText),
          ),
        );
  }

  @override
  Future<void> update(Highlight h) async {
    await (_db.update(_db.highlights)..where((t) => t.id.equals(h.id))).write(
      HighlightsCompanion(
        type: Value(h.type.index),
        colorValue: Value(h.colorValue),
        selectedText: Value(h.selectedText),
        rects: Value(h.rects),
        updatedAt: Value(h.updatedAt),
      ),
    );
  }

  @override
  Future<void> updateColor(String id, int colorValue) async {
    await (_db.update(_db.highlights)..where((t) => t.id.equals(id))).write(
      HighlightsCompanion(
        colorValue: Value(colorValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> updateType(String id, AnnotationType type) async {
    await (_db.update(_db.highlights)..where((t) => t.id.equals(id))).write(
      HighlightsCompanion(
        type: Value(type.index),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.highlights)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> deleteForDocument(String documentId) async {
    await (_db.delete(_db.highlights)
          ..where((t) => t.documentId.equals(documentId)))
        .go();
  }

  @override
  Future<int> countForDocument(String documentId) async {
    final rows = await (_db.select(_db.highlights)
          ..where((t) => t.documentId.equals(documentId)))
        .get();
    return rows.length;
  }

  List<Highlight> _mapRows(List<HighlightRow> rows) =>
      rows.map(_mapRow).toList(growable: false);

  Highlight _mapRow(HighlightRow r) => Highlight(
        id: r.id,
        documentId: r.documentId,
        pageNumber: r.pageNumber,
        type: AnnotationType
            .values[r.type.clamp(0, AnnotationType.values.length - 1)],
        colorValue: r.colorValue,
        selectedText: r.selectedText,
        rects: r.rects,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );
}

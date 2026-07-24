import 'package:lexiora/core/reader_engine/reader_models.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/features/annotations/domain/entities/highlight.dart';
import 'package:lexiora/features/annotations/domain/repositories/annotations_repository.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Streams all annotations for a document.
class WatchHighlights implements StreamUseCase<List<Highlight>, String> {
  const WatchHighlights(this._repo);
  final AnnotationsRepository _repo;

  @override
  Stream<List<Highlight>> call(String documentId) =>
      _repo.watchForDocument(documentId);
}

/// Parameters identifying a single page within a document.
class PageRef {
  const PageRef(this.documentId, this.pageNumber);
  final String documentId;
  final int pageNumber;
}

/// Streams annotations for one page.
class WatchHighlightsForPage
    implements StreamUseCase<List<Highlight>, PageRef> {
  const WatchHighlightsForPage(this._repo);
  final AnnotationsRepository _repo;

  @override
  Stream<List<Highlight>> call(PageRef ref) =>
      _repo.watchForPage(ref.documentId, ref.pageNumber);
}

/// Parameters for [AddHighlightFromSelection].
class AddHighlightParams {
  const AddHighlightParams({
    required this.documentId,
    required this.selection,
    required this.colorValue,
    required this.type,
  });
  final String documentId;
  final PdfTextSelectionData selection;
  final int colorValue;
  final AnnotationType type;
}

/// Creates a highlight/underline from a text selection. A selection spanning
/// multiple pages produces one annotation per page.
class AddHighlightFromSelection implements UseCase<void, AddHighlightParams> {
  const AddHighlightFromSelection(this._repo);
  final AnnotationsRepository _repo;

  @override
  ResultFuture<void> call(AddHighlightParams params) => guard(() async {
        final DateTime now = DateTime.now();
        for (final PdfPageSelection page in params.selection.pages) {
          if (page.rects.isEmpty) continue;
          await _repo.add(
            Highlight(
              id: _uuid.v4(),
              documentId: params.documentId,
              pageNumber: page.pageNumber,
              type: params.type,
              colorValue: params.colorValue,
              selectedText: page.text,
              rects: page.rects,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      });
}

/// Parameters for [ChangeHighlightColor].
class ChangeColorParams {
  const ChangeColorParams(this.id, this.colorValue);
  final String id;
  final int colorValue;
}

class ChangeHighlightColor implements UseCase<void, ChangeColorParams> {
  const ChangeHighlightColor(this._repo);
  final AnnotationsRepository _repo;

  @override
  ResultFuture<void> call(ChangeColorParams params) =>
      guard(() => _repo.updateColor(params.id, params.colorValue));
}

/// Parameters for [ChangeHighlightStyle].
class ChangeStyleParams {
  const ChangeStyleParams(this.id, this.type);
  final String id;
  final AnnotationType type;
}

class ChangeHighlightStyle implements UseCase<void, ChangeStyleParams> {
  const ChangeHighlightStyle(this._repo);
  final AnnotationsRepository _repo;

  @override
  ResultFuture<void> call(ChangeStyleParams params) =>
      guard(() => _repo.updateType(params.id, params.type));
}

class DeleteHighlight implements UseCase<void, String> {
  const DeleteHighlight(this._repo);
  final AnnotationsRepository _repo;

  @override
  ResultFuture<void> call(String id) => guard(() => _repo.delete(id));
}

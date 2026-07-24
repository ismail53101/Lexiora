import 'package:lexiora/core/models/normalized_rect.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/features/notes/domain/entities/note.dart';
import 'package:lexiora/features/notes/domain/repositories/notes_repository.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Streams all notes for a document.
class WatchNotes implements StreamUseCase<List<Note>, String> {
  const WatchNotes(this._repo);
  final NotesRepository _repo;

  @override
  Stream<List<Note>> call(String documentId) =>
      _repo.watchForDocument(documentId);
}

/// Parameters for [AddNote].
class AddNoteParams {
  const AddNoteParams({
    required this.documentId,
    required this.pageNumber,
    required this.content,
    this.anchor = NoteAnchor.page,
    this.selectedText,
    this.rects = const <NormalizedRect>[],
  });

  final String documentId;
  final int pageNumber;
  final String content;
  final NoteAnchor anchor;
  final String? selectedText;
  final List<NormalizedRect> rects;
}

class AddNote implements UseCase<void, AddNoteParams> {
  const AddNote(this._repo);
  final NotesRepository _repo;

  @override
  ResultFuture<void> call(AddNoteParams params) => guard(() {
        final DateTime now = DateTime.now();
        return _repo.add(
          Note(
            id: _uuid.v4(),
            documentId: params.documentId,
            pageNumber: params.pageNumber,
            content: params.content,
            anchor: params.anchor,
            selectedText: params.selectedText,
            rects: params.rects,
            createdAt: now,
            updatedAt: now,
          ),
        );
      });
}

/// Parameters for [UpdateNoteContent].
class UpdateNoteParams {
  const UpdateNoteParams(this.note, this.content);
  final Note note;
  final String content;
}

class UpdateNoteContent implements UseCase<void, UpdateNoteParams> {
  const UpdateNoteContent(this._repo);
  final NotesRepository _repo;

  @override
  ResultFuture<void> call(UpdateNoteParams params) => guard(
        () => _repo.update(
          params.note.copyWith(
            content: params.content,
            updatedAt: DateTime.now(),
          ),
        ),
      );
}

class DeleteNote implements UseCase<void, String> {
  const DeleteNote(this._repo);
  final NotesRepository _repo;

  @override
  ResultFuture<void> call(String id) => guard(() => _repo.delete(id));
}

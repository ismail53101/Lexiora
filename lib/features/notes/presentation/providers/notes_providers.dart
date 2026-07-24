import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/features/notes/domain/entities/note.dart';
import 'package:lexiora/features/notes/domain/repositories/notes_repository.dart';
import 'package:lexiora/features/notes/domain/usecases/notes_usecases.dart';

final Provider<NotesRepository> notesRepositoryProvider =
    Provider<NotesRepository>((Ref ref) => sl<NotesRepository>());

final notesForDocumentProvider = StreamProvider.family<List<Note>, String>(
  (Ref ref, String documentId) =>
      WatchNotes(ref.watch(notesRepositoryProvider)).call(documentId),
);

final Provider<AddNote> addNoteProvider = Provider<AddNote>(
  (Ref ref) => AddNote(ref.watch(notesRepositoryProvider)),
);

final Provider<UpdateNoteContent> updateNoteProvider =
    Provider<UpdateNoteContent>(
  (Ref ref) => UpdateNoteContent(ref.watch(notesRepositoryProvider)),
);

final Provider<DeleteNote> deleteNoteProvider = Provider<DeleteNote>(
  (Ref ref) => DeleteNote(ref.watch(notesRepositoryProvider)),
);

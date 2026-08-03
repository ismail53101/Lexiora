import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/app_bottom_nav.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/features/notes/domain/entities/note.dart';
import 'package:lexiora/features/notes/presentation/providers/notes_providers.dart';

/// Every note the user has written, across every document — the Notes tab.
/// Individual notes are still created/edited from inside the reader; this is
/// the read/browse/jump-back-in view over all of them at once.
class AllNotesPage extends ConsumerWidget {
  const AllNotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<Note>> notesAsync = ref.watch(allNotesProvider);
    final AsyncValue<List<LibraryDocument>> docsAsync =
        ref.watch(allDocumentsProvider);

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      appBar: AppBar(title: const Text('Notes')),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) =>
            Center(child: Text('Could not load notes: $e')),
        data: (List<Note> notes) {
          if (notes.isEmpty) {
            return const EmptyState(
              icon: Icons.sticky_note_2_outlined,
              title: 'No notes yet',
              message: 'Open a document in your Library and add a note to '
                  'a page or a selection — it shows up here.',
            );
          }
          final Map<String, String> titleById = <String, String>{
            for (final LibraryDocument d
                in docsAsync.valueOrDefault(const <LibraryDocument>[]))
              d.id: d.title,
          };
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int i) {
              final Note note = notes[i];
              final String docTitle =
                  titleById[note.documentId] ?? 'Untitled document';
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.sticky_note_2_outlined, size: 20),
                  ),
                  title: Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '$docTitle · Page ${note.pageNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () =>
                      context.push(AppRoutes.reader(note.documentId)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final StreamProvider<List<Note>> allNotesProvider = StreamProvider<List<Note>>(
    (Ref ref) => ref.watch(notesRepositoryProvider).watchAll());

extension on AsyncValue<List<LibraryDocument>> {
  List<LibraryDocument> valueOrDefault(List<LibraryDocument> fallback) =>
      when(
        data: (List<LibraryDocument> d) => d,
        loading: () => fallback,
        error: (Object _, StackTrace _) => fallback,
      );
}

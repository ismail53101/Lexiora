import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/reader_engine/pdf_reader_controller.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/features/annotations/domain/entities/highlight.dart';
import 'package:lexiora/features/annotations/presentation/providers/annotations_providers.dart';
import 'package:lexiora/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lexiora/features/bookmarks/presentation/providers/bookmarks_providers.dart';
import 'package:lexiora/features/notes/domain/entities/note.dart';
import 'package:lexiora/features/notes/domain/usecases/notes_usecases.dart';
import 'package:lexiora/features/notes/presentation/providers/notes_providers.dart';

/// Shows the reader's Bookmarks / Notes / Highlights panels in a bottom sheet.
Future<void> showReaderPanels(
  BuildContext context, {
  required String documentId,
  required PdfReaderController controller,
  int initialTab = 0,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => FractionallySizedBox(
      heightFactor: 0.7,
      child: _ReaderPanels(
        documentId: documentId,
        controller: controller,
        initialTab: initialTab,
      ),
    ),
  );
}

class _ReaderPanels extends ConsumerWidget {
  const _ReaderPanels({
    required this.documentId,
    required this.controller,
    required this.initialTab,
  });

  final String documentId;
  final PdfReaderController controller;
  final int initialTab;

  void _goTo(BuildContext context, int page) {
    Navigator.of(context).pop();
    controller.goToPage(page);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Bookmarks'),
              Tab(text: 'Notes'),
              Tab(text: 'Highlights'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _BookmarksTab(
                  documentId: documentId,
                  onOpen: (int p) => _goTo(context, p),
                ),
                _NotesTab(
                  documentId: documentId,
                  onOpen: (int p) => _goTo(context, p),
                ),
                _HighlightsTab(
                  documentId: documentId,
                  onOpen: (int p) => _goTo(context, p),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarksTab extends ConsumerWidget {
  const _BookmarksTab({required this.documentId, required this.onOpen});

  final String documentId;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Bookmark>> async =
        ref.watch(bookmarksForDocumentProvider(documentId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, _) => Center(child: Text('Error: $e')),
      data: (List<Bookmark> items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.bookmark_border,
            title: 'No bookmarks yet',
            message: 'Bookmark a page from the reader to see it here.',
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (BuildContext context, int i) {
            final Bookmark b = items[i];
            return ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text('Page ${b.pageNumber}'),
              subtitle: b.label == null ? null : Text(
                b.label!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    ref.read(deleteBookmarkProvider).call(b.id),
              ),
              onTap: () => onOpen(b.pageNumber),
            );
          },
        );
      },
    );
  }
}

class _NotesTab extends ConsumerWidget {
  const _NotesTab({required this.documentId, required this.onOpen});

  final String documentId;
  final ValueChanged<int> onOpen;

  Future<void> _edit(BuildContext context, WidgetRef ref, Note note) async {
    final TextEditingController c = TextEditingController(text: note.content);
    final String? text = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Edit note'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: 5,
          minLines: 1,
          decoration: const InputDecoration(hintText: 'Note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(c.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    if (text != null && text.isNotEmpty) {
      await ref.read(updateNoteProvider).call(UpdateNoteParams(note, text));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Note>> async =
        ref.watch(notesForDocumentProvider(documentId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, _) => Center(child: Text('Error: $e')),
      data: (List<Note> items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.sticky_note_2_outlined,
            title: 'No notes yet',
            message: 'Add a note to a page or a selection while reading.',
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (BuildContext context, int i) {
            final Note n = items[i];
            return ListTile(
              leading: Icon(
                n.isSelectionAnchored
                    ? Icons.format_quote
                    : Icons.description_outlined,
              ),
              title: Text(n.content, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                n.isSelectionAnchored && n.selectedText != null
                    ? 'Page ${n.pageNumber} · "${n.selectedText}"'
                    : 'Page ${n.pageNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(context, ref, n),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(deleteNoteProvider).call(n.id),
                  ),
                ],
              ),
              onTap: () => onOpen(n.pageNumber),
            );
          },
        );
      },
    );
  }
}

class _HighlightsTab extends ConsumerWidget {
  const _HighlightsTab({required this.documentId, required this.onOpen});

  final String documentId;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Highlight>> async =
        ref.watch(highlightsForDocumentProvider(documentId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, _) => Center(child: Text('Error: $e')),
      data: (List<Highlight> items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.highlight_alt_outlined,
            title: 'No highlights yet',
            message: 'Select text while reading to highlight or underline it.',
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (BuildContext context, int i) {
            final Highlight h = items[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(h.colorValue),
                radius: 12,
                child: Icon(
                  h.type == AnnotationType.underline
                      ? Icons.format_underlined
                      : Icons.highlight,
                  size: 14,
                  color: Colors.black54,
                ),
              ),
              title: Text(
                h.selectedText.isEmpty ? 'Highlight' : h.selectedText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Page ${h.pageNumber}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(deleteHighlightProvider).call(h.id),
              ),
              onTap: () => onOpen(h.pageNumber),
            );
          },
        );
      },
    );
  }
}

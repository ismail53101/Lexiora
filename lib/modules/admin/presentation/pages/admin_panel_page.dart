import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/features/library/presentation/widgets/document_card.dart';
import 'package:lexiora/modules/admin/domain/entities/admin_link.dart';
import 'package:lexiora/modules/admin/domain/entities/admin_note.dart';
import 'package:lexiora/modules/admin/presentation/providers/admin_providers.dart';
import 'package:uuid/uuid.dart';

/// Back-office content curation: PDFs, links and notes added here are
/// visible to every user of the app (PDFs appear filed under the "Admin"
/// library category; links/notes are for future presentation elsewhere).
/// No Home tile — reached only via Settings, matching an internal tool.
class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'PDFs', icon: Icon(Icons.picture_as_pdf_outlined)),
              Tab(text: 'Links', icon: Icon(Icons.link)),
              Tab(text: 'Notes', icon: Icon(Icons.note_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _AdminPdfsTab(),
            _AdminLinksTab(),
            _AdminNotesTab(),
          ],
        ),
      ),
    );
  }
}

// ── PDFs ─────────────────────────────────────────────────────────────────────

class _AdminPdfsTab extends ConsumerWidget {
  const _AdminPdfsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String> categoryId = ref.watch(adminCategoryIdProvider);

    return categoryId.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace _) =>
          Center(child: Text('Could not set up the Admin category: $e')),
      data: (String catId) => Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _import(context, ref, catId),
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Add PDF'),
        ),
        body: StreamBuilder<List<LibraryDocument>>(
          stream: ref.watch(libraryRepositoryProvider).watchByCategory(catId),
          builder: (BuildContext context,
              AsyncSnapshot<List<LibraryDocument>> snapshot) {
            final List<LibraryDocument> docs = snapshot.data ?? const [];
            if (docs.isEmpty) {
              return const EmptyState(
                icon: Icons.picture_as_pdf_outlined,
                title: 'No admin PDFs yet',
                message:
                    'PDFs added here appear in every user\'s library, filed '
                    'under "Admin".',
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: docs.length,
              itemBuilder: (BuildContext context, int i) => DocumentCard(
                document: docs[i],
                onOpen: () => context.push(AppRoutes.reader(docs[i].id)),
                onAction: (DocumentCardAction action) =>
                    _handleDocAction(ref, docs[i], action),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _import(
      BuildContext context, WidgetRef ref, String categoryId) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final result =
        await ref.read(adminImportPdfsProvider).call(categoryId);
    result.fold(
      (failure) => messenger.showSnackBar(
          SnackBar(content: Text('Import failed: ${failure.message}'))),
      (outcome) => messenger.showSnackBar(
        SnackBar(content: Text('Added ${outcome.added} PDF(s).')),
      ),
    );
  }

  Future<void> _handleDocAction(
      WidgetRef ref, LibraryDocument doc, DocumentCardAction action) async {
    switch (action) {
      case DocumentCardAction.favorite:
        await ref.read(toggleFavoriteProvider).call(doc.id);
      case DocumentCardAction.delete:
        await ref.read(deleteDocumentProvider).call(doc.id);
      case DocumentCardAction.rename:
        break; // Renaming isn't exposed from the Admin Panel yet.
    }
  }
}

// ── Links ────────────────────────────────────────────────────────────────────

class _AdminLinksTab extends ConsumerWidget {
  const _AdminLinksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AdminLink>> links = ref.watch(adminLinksProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editLink(context, ref, null),
        icon: const Icon(Icons.add_link),
        label: const Text('Add Link'),
      ),
      body: links.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Error: $e')),
        data: (List<AdminLink> items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.link,
              title: 'No links yet',
              message: 'Curated links (reference articles, past-paper '
                  'sites, ...) added here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int i) {
              final AdminLink link = items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(link.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    link.note?.isNotEmpty == true
                        ? '${link.url}\n${link.note}'
                        : link.url,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: link.note?.isNotEmpty == true,
                  onTap: () => _editLink(context, ref, link),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref
                          .read(adminContentServiceProvider)
                          .deleteLink(link.id);
                      ref.invalidate(adminLinksProvider);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editLink(
      BuildContext context, WidgetRef ref, AdminLink? existing) async {
    final TextEditingController title =
        TextEditingController(text: existing?.title ?? '');
    final TextEditingController url =
        TextEditingController(text: existing?.url ?? '');
    final TextEditingController note =
        TextEditingController(text: existing?.note ?? '');

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add Link' : 'Edit Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            TextField(
              controller: url,
              decoration: const InputDecoration(labelText: 'URL'),
              keyboardType: TextInputType.url,
            ),
            TextField(
              controller: note,
              decoration:
                  const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save != true) return;
    if (title.text.trim().isEmpty || url.text.trim().isEmpty) return;

    await ref.read(adminContentServiceProvider).saveLink(
          AdminLink(
            id: existing?.id ?? const Uuid().v4(),
            title: title.text.trim(),
            url: url.text.trim(),
            note: note.text.trim().isEmpty ? null : note.text.trim(),
            createdAt: existing?.createdAt ?? DateTime.now(),
          ),
        );
    ref.invalidate(adminLinksProvider);
  }
}

// ── Notes ────────────────────────────────────────────────────────────────────

class _AdminNotesTab extends ConsumerWidget {
  const _AdminNotesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AdminNote>> notes = ref.watch(adminNotesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editNote(context, ref, null),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Add Note'),
      ),
      body: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Error: $e')),
        data: (List<AdminNote> items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.note_outlined,
              title: 'No notes yet',
              message: 'Standalone notes (announcements, reminders, '
                  'curation notes, ...) added here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int i) {
              final AdminNote note = items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.note_outlined),
                  title: Text(note.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(note.content,
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  onTap: () => _editNote(context, ref, note),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref
                          .read(adminContentServiceProvider)
                          .deleteNote(note.id);
                      ref.invalidate(adminNotesProvider);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editNote(
      BuildContext context, WidgetRef ref, AdminNote? existing) async {
    final TextEditingController title =
        TextEditingController(text: existing?.title ?? '');
    final TextEditingController content =
        TextEditingController(text: existing?.content ?? '');

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add Note' : 'Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            TextField(
              controller: content,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save != true) return;
    if (title.text.trim().isEmpty) return;

    await ref.read(adminContentServiceProvider).saveNote(
          AdminNote(
            id: existing?.id ?? const Uuid().v4(),
            title: title.text.trim(),
            content: content.text.trim(),
            createdAt: existing?.createdAt ?? DateTime.now(),
          ),
        );
    ref.invalidate(adminNotesProvider);
  }
}

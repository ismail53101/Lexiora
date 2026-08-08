import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/usecases/library_usecases.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/modules/admin/data/services/admin_content_service.dart';
import 'package:lexiora/modules/admin/domain/entities/admin_link.dart';
import 'package:lexiora/modules/admin/domain/entities/admin_note.dart';
import 'package:lexiora/modules/admin/presentation/providers/admin_providers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

enum _ItemType { pdf, link, note }

/// A unified view over a PDF, link, or note so all three can share one list,
/// one subject grouping, and one sort order.
class _AdminItem {
  const _AdminItem({
    required this.type,
    required this.title,
    required this.subject,
    required this.createdAt,
    this.doc,
    this.link,
    this.note,
  });

  final _ItemType type;
  final String title;
  final String? subject;
  final DateTime createdAt;
  final LibraryDocument? doc;
  final AdminLink? link;
  final AdminNote? note;
}

/// Back-office content curation: PDFs, links and notes added here are
/// visible to every user of the app (PDFs appear filed under the "Admin"
/// library category). Shown as one combined, subject-organized list rather
/// than separate tabs, since a subject often mixes all three content types.
class AdminPanelPage extends ConsumerWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String> categoryId = ref.watch(adminCategoryIdProvider);
    final AsyncValue<List<AdminLink>> links = ref.watch(adminLinksProvider);
    final AsyncValue<List<AdminNote>> notes = ref.watch(adminNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Export for release',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () => _export(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(
          context,
          ref,
          categoryId.when(
            data: (String v) => v,
            loading: () => null,
            error: (Object _, StackTrace _) => null,
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: categoryId.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) =>
            Center(child: Text('Could not set up the Admin category: $e')),
        data: (String catId) => StreamBuilder<List<LibraryDocument>>(
          stream: ref.watch(libraryRepositoryProvider).watchByCategory(catId),
          builder: (BuildContext context,
              AsyncSnapshot<List<LibraryDocument>> docsSnap) {
            return FutureBuilder<Map<String, String>>(
              future: ref.watch(adminContentServiceProvider).loadPdfSubjects(),
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, String>> subjectsSnap) {
                if (!docsSnap.hasData ||
                    !links.hasValue ||
                    !notes.hasValue ||
                    !subjectsSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final Map<String, String> pdfSubjects = subjectsSnap.data!;
                final List<_AdminItem> items = <_AdminItem>[
                  ...docsSnap.data!.map((LibraryDocument d) => _AdminItem(
                        type: _ItemType.pdf,
                        title: d.title,
                        subject: pdfSubjects[d.id],
                        createdAt: d.importedAt,
                        doc: d,
                      )),
                  ...links.value!.map((AdminLink l) => _AdminItem(
                        type: _ItemType.link,
                        title: l.title,
                        subject: l.subject,
                        createdAt: l.createdAt,
                        link: l,
                      )),
                  ...notes.value!.map((AdminNote n) => _AdminItem(
                        type: _ItemType.note,
                        title: n.title,
                        subject: n.subject,
                        createdAt: n.createdAt,
                        note: n,
                      )),
                ];

                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Nothing added yet',
                    message: 'Use + to add a PDF, link, or note — tag it '
                        'with a subject to keep things organized.',
                  );
                }

                final Map<String, List<_AdminItem>> grouped =
                    <String, List<_AdminItem>>{};
                for (final _AdminItem item in items) {
                  final String key = (item.subject == null ||
                          item.subject!.trim().isEmpty)
                      ? 'General'
                      : item.subject!.trim();
                  grouped.putIfAbsent(key, () => <_AdminItem>[]).add(item);
                }
                final List<String> subjects = grouped.keys.toList()
                  ..sort((String a, String b) {
                    if (a == 'General') return 1;
                    if (b == 'General') return -1;
                    return a.compareTo(b);
                  });
                for (final String s in subjects) {
                  grouped[s]!
                      .sort((a, b) => b.createdAt.compareTo(a.createdAt));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  itemCount: subjects.length,
                  itemBuilder: (BuildContext context, int i) {
                    final String subject = subjects[i];
                    return _SubjectSection(
                      subject: subject,
                      items: grouped[subject]!,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Building export…')),
    );
    try {
      final String path =
          await ref.read(adminExportServiceProvider).exportToZip();
      messenger.hideCurrentSnackBar();
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(path)],
          text: 'Sapiora Admin export — content to fold into the next release.',
        ),
      );
    } on Object catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  void _showAddSheet(
      BuildContext context, WidgetRef ref, String? categoryId) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Add PDF'),
              enabled: categoryId != null,
              onTap: () {
                Navigator.of(sheetContext).pop();
                if (categoryId != null) _addPdf(context, ref, categoryId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_link),
              title: const Text('Add Link'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _editLink(context, ref, null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Add Note'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _editNote(context, ref, null);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _addPdf(
      BuildContext context, WidgetRef ref, String categoryId) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(adminImportPdfsProvider).call(categoryId);
    if (!context.mounted) return;

    if (result case Err(:final failure)) {
      messenger.showSnackBar(
          SnackBar(content: Text('Import failed: ${failure.message}')));
      return;
    }
    final ImportOutcome outcome = (result as Ok<ImportOutcome>).value;
    messenger
        .showSnackBar(SnackBar(content: Text('Added ${outcome.added} PDF(s).')));

    final String? subject = await _askSubject(context);
    if (!context.mounted) return;
    if (subject == null || subject.trim().isEmpty) return;

    // Applies the chosen subject to every newly-added PDF in this batch.
    final List<LibraryDocument> docs = await ref
        .read(libraryRepositoryProvider)
        .watchByCategory(categoryId)
        .first;
    final AdminContentService service = ref.read(adminContentServiceProvider);
    for (final LibraryDocument d in docs.take(outcome.added)) {
      await service.setPdfSubject(d.id, subject);
    }
  }

  Future<String?> _askSubject(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Subject (optional)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'e.g. Pakistan Affairs, English'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
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
    final TextEditingController subject =
        TextEditingController(text: existing?.subject ?? '');

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add Link' : 'Edit Link'),
        content: SingleChildScrollView(
          child: Column(
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
                controller: subject,
                decoration: const InputDecoration(
                    labelText: 'Subject (optional)',
                    hintText: 'e.g. Pakistan Affairs'),
              ),
              TextField(
                controller: note,
                decoration:
                    const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
            ],
          ),
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
            subject: subject.text.trim().isEmpty ? null : subject.text.trim(),
            createdAt: existing?.createdAt ?? DateTime.now(),
          ),
        );
    ref.invalidate(adminLinksProvider);
  }

  Future<void> _editNote(
      BuildContext context, WidgetRef ref, AdminNote? existing) async {
    final TextEditingController title =
        TextEditingController(text: existing?.title ?? '');
    final TextEditingController content =
        TextEditingController(text: existing?.content ?? '');
    final TextEditingController subject =
        TextEditingController(text: existing?.subject ?? '');

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add Note' : 'Edit Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              TextField(
                controller: subject,
                decoration: const InputDecoration(
                    labelText: 'Subject (optional)',
                    hintText: 'e.g. Pakistan Affairs'),
              ),
              TextField(
                controller: content,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 5,
              ),
            ],
          ),
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
            subject: subject.text.trim().isEmpty ? null : subject.text.trim(),
            createdAt: existing?.createdAt ?? DateTime.now(),
          ),
        );
    ref.invalidate(adminNotesProvider);
  }
}

class _SubjectSection extends StatelessWidget {
  const _SubjectSection({required this.subject, required this.items});

  final String subject;
  final List<_AdminItem> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text(
            subject.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        ...items.map((_AdminItem item) => _AdminItemTile(item: item)),
      ],
    );
  }
}

class _AdminItemTile extends ConsumerWidget {
  const _AdminItemTile({required this.item});

  final _AdminItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (IconData icon, String subtitle) = switch (item.type) {
      _ItemType.pdf => (Icons.picture_as_pdf_outlined,
          '${(item.doc!.fileSize / 1024 / 1024).toStringAsFixed(1)} MB'),
      _ItemType.link => (Icons.link, item.link!.url),
      _ItemType.note => (Icons.note_outlined, item.note!.content),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () => _open(context, ref),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(ref),
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    switch (item.type) {
      case _ItemType.pdf:
        context.push(AppRoutes.reader(item.doc!.id));
      case _ItemType.link:
        // ignore: unused_local_variable — reserved for a future "open in
        // browser" action; editing is available via the add-sheet reuse.
        break;
      case _ItemType.note:
        break;
    }
  }

  Future<void> _delete(WidgetRef ref) async {
    switch (item.type) {
      case _ItemType.pdf:
        await ref.read(deleteDocumentProvider).call(item.doc!.id);
      case _ItemType.link:
        await ref.read(adminContentServiceProvider).deleteLink(item.link!.id);
        ref.invalidate(adminLinksProvider);
      case _ItemType.note:
        await ref.read(adminContentServiceProvider).deleteNote(item.note!.id);
        ref.invalidate(adminNotesProvider);
    }
  }
}

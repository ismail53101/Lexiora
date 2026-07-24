import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/features/library/domain/entities/category.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/usecases/library_usecases.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/features/library/presentation/widgets/document_card.dart';

/// The Library screen: an adaptive grid of imported PDFs with category
/// filtering and import. Column count adapts to width (phones → tablets).
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String? _categoryId;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<LibraryDocument>> documents = _categoryId == null
        ? ref.watch(allDocumentsProvider)
        : ref.watch(documentsByCategoryProvider(_categoryId!));
    final AsyncValue<List<Category>> categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importing ? null : _import,
        icon: _importing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(_importing ? 'Importing…' : 'Import PDF'),
      ),
      body: Column(
        children: [
          categories.maybeWhen(
            data: (List<Category> cats) => _CategoryBar(
              categories: cats,
              selectedId: _categoryId,
              onSelected: (String? id) => setState(() => _categoryId = id),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: documents.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(child: Text('Error: $e')),
              data: (List<LibraryDocument> docs) {
                if (docs.isEmpty) {
                  return EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: _categoryId == null
                        ? 'Your library is empty'
                        : 'Nothing in this category yet',
                    message: 'Import a PDF to start reading and studying.',
                    action: FilledButton.icon(
                      onPressed: _importing ? null : _import,
                      icon: const Icon(Icons.add),
                      label: const Text('Import PDF'),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (BuildContext context, int i) {
                    final LibraryDocument doc = docs[i];
                    return DocumentCard(
                      document: doc,
                      onOpen: () => context.push(AppRoutes.reader(doc.id)),
                      onAction: (DocumentCardAction a) =>
                          _onAction(a, doc),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _import() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _importing = true);
    final Result<LibraryDocument?> result =
        await ref.read(importDocumentProvider).call(const NoParams());
    if (!mounted) return;
    setState(() => _importing = false);
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text('Import failed: ${failure.message}')),
      ),
      (LibraryDocument? doc) {
        if (doc != null) {
          messenger.showSnackBar(
            SnackBar(content: Text('Imported "${doc.title}"')),
          );
        }
      },
    );
  }

  Future<void> _onAction(DocumentCardAction action, LibraryDocument doc) async {
    switch (action) {
      case DocumentCardAction.favorite:
        await ref.read(toggleFavoriteProvider).call(doc.id);
      case DocumentCardAction.rename:
        await _rename(doc);
      case DocumentCardAction.delete:
        await _confirmDelete(doc);
    }
  }

  Future<void> _rename(LibraryDocument doc) async {
    final TextEditingController controller =
        TextEditingController(text: doc.title);
    final String? newTitle = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (String v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle == null || newTitle.isEmpty || !mounted) return;
    await ref
        .read(renameDocumentProvider)
        .call(RenameDocumentParams(doc.id, newTitle));
  }

  Future<void> _confirmDelete(LibraryDocument doc) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
          '"${doc.title}" and all its highlights, notes and bookmarks will be '
          'permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final Result<void> result =
        await ref.read(deleteDocumentProvider).call(doc.id);
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text('Delete failed: ${failure.message}')),
      ),
      (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Document deleted')),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedId == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...categories.map(
            (Category c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c.name),
                selected: selectedId == c.id,
                avatar: CircleAvatar(
                  backgroundColor: Color(c.colorValue),
                  radius: 8,
                ),
                onSelected: (_) => onSelected(c.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

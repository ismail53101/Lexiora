import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/services/permission_service.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/features/library/domain/entities/category.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/usecases/library_usecases.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/features/library/presentation/widgets/document_card.dart';

/// Ways to order the library.
enum LibrarySort { name, importDate, lastOpened, fileSize }

extension on LibrarySort {
  String get label => switch (this) {
        LibrarySort.name => 'Name (A–Z)',
        LibrarySort.importDate => 'Date added',
        LibrarySort.lastOpened => 'Last opened',
        LibrarySort.fileSize => 'File size',
      };
}

/// The Library screen: an adaptive grid of every PDF on the device, with
/// search, sort and category filtering.
///
/// Discovery is fully automatic — there is no import or "find files" button.
/// On open (and on pull-to-refresh) Lexiora scans the device and lists every
/// PDF, referencing each file in place. The one prerequisite on Android 11+ is
/// the one-time "All files access" grant, surfaced as a permission state.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String? _categoryId;
  bool _scanning = false;
  bool _importing = false;
  bool _accessDenied = false;
  bool _searching = false;
  String _query = '';
  LibrarySort _sort = LibrarySort.importDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _autoDiscover(initial: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<LibraryDocument>> documents = _categoryId == null
        ? ref.watch(allDocumentsProvider)
        : ref.watch(documentsByCategoryProvider(_categoryId!));
    final AsyncValue<List<Category>> categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search library',
                  border: InputBorder.none,
                ),
                onChanged: (String v) => setState(() => _query = v),
              )
            : const Text('Library'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: _searching ? 'Close search' : 'Search',
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
          PopupMenuButton<LibrarySort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (LibrarySort s) => setState(() => _sort = s),
            itemBuilder: (BuildContext context) => LibrarySort.values
                .map((LibrarySort s) => PopupMenuItem<LibrarySort>(
                      value: s,
                      child: Text(s.label),
                    ))
                .toList(),
          ),
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => _autoDiscover(),
            ),
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
            : const Icon(Icons.file_upload_outlined),
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
            child: _accessDenied
                ? _accessState()
                : documents.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (Object e, _) =>
                        Center(child: Text('Error: $e')),
                    data: (List<LibraryDocument> docs) {
                      final List<LibraryDocument> visible = _applyView(docs);
                      return RefreshIndicator(
                        onRefresh: _autoDiscover,
                        child: visible.isEmpty
                            ? _emptyScrollable(_emptyContent())
                            : GridView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 96),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 200,
                                  childAspectRatio: 0.60,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: visible.length,
                                itemBuilder: (BuildContext context, int i) {
                                  final LibraryDocument doc = visible[i];
                                  return DocumentCard(
                                    document: doc,
                                    onOpen: () => context
                                        .push(AppRoutes.reader(doc.id)),
                                    onAction: (DocumentCardAction a) =>
                                        _onAction(a, doc),
                                  );
                                },
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<LibraryDocument> _applyView(List<LibraryDocument> docs) {
    final String q = _query.trim().toLowerCase();
    final List<LibraryDocument> filtered = q.isEmpty
        ? List<LibraryDocument>.of(docs)
        : docs
            .where((LibraryDocument d) => d.title.toLowerCase().contains(q))
            .toList();
    filtered.sort((LibraryDocument a, LibraryDocument b) {
      switch (_sort) {
        case LibrarySort.name:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case LibrarySort.importDate:
          return b.importedAt.compareTo(a.importedAt);
        case LibrarySort.fileSize:
          return b.fileSize.compareTo(a.fileSize);
        case LibrarySort.lastOpened:
          final DateTime a0 =
              a.lastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime b0 =
              b.lastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return b0.compareTo(a0);
      }
    });
    return filtered;
  }

  /// Wraps empty-state content so pull-to-refresh still works when the grid has
  /// no items.
  Widget _emptyScrollable(Widget child) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          ],
        ),
      );

  Widget _emptyContent() {
    if (_query.isNotEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No matches',
        message: 'No documents match "$_query".',
      );
    }
    if (_categoryId != null) {
      return const EmptyState(
        icon: Icons.folder_outlined,
        title: 'Nothing in this category yet',
        message: 'Assign documents to this category to see them here.',
      );
    }
    return EmptyState(
      icon: Icons.menu_book_outlined,
      title: 'No PDFs found',
      message: 'Sapiora didn’t find any PDF files on this device yet. Add PDFs '
          '(for example to Downloads or Documents) and pull down to refresh, or '
          'use Import PDF to pick files yourself.',
      action: Wrap(
        spacing: 12,
        alignment: WrapAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _scanning ? null : () => _autoDiscover(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
          FilledButton.icon(
            onPressed: _importing ? null : _import,
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Import PDF'),
          ),
        ],
      ),
    );
  }

  Widget _accessState() {
    return EmptyState(
      icon: Icons.folder_off_outlined,
      title: 'Allow access to your files',
      message: 'Sapiora lists the PDFs already on your device — nothing is '
          'ever uploaded and everything stays on your phone. To do that it '
          'needs the one-time “All files access” permission (the same '
          'one Adobe Acrobat and Xodo use). Grant it once and your PDFs appear '
          'here automatically. You can also use Import PDF to add files without '
          'granting access.',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: _scanning ? null : () => _autoDiscover(),
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Grant access'),
          ),
          TextButton(
            onPressed: () =>
                ref.read(permissionServiceProvider).openSystemSettings(),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

  /// Ensures storage access, then scans the device and indexes any PDFs not yet
  /// in the library. Runs automatically on open and on pull-to-refresh.
  Future<void> _autoDiscover({bool initial = false}) async {
    if (_scanning) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final PermissionService perm = ref.read(permissionServiceProvider);
    setState(() => _scanning = true);

    final StorageAccessStatus status = await perm.requestForDiscovery();
    if (!mounted) return;

    if (status != StorageAccessStatus.granted) {
      setState(() {
        _scanning = false;
        _accessDenied = true;
      });
      if (!initial && status == StorageAccessStatus.permanentlyDenied) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Enable “All files access” in Settings to see your PDFs.',
            ),
          ),
        );
      }
      return;
    }

    final Result<DiscoveryOutcome> result =
        await ref.read(autoDiscoverProvider).call(const NoParams());
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _accessDenied = false;
    });
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text('Scan failed: ${failure.message}')),
      ),
      (DiscoveryOutcome o) {
        if (initial) return; // silent on first automatic scan
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              o.added > 0
                  ? 'Added ${o.added} new PDF${o.added == 1 ? '' : 's'}'
                  : 'Library is up to date',
            ),
          ),
        );
      },
    );
  }

  /// Manual import via the system file picker (one or several PDFs). Imported
  /// files appear in the library immediately (the list is stream-backed);
  /// duplicates of already-known files are skipped.
  Future<void> _import() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _importing = true);
    final Result<ImportOutcome> result =
        await ref.read(importPdfsProvider).call(const NoParams());
    if (!mounted) return;
    setState(() => _importing = false);
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text('Import failed: ${failure.message}')),
      ),
      (ImportOutcome o) {
        if (o.picked == 0) return; // user cancelled the picker
        final String msg;
        if (o.added > 0 && o.duplicates > 0) {
          msg = 'Imported ${o.added} PDF${o.added == 1 ? '' : 's'} '
              '· skipped ${o.duplicates} already in your library';
        } else if (o.added > 0) {
          msg = 'Imported ${o.added} PDF${o.added == 1 ? '' : 's'}';
        } else {
          msg = o.duplicates == 1
              ? 'That PDF is already in your library'
              : 'Those PDFs are already in your library';
        }
        messenger.showSnackBar(SnackBar(content: Text(msg)));
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
        title: const Text('Remove from library?'),
        content: Text(
          '"${doc.title}" will be removed from your library along with its '
          'highlights, notes and bookmarks. The original PDF file on your '
          'device is not deleted, so it may reappear on the next scan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final Result<void> result =
        await ref.read(deleteDocumentProvider).call(doc.id);
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text('Remove failed: ${failure.message}')),
      ),
      (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Removed from library')),
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

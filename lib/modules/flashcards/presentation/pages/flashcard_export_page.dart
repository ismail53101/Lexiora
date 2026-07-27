import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/data/services/flashcard_export_service.dart';
import 'package:lexiora/modules/flashcards/domain/entities/deck.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/flashcard_repository.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_common.dart';

/// Export cards (CSV/PDF/Excel/JSON) and manage local JSON backups.
class FlashcardExportPage extends ConsumerStatefulWidget {
  const FlashcardExportPage({super.key});

  @override
  ConsumerState<FlashcardExportPage> createState() =>
      _FlashcardExportPageState();
}

class _FlashcardExportPageState extends ConsumerState<FlashcardExportPage> {
  String? _deckId; // null = all decks
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final List<DeckSummary> decks = ref.watch(decksProvider(true)).maybeWhen(
          data: (List<DeckSummary> d) => d,
          orElse: () => const <DeckSummary>[],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Export & Backup')),
      body: Stack(
        children: <Widget>[
          ListView(
            children: <Widget>[
              FcSectionCard(
                icon: Icons.file_download_outlined,
                title: 'Export cards',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Text('Scope:'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _deckId,
                            items: <DropdownMenuItem<String?>>[
                              const DropdownMenuItem<String?>(
                                  child: Text('All decks')),
                              for (final DeckSummary d in decks)
                                DropdownMenuItem<String?>(
                                    value: d.deck.id, child: Text(d.deck.name)),
                            ],
                            onChanged: (String? v) =>
                                setState(() => _deckId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        for (final FcExportFormat f in FcExportFormat.values)
                          OutlinedButton.icon(
                            onPressed: _busy ? null : () => _export(f, decks),
                            icon: Icon(_iconFor(f), size: 18),
                            label: Text(f.label),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Exports the selected scope. JSON backup here is a '
                      'lightweight card export — use the full backup below to '
                      'preserve decks, progress and settings.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FcSectionCard(
                icon: Icons.backup_outlined,
                title: 'Full backup',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                        'Backs up every deck, card, review log, bookmark, '
                        'favourite and setting to a JSON file you can share or '
                        'restore later.'),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: _busy ? null : _backup,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Create backup'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _openRestore,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(FcExportFormat f) => switch (f) {
        FcExportFormat.csv => Icons.grid_on,
        FcExportFormat.pdf => Icons.picture_as_pdf_outlined,
        FcExportFormat.xlsx => Icons.table_chart_outlined,
        FcExportFormat.json => Icons.data_object,
      };

  Future<void> _export(FcExportFormat format, List<DeckSummary> decks) async {
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final FlashcardRepository repo = ref.read(flashcardRepositoryProvider);
      final FlashcardFilter filter = _deckId == null
          ? const FlashcardFilter()
          : FlashcardFilter(deckId: _deckId);
      final List<Flashcard> cards = await repo.cards(filter, limit: 100000);
      final Map<String, String> deckNames = <String, String>{
        for (final DeckSummary d in decks) d.deck.id: d.deck.name,
      };
      final String title = _deckId == null
          ? 'All flashcards'
          : (deckNames[_deckId] ?? 'Flashcards');
      await ref.read(fcExportServiceProvider).exportCards(
            title: title,
            cards: cards,
            deckNames: deckNames,
            format: format,
          );
      messenger.showSnackBar(
          SnackBar(content: Text('Exported ${cards.length} cards')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backup() async {
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(fcExportServiceProvider)
          .backupAndShare(ref.read(flashcardRepositoryProvider));
      messenger.showSnackBar(const SnackBar(content: Text('Backup created')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRestore() async {
    final FlashcardExportService service = ref.read(fcExportServiceProvider);
    final List<FcBackupFile> files = await service.listBackups();
    if (!mounted) return;
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved backups found')));
      return;
    }
    final FcBackupFile? chosen = await showModalBottomSheet<FcBackupFile>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ListTile(title: Text('Restore from backup')),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (final FcBackupFile f in files)
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(f.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(f.savedAt.toString().substring(0, 16)),
                      onTap: () => Navigator.of(context).pop(f),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final bool ok = await _confirmRestore(chosen);
    if (!ok || !mounted) return;
    await _restore(chosen);
  }

  Future<bool> _confirmRestore(FcBackupFile file) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Restore backup?'),
            content: Text(
                'This replaces all current flashcards with the contents of '
                '"${file.name}". This cannot be undone.'),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Restore')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _restore(FcBackupFile file) async {
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(fcExportServiceProvider)
          .restore(ref.read(flashcardRepositoryProvider), file.path);
      ref.read(fcRevisionProvider.notifier).bump();
      messenger.showSnackBar(const SnackBar(content: Text('Backup restored')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

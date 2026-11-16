import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/data/fc_export_service.dart';
import 'package:lexiora/modules/flashcards/domain/logic/export_rows.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_query.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';

/// Export cards to a file, and back up / restore everything.
class FlashcardsExportPage extends ConsumerStatefulWidget {
  const FlashcardsExportPage({super.key, this.deckId});

  final String? deckId;

  @override
  ConsumerState<FlashcardsExportPage> createState() => _FlashcardsExportPageState();
}

class _FlashcardsExportPageState extends ConsumerState<FlashcardsExportPage> {
  late String? _scope = widget.deckId;
  FcExportFormat _format = FcExportFormat.csv;
  bool _busy = false;
  List<FcBackupFile> _backups = <FcBackupFile>[];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    try {
      final List<FcBackupFile> b = await ref.read(fcExportServiceProvider).listBackups();
      if (mounted) setState(() => _backups = b);
    } catch (_) {}
  }

  Future<void> _export(List<FcDeckSummary> decks) async {
    setState(() => _busy = true);
    try {
      final Map<String, String> names = <String, String>{for (final FcDeckSummary s in decks) s.deck.id: s.deck.name};
      final List<FcCard> cards = await ref.read(fcRepositoryProvider).browse(FcCardQuery(deckId: _scope, limit: 1000000, sort: FcSort.alphabetical));
      if (cards.isEmpty) {
        if (mounted) fcToast(context, 'There are no cards to export');
        return;
      }
      await ref.read(fcExportServiceProvider).exportCards(
            title: _scope == null ? 'All decks' : (names[_scope] ?? 'deck'),
            cards: cards,
            deckNames: names,
            format: _format,
          );
    } catch (e) {
      if (mounted) fcToast(context, 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      await ref.read(fcExportServiceProvider).backupAndShare(ref.read(fcRepositoryProvider));
      await _loadBackups();
    } catch (e) {
      if (mounted) fcToast(context, 'Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(FcBackupFile f) async {
    final bool ok = await fcConfirm(
      context,
      title: 'Restore this backup?',
      message: 'All current decks, cards and history will be REPLACED by the contents of ${f.name}.',
      confirmLabel: 'Restore',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(fcExportServiceProvider).restore(ref.read(fcRepositoryProvider), f.path);
      if (mounted) fcToast(context, 'Backup restored');
    } catch (e) {
      if (mounted) fcToast(context, 'Couldn’t restore: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<FcDeckSummary> decks = ref.watch(fcAllDecksProvider).asData?.value ?? const <FcDeckSummary>[];
    final String? scope = decks.any((FcDeckSummary s) => s.deck.id == _scope) ? _scope : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Export & backup')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          FcSectionCard(
            margin: EdgeInsets.zero,
            title: 'Export cards',
            icon: Icons.ios_share,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownButtonFormField<String?>(
                  initialValue: scope,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'What to export', border: OutlineInputBorder()),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(child: Text('All decks')),
                    for (final FcDeckSummary s in decks) DropdownMenuItem<String?>(value: s.deck.id, child: Text(s.deck.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (String? v) => setState(() => _scope = v),
                ),
                const SizedBox(height: 12),
                RadioGroup<FcExportFormat>(
                  groupValue: _format,
                  onChanged: (FcExportFormat? v) => setState(() => _format = v ?? _format),
                  child: Column(
                    children: <Widget>[
                      for (final FcExportFormat f in FcExportFormat.values)
                        RadioListTile<FcExportFormat>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: f,
                          title: Text(f.label),
                          subtitle: f == FcExportFormat.anki ? const Text('Tab-separated; imports into Anki and back here') : null,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _export(decks),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Export'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FcSectionCard(
            margin: EdgeInsets.zero,
            title: 'Backup',
            icon: Icons.backup_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'A backup contains every deck, card, setting and your full review history. '
                  'It is saved on this device and offered to the share sheet so you can keep a copy elsewhere.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _backup,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Back up now'),
                  ),
                ),
                if (_backups.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text('Saved on this device', style: theme.textTheme.titleSmall),
                  for (final FcBackupFile f in _backups)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.description_outlined),
                      title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${f.savedAt.year}-${f.savedAt.month.toString().padLeft(2, '0')}-${f.savedAt.day.toString().padLeft(2, '0')} ${f.savedAt.hour.toString().padLeft(2, '0')}:${f.savedAt.minute.toString().padLeft(2, '0')}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextButton(onPressed: _busy ? null : () => _restore(f), child: const Text('Restore')),
                          IconButton(
                            tooltip: 'Delete backup',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _busy
                                ? null
                                : () async {
                                    await ref.read(fcExportServiceProvider).deleteBackup(f.path);
                                    await _loadBackups();
                                  },
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

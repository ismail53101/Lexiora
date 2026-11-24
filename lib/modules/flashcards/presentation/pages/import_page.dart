import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/domain/logic/csv_codec.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_stats_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/fc_repository.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_sheets.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';
import 'package:lexiora/modules/vocabulary/presentation/providers/vocabulary_providers.dart';

/// Bring cards in: paste a table / Anki text, or pull from other parts of the app.
class FlashcardsImportPage extends ConsumerStatefulWidget {
  const FlashcardsImportPage({super.key});

  @override
  ConsumerState<FlashcardsImportPage> createState() => _FlashcardsImportPageState();
}

class _FlashcardsImportPageState extends ConsumerState<FlashcardsImportPage> {
  String? _deckId;

  Future<void> _newDeck() async {
    final FcDeck? d = await showDeckEditor(context);
    if (d != null && mounted) setState(() => _deckId = d.id);
  }

  Widget _deckPicker(List<FcDeckSummary> decks) {
    final String? value = decks.any((FcDeckSummary s) => s.deck.id == _deckId) ? _deckId : null;
    return Row(
      children: <Widget>[
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Add to deck', border: OutlineInputBorder()),
            items: <DropdownMenuItem<String>>[
              for (final FcDeckSummary s in decks) DropdownMenuItem<String>(value: s.deck.id, child: Text(s.deck.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (String? v) => setState(() => _deckId = v),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(tooltip: 'New deck', icon: const Icon(Icons.add), onPressed: _newDeck),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<FcDeckSummary> decks = ref.watch(fcDecksProvider).asData?.value ?? const <FcDeckSummary>[];
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import cards'),
          bottom: const TabBar(tabs: <Tab>[Tab(text: 'Paste / file text'), Tab(text: 'From the app')]),
        ),
        body: TabBarView(
          children: <Widget>[
            _PasteTab(deckPicker: _deckPicker(decks), deckId: _deckId),
            _AppTab(deckPicker: _deckPicker(decks), deckId: _deckId),
          ],
        ),
      ),
    );
  }
}

class _PasteTab extends ConsumerStatefulWidget {
  const _PasteTab({required this.deckPicker, required this.deckId});
  final Widget deckPicker;
  final String? deckId;

  @override
  ConsumerState<_PasteTab> createState() => _PasteTabState();
}

class _PasteTabState extends ConsumerState<_PasteTab> {
  final TextEditingController _text = TextEditingController();
  bool _reversed = false;
  bool _busy = false;
  DraftParseResult _parsed = const DraftParseResult(<CardDraft>[], 0);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _parse(String v) =>
      setState(() => _parsed = draftsFromRows(parseDelimited(v)));

  Future<void> _import() async {
    final String? deckId = widget.deckId;
    if (deckId == null) {
      fcToast(context, 'Choose a deck first');
      return;
    }
    setState(() => _busy = true);
    final AddCardsResult r = await ref.read(fcRepositoryProvider).addCards(deckId, _parsed.drafts, reversed: _reversed);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _text.clear();
      _parsed = const DraftParseResult(<CardDraft>[], 0);
    });
    fcToast(context, 'Imported ${r.created} ${r.created == 1 ? 'card' : 'cards'}${r.skipped > 0 ? ' (${r.skipped} skipped)' : ''}');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        widget.deckPicker,
        const SizedBox(height: 14),
        TextField(
          controller: _text,
          minLines: 8,
          maxLines: 14,
          onChanged: _parse,
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            labelText: 'Paste your cards',
            hintText: 'front,back,tags\nHello,سلام,greetings\nThe {{c1::sun}} is a star',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'One card per line. Use commas, tabs or semicolons between columns: '
          'front, back, tags, notes. A first line like “front,back” is detected '
          'automatically. Text with {{c1::…}} becomes a cloze card. Anki “Notes in '
          'Plain Text” exports work too.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (_parsed.drafts.isNotEmpty || _parsed.skipped > 0)
          FcSectionCard(
            margin: EdgeInsets.zero,
            title: 'Preview',
            icon: Icons.visibility_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${_parsed.drafts.length} cards ready${_parsed.skipped > 0 ? ' · ${_parsed.skipped} rows skipped (empty front/back)' : ''}',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final CardDraft d in _parsed.drafts.take(4))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('• ${d.front}  →  ${d.back.isEmpty ? '(cloze)' : d.back}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                if (_parsed.drafts.length > 4) Text('… and ${_parsed.drafts.length - 4} more', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Also create reverse cards'),
          value: _reversed,
          onChanged: (bool v) => setState(() => _reversed = v),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy || _parsed.drafts.isEmpty ? null : _import,
          icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_done),
          label: Text('Import ${_parsed.drafts.length} ${_parsed.drafts.length == 1 ? 'card' : 'cards'}'),
        ),
      ],
    );
  }
}

class _AppTab extends ConsumerStatefulWidget {
  const _AppTab({required this.deckPicker, required this.deckId});
  final Widget deckPicker;
  final String? deckId;

  @override
  ConsumerState<_AppTab> createState() => _AppTabState();
}

class _AppTabState extends ConsumerState<_AppTab> {
  ImportSource _source = ImportSource.vocabulary;
  String _query = '';
  Timer? _debounce;
  List<ImportCandidate> _items = <ImportCandidate>[];
  final Set<int> _picked = <int>{};
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Vocabulary is seeded lazily by its own module. Ensure the bundled
      // vocabulary packs are loaded before querying the shared database.
      if (_source == ImportSource.vocabulary) {
        await ref.read(vocabularySeederProvider).ensureSeeded();
      }
      final List<ImportCandidate> r = await ref.read(fcRepositoryProvider).importCandidates(_source, _query);
      if (!mounted) return;
      setState(() {
        _items = r;
        _picked.clear();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = <ImportCandidate>[];
          _loading = false;
        });
      }
    }
  }

  Future<void> _import() async {
    final String? deckId = widget.deckId;
    if (deckId == null) {
      fcToast(context, 'Choose a deck first');
      return;
    }
    setState(() => _busy = true);
    final FcRepository repo = ref.read(fcRepositoryProvider);
    // Keep each item's subject/topic by importing in (subject, topic) groups.
    final Map<(String?, String?), List<CardDraft>> groups = <(String?, String?), List<CardDraft>>{};
    for (final int i in _picked) {
      final ImportCandidate c = _items[i];
      groups.putIfAbsent((c.subject, c.topic), () => <CardDraft>[]).add(CardDraft(front: c.front, back: c.back));
    }
    int created = 0;
    for (final MapEntry<(String?, String?), List<CardDraft>> g in groups.entries) {
      created += (await repo.addCards(deckId, g.value, subject: g.key.$1, topic: g.key.$2)).created;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _picked.clear();
    });
    fcToast(context, 'Imported $created ${created == 1 ? 'card' : 'cards'}');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: <Widget>[
              widget.deckPicker,
              const SizedBox(height: 12),
              SegmentedButton<ImportSource>(
                showSelectedIcon: false,
                segments: <ButtonSegment<ImportSource>>[
                  for (final ImportSource s in ImportSource.values) ButtonSegment<ImportSource>(value: s, label: Text(s.label)),
                ],
                selected: <ImportSource>{_source},
                onSelectionChanged: (Set<ImportSource> s) {
                  _source = s.first;
                  _load();
                },
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_source.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(height: 8),
              SearchBar(
                hintText: 'Filter',
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll<double>(0),
                onChanged: (String v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 250), () {
                    _query = v;
                    _load();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(child: Text('Nothing to import from ${_source.label} yet.', style: theme.textTheme.bodyMedium))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (BuildContext c, int i) => CheckboxListTile(
                        value: _picked.contains(i),
                        onChanged: (bool? v) => setState(() => v == true ? _picked.add(i) : _picked.remove(i)),
                        title: Text(_items[i].front, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(_items[i].back, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: <Widget>[
                TextButton(
                  onPressed: _items.isEmpty ? null : () => setState(() => _picked.length == _items.length ? _picked.clear() : _picked.addAll(List<int>.generate(_items.length, (int i) => i))),
                  child: Text(_picked.length == _items.length && _items.isNotEmpty ? 'Clear' : 'Select all'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _busy || _picked.isEmpty ? null : _import,
                  icon: const Icon(Icons.download_done),
                  label: Text('Import ${_picked.length}'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

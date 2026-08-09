import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/domain/entities/deck.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_editor.dart';

/// Import cards from Dictionary, Vocabulary or Study Hub (read-only sources).
/// Imported cards are ordinary, fully-editable cards.
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  ImportSource _source = ImportSource.vocabulary;
  final TextEditingController _query = TextEditingController();
  List<ImportCandidate> _candidates = <ImportCandidate>[];
  final Set<int> _selected = <int>{};
  String? _deckId;
  bool _loading = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final List<ImportCandidate> items = await ref
        .read(flashcardRepositoryProvider)
        .importCandidates(_source, query: _query.text.trim(), limit: 200);
    if (!mounted) return;
    setState(() {
      _candidates = items;
      _selected.clear();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<DeckSummary> decks = ref.watch(decksProvider(false)).maybeWhen(
          data: (List<DeckSummary> d) => d,
          orElse: () => const <DeckSummary>[],
        );
    _deckId ??= decks.isNotEmpty ? decks.first.deck.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Import Cards')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<ImportSource>(
              segments: const <ButtonSegment<ImportSource>>[
                ButtonSegment<ImportSource>(
                    value: ImportSource.dictionary, label: Text('Dictionary')),
                ButtonSegment<ImportSource>(
                    value: ImportSource.vocabulary, label: Text('Vocabulary')),
                ButtonSegment<ImportSource>(
                    value: ImportSource.studyHub, label: Text('Study Planner')),
              ],
              selected: <ImportSource>{_source},
              onSelectionChanged: (Set<ImportSource> s) {
                setState(() => _source = s.first);
                _load();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Filter…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh), onPressed: _load),
              ),
            ),
          ),
          if (decks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  const Expanded(child: Text('Create a deck to import into.')),
                  FilledButton(
                      onPressed: () => showDeckEditor(context),
                      child: const Text('New deck')),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  const Text('Into deck:'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _deckId,
                      items: <DropdownMenuItem<String>>[
                        for (final DeckSummary d in decks)
                          DropdownMenuItem<String>(
                              value: d.deck.id, child: Text(d.deck.name)),
                      ],
                      onChanged: (String? v) => setState(() => _deckId = v),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _candidates.isEmpty
                    ? const Center(child: Text('Nothing to import here.'))
                    : ListView.builder(
                        itemCount: _candidates.length,
                        itemBuilder: (BuildContext context, int i) {
                          final ImportCandidate c = _candidates[i];
                          return CheckboxListTile(
                            value: _selected.contains(i),
                            onChanged: (bool? v) => setState(() =>
                                v ?? false ? _selected.add(i) : _selected.remove(i)),
                            title: Text(c.front,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(c.back,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              TextButton(
                onPressed: _candidates.isEmpty
                    ? null
                    : () => setState(() {
                          if (_selected.length == _candidates.length) {
                            _selected.clear();
                          } else {
                            _selected
                              ..clear()
                              ..addAll(List<int>.generate(_candidates.length, (int i) => i));
                          }
                        }),
                child: Text(_selected.length == _candidates.length && _candidates.isNotEmpty
                    ? 'Clear all'
                    : 'Select all'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: (_selected.isEmpty || _deckId == null || _importing)
                    ? null
                    : _import,
                icon: const Icon(Icons.download),
                label: Text('Import (${_selected.length})'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final List<ImportCandidate> chosen =
        _selected.map((int i) => _candidates[i]).toList();
    final int n = await ref
        .read(flashcardRepositoryProvider)
        .importCards(_deckId!, chosen);
    ref.read(fcRevisionProvider.notifier).bump();
    if (!mounted) return;
    setState(() => _importing = false);
    messenger.showSnackBar(SnackBar(content: Text('Imported $n cards')));
    Navigator.of(context).pop();
  }
}

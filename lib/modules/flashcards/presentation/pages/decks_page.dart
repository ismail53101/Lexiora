import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_sheets.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_tile.dart';

/// Every deck, including archived ones.
class DecksPage extends ConsumerStatefulWidget {
  const DecksPage({super.key});

  @override
  ConsumerState<DecksPage> createState() => _DecksPageState();
}

class _DecksPageState extends ConsumerState<DecksPage> {
  bool _archived = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<FcDeckSummary>> all = ref.watch(fcAllDecksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('All decks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDeckEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('New deck'),
      ),
      body: all.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => EmptyState(icon: Icons.error_outline, title: 'Couldn’t load decks', message: '$e'),
        data: (List<FcDeckSummary> list) {
          final String q = _query.trim().toLowerCase();
          final List<FcDeckSummary> shown = list
              .where((FcDeckSummary s) => s.deck.archived == _archived)
              .where((FcDeckSummary s) =>
                  q.isEmpty ||
                  s.deck.name.toLowerCase().contains(q) ||
                  (s.deck.subject ?? '').toLowerCase().contains(q))
              .toList();
          final int archivedCount = list.where((FcDeckSummary s) => s.deck.archived).length;
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SearchBar(
                  hintText: 'Search decks',
                  leading: const Icon(Icons.search),
                  elevation: const WidgetStatePropertyAll<double>(0),
                  onChanged: (String v) => setState(() => _query = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ChoiceChip(label: const Text('Active'), selected: !_archived, onSelected: (_) => setState(() => _archived = false)),
                    ChoiceChip(label: Text('Archived ($archivedCount)'), selected: _archived, onSelected: (_) => setState(() => _archived = true)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: EmptyState(
                    icon: _archived ? Icons.archive_outlined : Icons.style_outlined,
                    title: _archived ? 'No archived decks' : 'No decks found',
                  ),
                )
              else
                for (final FcDeckSummary s in shown) FcDeckTile(summary: s),
            ],
          );
        },
      ),
    );
  }
}

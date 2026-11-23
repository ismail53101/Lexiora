import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_query.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/card_editor_page.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';

/// Search every card in every deck.
class FlashcardsSearchPage extends ConsumerStatefulWidget {
  const FlashcardsSearchPage({super.key});

  @override
  ConsumerState<FlashcardsSearchPage> createState() => _FlashcardsSearchPageState();
}

class _FlashcardsSearchPageState extends ConsumerState<FlashcardsSearchPage> {
  Timer? _debounce;
  String _text = '';
  FcStatusFilter _status = FcStatusFilter.all;
  List<FcCard> _results = <FcCard>[];
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    if (_text.trim().isEmpty && _status == FcStatusFilter.all) {
      setState(() {
        _results = <FcCard>[];
        _searched = false;
      });
      return;
    }
    final List<FcCard> r = await ref
        .read(fcRepositoryProvider)
        .browse(FcCardQuery(text: _text, status: _status, limit: 200));
    if (mounted) {
      setState(() {
        _results = r;
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<int>>(fcRevisionProvider, (AsyncValue<int>? _, AsyncValue<int> __) => _run());
    final Map<String, String> deckNames = <String, String>{
      for (final FcDeckSummary s in ref.watch(fcAllDecksProvider).asData?.value ?? const <FcDeckSummary>[]) s.deck.id: s.deck.name,
    };
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search all cards', border: InputBorder.none),
          onChanged: (String v) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 250), () {
              _text = v;
              _run();
            });
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                for (final FcStatusFilter f in FcStatusFilter.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: _status == f,
                      onSelected: (_) {
                        _status = f;
                        _run();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: !_searched
                ? const EmptyState(icon: Icons.search, title: 'Search your cards', message: 'Type a word, or pick a filter such as Starred or Leeches.')
                : _results.isEmpty
                    ? const EmptyState(icon: Icons.search_off, title: 'No cards found')
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (BuildContext c, int i) {
                          final FcCard card = _results[i];
                          return FcCardTile(
                            card: card,
                            deckName: deckNames[card.deckId],
                            onTap: () => openCardEditor(context, deckId: card.deckId, cardId: card.id),
                            onToggleStar: () => ref.read(fcRepositoryProvider).setStarred(card.id, !card.bookmarked),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

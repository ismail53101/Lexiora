import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/flashcards/domain/entities/deck.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_editor.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_common.dart';

class DecksPage extends ConsumerStatefulWidget {
  const DecksPage({super.key});

  @override
  ConsumerState<DecksPage> createState() => _DecksPageState();
}

class _DecksPageState extends ConsumerState<DecksPage> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final List<DeckSummary> decks = ref.watch(decksProvider(_showArchived)).maybeWhen(
          data: (List<DeckSummary> d) => d,
          orElse: () => const <DeckSummary>[],
        );
    final Map<String, int> colors = ref.watch(fcSubjectColorsProvider).maybeWhen(
          data: (Map<String, int> m) => m,
          orElse: () => const <String, int>{},
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Decks'),
        actions: <Widget>[
          IconButton(
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            icon: Icon(_showArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDeckEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('New deck'),
      ),
      body: decks.isEmpty
          ? const EmptyState(
              icon: Icons.library_books_outlined,
              title: 'No decks yet',
              message: 'Create your first deck to start making flashcards.',
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: decks.length,
              itemBuilder: (BuildContext context, int i) =>
                  _DeckCard(summary: decks[i], colors: colors),
            ),
    );
  }
}

class _DeckCard extends ConsumerWidget {
  const _DeckCard({required this.summary, required this.colors});
  final DeckSummary summary;
  final Map<String, int> colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Deck d = summary.deck;
    final Color color = d.colorValue ??
        subjectColorOf(d.subject, colors) ??
        theme.colorScheme.primary;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push(AppRoutes.flashcardsDeck(d.id)),
        onLongPress: () => showDeckEditor(context, existing: d),
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(Icons.style, color: Colors.white),
        ),
        title: Text(d.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(<String>[
          if (d.subject != null) d.subject!,
          '${summary.cardCount} cards',
          '${summary.dueCount} due',
          if (d.archived) 'Archived',
        ].join(' · ')),
        trailing: summary.dueCount > 0
            ? Chip(
                label: Text('${summary.dueCount}'),
                backgroundColor: theme.colorScheme.primaryContainer,
                visualDensity: VisualDensity.compact,
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

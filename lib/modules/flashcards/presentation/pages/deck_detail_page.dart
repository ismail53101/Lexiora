import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/flashcards/domain/entities/deck.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/card_editor.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_editor.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/paginated_cards.dart';

/// A deck's cards (paginated) with study + add-card actions.
class DeckDetailPage extends ConsumerWidget {
  const DeckDetailPage({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find the deck (and live counts) from the decks stream.
    final List<DeckSummary> decks = ref.watch(decksProvider(true)).maybeWhen(
          data: (List<DeckSummary> d) => d,
          orElse: () => const <DeckSummary>[],
        );
    DeckSummary? summary;
    for (final DeckSummary s in decks) {
      if (s.deck.id == deckId) {
        summary = s;
        break;
      }
    }
    final Deck? deck = summary?.deck;

    return Scaffold(
      appBar: AppBar(
        title: Text(deck?.name ?? 'Deck', overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          if (deck != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit deck',
              onPressed: () => showDeckEditor(context, existing: deck),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCardEditor(context, deckId: deckId),
        icon: const Icon(Icons.add),
        label: const Text('Add card'),
      ),
      body: Column(
        children: <Widget>[
          if (summary != null) _DeckStudyBar(deckId: deckId, summary: summary),
          Expanded(
            child: PaginatedCards(
              filter: FlashcardFilter(deckId: deckId),
              padding: const EdgeInsets.only(bottom: 88, top: 4),
            ),
          ),
        ],
      ),
    );
  }
}

/// The deck's study controls. A deck is permanent and always fully reviewable:
/// [Study] replays the whole deck (first → last) regardless of due status, so it
/// works even when nothing is due. [Review due] is the optional spaced-
/// repetition subset, shown only when there are due cards.
class _DeckStudyBar extends StatelessWidget {
  const _DeckStudyBar({required this.deckId, required this.summary});

  final String deckId;
  final DeckSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasCards = summary.cardCount > 0;
    final bool hasDue = summary.dueCount > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _CountChip(
                  icon: Icons.style_outlined,
                  label: 'Total',
                  value: summary.cardCount,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              _CountChip(
                  icon: Icons.bolt_outlined,
                  label: 'Due',
                  value: summary.dueCount,
                  color: theme.colorScheme.tertiary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: hasCards
                      ? () => context.push(
                          '${AppRoutes.flashcardsStudy}?deck=$deckId&mode=all')
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Study'),
                ),
              ),
              if (hasDue) ...<Widget>[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                        '${AppRoutes.flashcardsStudy}?deck=$deckId&mode=due'),
                    icon: const Icon(Icons.bolt),
                    label: Text('Review due (${summary.dueCount})'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Study reviews every card, anytime. Review due follows spaced '
            'repetition.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text('$value',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

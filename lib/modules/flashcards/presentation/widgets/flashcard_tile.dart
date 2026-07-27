import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/card_editor.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_common.dart';

/// A single card row: front/back preview, subject colour, flags, and a
/// long-press menu (bookmark / favourite / difficulty / delete). Tap to edit.
class FlashcardTile extends ConsumerWidget {
  const FlashcardTile({super.key, required this.card, required this.colors});

  final Flashcard card;
  final Map<String, int> colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Color? sc = subjectColorOf(card.subject, colors);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showCardEditor(context, deckId: card.deckId, existing: card),
        onLongPress: () => _menu(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
          child: Row(
            children: <Widget>[
              Container(
                width: 4,
                height: 42,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: sc ?? theme.colorScheme.primary,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(card.front,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(card.back,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    if (card.subject != null || card.isDifficult)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 6,
                          children: <Widget>[
                            if (card.subject != null)
                              _Tag(text: card.subject!, color: sc),
                            if (card.isDifficult)
                              _Tag(text: 'Hard', color: theme.colorScheme.error),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (card.bookmarked)
                const Icon(Icons.bookmark, size: 18, color: Colors.amber),
              if (card.favorite)
                Icon(Icons.favorite, size: 16, color: theme.colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }

  void _menu(BuildContext context, WidgetRef ref) {
    final repo = ref.read(flashcardRepositoryProvider);
    void done() {
      ref.read(fcRevisionProvider.notifier).bump();
      Navigator.of(context).pop();
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(card.bookmarked ? Icons.bookmark_remove : Icons.bookmark_add_outlined),
              title: Text(card.bookmarked ? 'Remove bookmark' : 'Bookmark'),
              onTap: () {
                repo.setBookmarked(card.id, !card.bookmarked);
                done();
              },
            ),
            ListTile(
              leading: Icon(card.favorite ? Icons.favorite : Icons.favorite_border),
              title: Text(card.favorite ? 'Unfavourite' : 'Favourite'),
              onTap: () {
                repo.setFavorite(card.id, !card.favorite);
                done();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Mark difficulty'),
              subtitle: Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final CardDifficulty d in CardDifficulty.values)
                    ChoiceChip(
                      label: Text(d.label),
                      selected: card.difficulty == d,
                      onSelected: (_) {
                        repo.setDifficulty(card.id, d);
                        done();
                      },
                    ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: const Text('Delete card'),
              onTap: () {
                repo.deleteCard(card.id);
                done();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: c, fontWeight: FontWeight.w600)),
    );
  }
}

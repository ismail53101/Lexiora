import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/card_editor_page.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_sheets.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';

/// Route to start a study session.
String fcStudyLocation({String? deckId, StudyMode mode = StudyMode.due}) =>
    Uri(
      path: AppRoutes.flashcardsStudy,
      queryParameters: <String, String>{
        if (deckId != null) 'deck': deckId,
        if (mode != StudyMode.due) 'mode': mode.name,
      },
    ).toString();

/// Route to the export page, optionally for one deck.
String fcExportLocation({String? deckId}) => Uri(
      path: AppRoutes.flashcardsExport,
      queryParameters: <String, String>{if (deckId != null) 'deck': deckId},
    ).toString();

/// One deck in a list: colour, name, counts, quick "study" button.
class FcDeckTile extends ConsumerWidget {
  const FcDeckTile({super.key, required this.summary});

  final FcDeckSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Map<String, int> colors =
        ref.watch(fcSubjectColorsProvider).asData?.value ?? const <String, int>{};
    final FcDeck deck = summary.deck;
    final Color color = fcDeckColor(deck, colors, cs);
    final String subtitle = <String>[
      if (deck.subject != null) deck.subject!,
      '${summary.total} ${summary.total == 1 ? 'card' : 'cards'}',
    ].join(' · ');

    return Opacity(
      opacity: deck.archived ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.flashcardsDeck(deck.id)),
          onLongPress: () => showDeckActions(context, ref, summary),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.style_rounded, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(deck.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      if (deck.archived)
                        Text('Archived', style: theme.textTheme.labelMedium?.copyWith(color: cs.outline))
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: <Widget>[
                            FcCountChip(label: 'new', value: summary.newCount, color: cs.fcNew, dense: true),
                            FcCountChip(label: 'learn', value: summary.learningCount, color: cs.fcLearning, dense: true),
                            FcCountChip(label: 'due', value: summary.reviewCount, color: cs.fcReview, dense: true),
                          ],
                        ),
                    ],
                  ),
                ),
                if (!deck.archived && summary.dueTotal > 0)
                  IconButton.filled(
                    tooltip: 'Study this deck',
                    icon: const Icon(Icons.play_arrow_rounded),
                    onPressed: () => context.push(fcStudyLocation(deckId: deck.id)),
                  )
                else
                  IconButton(
                    tooltip: 'More',
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => showDeckActions(context, ref, summary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with every action available on a deck.
Future<void> showDeckActions(BuildContext context, WidgetRef ref, FcDeckSummary s) {
  final FcDeck deck = s.deck;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheet) {
      void close() => Navigator.pop(sheet);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(deck.name, style: Theme.of(sheet).textTheme.titleMedium),
              subtitle: Text('${s.total} cards'),
            ),
            ListTile(
              leading: const Icon(Icons.add_card_outlined),
              title: const Text('Add cards'),
              onTap: () {
                close();
                openCardEditor(context, deckId: deck.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename / edit'),
              onTap: () {
                close();
                showDeckEditor(context, deck: deck);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Study settings'),
              onTap: () {
                close();
                showDeckSettings(context, deck.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: const Text('Export this deck'),
              onTap: () {
                close();
                context.push(fcExportLocation(deckId: deck.id));
              },
            ),
            ListTile(
              leading: Icon(deck.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
              title: Text(deck.archived ? 'Unarchive' : 'Archive'),
              onTap: () {
                close();
                ref.read(fcRepositoryProvider).setDeckArchived(deck.id, !deck.archived);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(sheet).colorScheme.error),
              title: Text('Delete deck', style: TextStyle(color: Theme.of(sheet).colorScheme.error)),
              onTap: () async {
                close();
                final bool ok = await fcConfirm(
                  context,
                  title: 'Delete “${deck.name}”?',
                  message: 'This permanently deletes the deck, its ${s.total} cards and their review history.',
                );
                if (ok) await ref.read(fcRepositoryProvider).deleteDeck(deck.id);
              },
            ),
          ],
        ),
      );
    },
  );
}

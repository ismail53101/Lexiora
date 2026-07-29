import 'package:flutter/material.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_list.dart';

/// A tappable card representing one vocabulary list on the home screen.
class VocabularyListCard extends StatelessWidget {
  const VocabularyListCard({super.key, required this.list, required this.onTap});

  final VocabularyListSummary list;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String count = '${list.wordCount} '
        '${list.wordCount == 1 ? 'word' : 'words'}';
    final bool hasSubtitle =
        list.subtitle != null && list.subtitle!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: const Icon(Icons.menu_book_outlined),
        ),
        title: Text(
          list.title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasSubtitle) ...[
              Text(
                list.subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
            ],
            // On its own line so it's never the part that gets clipped —
            // the description above may wrap/truncate, the count never does.
            Text(
              count,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_topic.dart';
import 'package:lexiora/modules/grammar/domain/usecases/grammar_usecases.dart';
import 'package:lexiora/modules/grammar/presentation/providers/grammar_providers.dart';

/// A single row in a grammar navigation list. Branch nodes show a chevron and
/// drill in; leaf nodes show a completion check, an in-progress hint, and a
/// live favorite (★) toggle.
class GrammarTopicTile extends ConsumerWidget {
  const GrammarTopicTile({super.key, required this.topic, required this.onTap});

  final GrammarTopicSummary topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Icon(
          topic.isLeaf ? Icons.article_outlined : Icons.folder_outlined,
          color: scheme.onPrimaryContainer,
        ),
      ),
      title: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              topic.title,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (topic.isLeaf && topic.isCompleted) ...<Widget>[
            const SizedBox(width: 6),
            Icon(Icons.check_circle, size: 16, color: scheme.primary),
          ],
        ],
      ),
      subtitle: _subtitle(context),
      trailing: topic.isLeaf
          ? _FavoriteButton(topic: topic)
          : const Icon(Icons.chevron_right),
    );
  }

  Widget? _subtitle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? sub = topic.subtitle;
    if (topic.isLeaf && topic.isInProgress) {
      return Text('In progress',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary));
    }
    if (sub != null && sub.isNotEmpty) {
      return Text(sub,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    return null;
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.topic});

  final GrammarTopicSummary topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isFavorite = ref
        .watch(isLeafFavoriteProvider(topic.id))
        .maybeWhen(data: (bool v) => v, orElse: () => topic.isFavorite);
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? Colors.amber : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: isFavorite ? 'Remove from favorites' : 'Save to favorites',
      onPressed: () => ref.read(toggleLessonFavoriteProvider).call(
            FavoriteParams(leafId: topic.id, title: topic.title),
          ),
    );
  }
}

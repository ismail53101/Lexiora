import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/dictionary_usecases.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';
import 'package:lexiora/modules/dictionary/presentation/widgets/part_of_speech_chip.dart';

/// A single headword row in a search-results or favorites list. The trailing
/// star reflects the *live* saved state (so it stays in sync everywhere) and
/// toggles it on tap.
class DictionaryResultTile extends ConsumerWidget {
  const DictionaryResultTile({
    super.key,
    required this.result,
    required this.onTap,
  });

  final DictionaryResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool isFavorite = ref
        .watch(isWordFavoriteProvider(result.wordLower))
        .maybeWhen(data: (bool v) => v, orElse: () => result.isFavorite);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      title: Row(
        children: [
          Flexible(
            child: Text(
              result.word,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (result.partOfSpeech != null &&
              result.partOfSpeech!.isNotEmpty) ...[
            const SizedBox(width: 8),
            PartOfSpeechChip(partOfSpeech: result.partOfSpeech!),
          ],
          if (result.senseCount > 1) ...[
            const SizedBox(width: 6),
            Text(
              '+${result.senseCount - 1}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          result.meaning,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          color: isFavorite ? Colors.amber : theme.colorScheme.onSurfaceVariant,
        ),
        tooltip: isFavorite ? 'Remove from favorites' : 'Save to favorites',
        onPressed: () => ref.read(toggleWordFavoriteProvider).call(
              ToggleFavoriteParams(
                wordLower: result.wordLower,
                word: result.word,
                meaning: result.meaning,
                partOfSpeech: result.partOfSpeech,
              ),
            ),
      ),
    );
  }
}

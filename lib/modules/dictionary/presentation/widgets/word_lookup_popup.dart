import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/dictionary_usecases.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';
import 'package:lexiora/modules/dictionary/presentation/widgets/part_of_speech_chip.dart';

/// Normalizes a raw selected token to a dictionary lookup key: lowercased and
/// stripped of surrounding punctuation, keeping internal hyphens/apostrophes.
String normalizeLookupWord(String raw) {
  final String lower = raw.trim().toLowerCase();
  return lower.replaceAll(RegExp(r'^[^a-z]+|[^a-z]+$'), '');
}

/// Shows the lightweight reader dictionary popup for a single selected word.
///
/// Contents are intentionally minimal (per product spec): the word, its
/// meaning, and a single "Save to Vocabulary" action — nothing else.
Future<void> showWordLookup(BuildContext context, String selectedWord) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) => _WordLookupSheet(selectedWord: selectedWord),
  );
}

class _WordLookupSheet extends ConsumerWidget {
  const _WordLookupSheet({required this.selectedWord});

  final String selectedWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String wordLower = normalizeLookupWord(selectedWord);
    final AsyncValue<DictionaryResult?> lookup = wordLower.isEmpty
        ? const AsyncData<DictionaryResult?>(null)
        : ref.watch(wordLookupProvider(wordLower));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            lookup.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _NotFound(word: selectedWord.trim()),
              data: (DictionaryResult? r) => r == null
                  ? _NotFound(word: selectedWord.trim())
                  : _Found(result: r),
            ),
          ],
        ),
      ),
    );
  }
}

class _Found extends ConsumerWidget {
  const _Found({required this.result});

  final DictionaryResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool isSaved = ref
        .watch(isWordFavoriteProvider(result.wordLower))
        .maybeWhen(data: (bool v) => v, orElse: () => result.isFavorite);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected word
        Row(
          children: [
            Flexible(
              child: Text(
                result.word,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (result.partOfSpeech != null &&
                result.partOfSpeech!.isNotEmpty) ...[
              const SizedBox(width: 10),
              PartOfSpeechChip(partOfSpeech: result.partOfSpeech!),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // Meaning
        Text(
          result.meaning,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 20),
        // Save to Vocabulary
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: Icon(isSaved ? Icons.star : Icons.star_border),
            label: Text(isSaved ? 'Saved to Vocabulary' : 'Save to Vocabulary'),
            style: isSaved
                ? FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                  )
                : null,
            onPressed: () async {
              final ScaffoldMessengerState messenger =
                  ScaffoldMessenger.of(context);
              final bool nowSaved =
                  await ref.read(toggleWordFavoriteProvider).call(
                            ToggleFavoriteParams(
                              wordLower: result.wordLower,
                              word: result.word,
                              meaning: result.meaning,
                              partOfSpeech: result.partOfSpeech,
                            ),
                          ).then(
                        (r) => r.fold((_) => isSaved, (bool v) => v),
                      );
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    nowSaved
                        ? 'Saved “${result.word}” to vocabulary'
                        : 'Removed “${result.word}” from vocabulary',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          word.isEmpty ? 'No word selected' : word,
          style:
              theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Text(
          'No definition found in the offline dictionary.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

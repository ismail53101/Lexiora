import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/core/widgets/error_view.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/dictionary_usecases.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';
import 'package:lexiora/modules/dictionary/presentation/widgets/part_of_speech_chip.dart';
// Reuse the Translation module's repository (via its shared provider) so the
// Urdu meaning shown here is identical to the reader's Translate popup.
import 'package:lexiora/modules/translation/domain/entities/translation.dart';
import 'package:lexiora/modules/translation/presentation/providers/translation_providers.dart';

/// Full details for a single word: the headword, IPA (when available), a
/// favorite toggle, and every sense with its part of speech, meaning and
/// example sentence.
class WordDetailsPage extends ConsumerWidget {
  const WordDetailsPage({super.key, required this.wordLower});

  final String wordLower;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WordDetails?> detailsAsync =
        ref.watch(wordDetailsProvider(wordLower));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detailsAsync.maybeWhen(
            data: (WordDetails? d) => d?.word ?? 'Word',
            orElse: () => 'Word',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          detailsAsync.maybeWhen(
            data: (WordDetails? d) =>
                d == null ? const SizedBox.shrink() : _FavoriteAction(details: d),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => ErrorView(
          title: 'Could not open word',
          message: 'Something went wrong loading this word.',
          onRetry: () => ref.invalidate(wordDetailsProvider(wordLower)),
        ),
        data: (WordDetails? details) {
          if (details == null || details.senses.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Not found',
              message: 'This word is not in the offline dictionary.',
            );
          }
          return _DetailsView(details: details);
        },
      ),
    );
  }
}

class _FavoriteAction extends ConsumerWidget {
  const _FavoriteAction({required this.details});

  final WordDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isFavorite = ref
        .watch(isWordFavoriteProvider(details.wordLower))
        .maybeWhen(data: (bool v) => v, orElse: () => details.isFavorite);
    final DictionaryEntry? primary = details.primary;

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? Colors.amber : null,
      ),
      tooltip: isFavorite ? 'Remove from favorites' : 'Save to favorites',
      onPressed: primary == null
          ? null
          : () => ref.read(toggleWordFavoriteProvider).call(
                ToggleFavoriteParams(
                  wordLower: details.wordLower,
                  word: details.word,
                  meaning: primary.meaning,
                  partOfSpeech: primary.partOfSpeech,
                ),
              ),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.details});

  final WordDetails details;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? ipa = details.ipaPronunciation;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          details.word,
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (ipa != null && ipa.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '/$ipa/',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          details.senses.length == 1
              ? '1 meaning'
              : '${details.senses.length} meanings',
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < details.senses.length; i++)
          _SenseCard(index: i + 1, sense: details.senses[i]),
        // Urdu meaning (offline) shown directly BELOW the English definition,
        // when available. Sourced from the shared translation repository (same
        // as the reader's Translate); renders nothing when there is no Urdu.
        _UrduMeaningCard(wordLower: details.wordLower),
      ],
    );
  }
}

/// Shows the word's offline Urdu meaning, sourced from the **same** translation
/// repository (via [translationProvider]) that powers the reader's Translate
/// popup — so Urdu results are consistent in both places. No separate Urdu
/// store is used. Renders nothing while loading or when no Urdu exists.
class _UrduMeaningCard extends ConsumerWidget {
  const _UrduMeaningCard({required this.wordLower});

  final String wordLower;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Translation?> urdu =
        ref.watch(translationProvider((word: wordLower, lang: 'ur')));
    final String? text =
        urdu.maybeWhen(data: (Translation? t) => t?.text, orElse: () => null);
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.translate,
                    size: 16, color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Urdu · اردو',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: theme.textTheme.headlineSmall?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SenseCard extends StatelessWidget {
  const _SenseCard({required this.index, required this.sense});

  final int index;
  final DictionaryEntry sense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? example = sense.exampleSentence;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '$index',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (sense.partOfSpeech != null &&
                    sense.partOfSpeech!.isNotEmpty)
                  PartOfSpeechChip(partOfSpeech: sense.partOfSpeech!),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              sense.meaning,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
            ),
            if (example != null && example.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        example,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

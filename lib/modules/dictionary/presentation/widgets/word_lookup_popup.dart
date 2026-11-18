import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/dictionary_usecases.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';
import 'package:lexiora/modules/dictionary/presentation/widgets/part_of_speech_chip.dart';

String normalizeLookupWord(String raw) {
  final String lower = raw.trim().toLowerCase();
  return lower.replaceAll(RegExp(r'^[^a-z]+|[^a-z]+$'), '');
}

/// Reader lookup is strictly offline-first:
/// local dictionary -> AI dictionary only when the local word is absent.
/// No generic online dictionary/translation is used for a missing word.
Future<void> showWordLookup(BuildContext context, String selectedWord) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) =>
        _WordLookupSheet(selectedWord: selectedWord),
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
              error: (_, _) => _AiFallback(word: wordLower),
              data: (DictionaryResult? r) =>
                  r == null ? _AiFallback(word: wordLower) : _Found(result: r),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiFallback extends ConsumerWidget {
  const _AiFallback({required this.word});

  final String word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (word.isEmpty) return const _NotFound(word: '');

    final AsyncValue<AiWordProfile?> ai =
        ref.watch(wordAiEnrichmentProvider(word));

    return ai.when(
      loading: () => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            word,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'Getting an AI dictionary meaning…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      error: (_, _) => _NotFound(word: word),
      data: (AiWordProfile? profile) => profile == null
          ? _NotFound(word: word)
          : _AiFound(profile: profile),
    );
  }
}

class _AiFound extends ConsumerWidget {
  const _AiFound({required this.profile});

  final AiWordProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String wordLower = profile.word.trim().toLowerCase();
    final bool isSaved = ref
        .watch(isWordFavoriteProvider(wordLower))
        .maybeWhen(data: (bool v) => v, orElse: () => false);

    final String english =
        profile.englishDefinition?.trim().isNotEmpty == true
            ? profile.englishDefinition!.trim()
            : 'No English definition returned.';
    final String urdu = profile.urduMeanings.isNotEmpty
        ? profile.urduMeanings.join('، ')
        : 'اردو معنی دستیاب نہیں۔';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                profile.word,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (profile.partOfSpeech?.trim().isNotEmpty == true) ...[
              const SizedBox(width: 10),
              PartOfSpeechChip(partOfSpeech: profile.partOfSpeech!.trim()),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          profile.source == 'stands4' ? 'ONLINE DICTIONARY' : 'AI DICTIONARY',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'ENGLISH MEANING',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          english,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 16),
        Text(
          'URDU',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            urdu,
            textAlign: TextAlign.right,
            style: theme.textTheme.titleLarge?.copyWith(height: 1.35),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: Icon(isSaved ? Icons.star : Icons.star_border),
            label: Text(
              isSaved ? 'Saved to Vocabulary' : 'Save to Vocabulary',
            ),
            onPressed: () async {
              final ScaffoldMessengerState messenger =
                  ScaffoldMessenger.of(context);
              final String meaningForVocabulary = urdu == 'اردو معنی دستیاب نہیں۔'
                  ? english
                  : '$english — $urdu';
              final bool nowSaved = await ref
                  .read(toggleWordFavoriteProvider)
                  .call(
                    ToggleFavoriteParams(
                      wordLower: wordLower,
                      word: profile.word,
                      meaning: meaningForVocabulary,
                      partOfSpeech: profile.partOfSpeech,
                    ),
                  )
                  .then(
                    (Result<bool> r) =>
                        r.fold((_) => isSaved, (bool v) => v),
                  );

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    nowSaved
                        ? 'Saved “${profile.word}” to vocabulary'
                        : 'Removed “${profile.word}” from vocabulary',
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
        Text(
          result.meaning,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: Icon(isSaved ? Icons.star : Icons.star_border),
            label: Text(
              isSaved ? 'Saved to Vocabulary' : 'Save to Vocabulary',
            ),
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
                        (Result<bool> r) =>
                            r.fold((_) => isSaved, (bool v) => v),
                      );
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    nowSaved
                        ? 'Saved “${result.word}” to vocabulary'
                        : 'Removed “${result.word}” from vocabulary',
                  ),
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
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Text(
          'No definition found. AI dictionary could not provide a reliable meaning.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

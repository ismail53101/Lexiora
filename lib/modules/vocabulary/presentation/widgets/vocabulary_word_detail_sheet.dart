import 'package:flutter/material.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';
import 'package:lexiora/modules/vocabulary/presentation/widgets/vocab_pronunciation_button.dart';

/// Shows [word]'s full detail — the complete English and Urdu meanings, with
/// no line clamping — so a longer meaning that gets cut off with "…" in the
/// fixed-height browse list ([VocabularyWordCard]) is always fully readable
/// one tap away.
Future<void> showVocabularyWordDetail(BuildContext context, VocabularyWord word) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _VocabularyWordDetailSheet(word: word),
  );
}

class _VocabularyWordDetailSheet extends StatelessWidget {
  const _VocabularyWordDetailSheet({required this.word});

  final VocabularyWord word;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: <Widget>[
                      Text(
                        word.word,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (word.partOfSpeech != null &&
                          word.partOfSpeech!.isNotEmpty)
                        _Chip(word.partOfSpeech!),
                      if (word.ipa != null && word.ipa!.isNotEmpty)
                        Text(
                          word.ipa!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                VocabPronunciationButton(text: word.word),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'MEANING',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            // No maxLines/overflow here — this is the full, untruncated text.
            Text(
              word.englishMeaning,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            Text(
              'URDU MEANING',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                word.urduMeaning,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

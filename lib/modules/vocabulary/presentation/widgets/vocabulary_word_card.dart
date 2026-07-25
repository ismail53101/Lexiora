import 'package:flutter/material.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';
import 'package:lexiora/modules/vocabulary/presentation/widgets/vocab_pronunciation_button.dart';

/// A beautiful, fixed-height Material 3 vocabulary card:
/// word + IPA + part-of-speech chip, the Urdu meaning (right-to-left) and a
/// short English meaning, with a tap-to-play pronunciation button.
///
/// Kept to a predictable height so the browse list uses a fixed extent (fast
/// scrolling + exact A–Z jumps). Text lines clamp to avoid overflow.
class VocabularyWordCard extends StatelessWidget {
  const VocabularyWordCard({super.key, required this.word});

  final VocabularyWord word;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          word.word,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (word.partOfSpeech != null &&
                          word.partOfSpeech!.isNotEmpty) ...<Widget>[
                        const SizedBox(width: 8),
                        _PosChip(word.partOfSpeech!),
                      ],
                      if (word.ipa != null && word.ipa!.isNotEmpty) ...<Widget>[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            word.ipa!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          word.englishMeaning,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          word.urduMeaning,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            VocabPronunciationButton(text: word.word),
          ],
        ),
      ),
    );
  }
}

class _PosChip extends StatelessWidget {
  const _PosChip(this.pos);
  final String pos;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        pos,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

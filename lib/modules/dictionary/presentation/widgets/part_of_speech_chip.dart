import 'package:flutter/material.dart';

/// A small, muted chip labelling a sense's grammatical category (e.g. "noun").
class PartOfSpeechChip extends StatelessWidget {
  const PartOfSpeechChip({super.key, required this.partOfSpeech});

  final String partOfSpeech;

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
        partOfSpeech,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

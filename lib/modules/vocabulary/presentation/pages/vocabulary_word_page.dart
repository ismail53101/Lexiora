import 'package:flutter/material.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';
import 'package:lexiora/modules/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:lexiora/modules/vocabulary/presentation/widgets/vocab_pronunciation_button.dart';

class VocabularyWordPage extends StatelessWidget {
  const VocabularyWordPage({super.key, required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word of the Day')),
      body: FutureBuilder<VocabularyWord?>(
        future: sl<VocabularyRepository>().lookupWord(word.toLowerCase()),
        builder: (BuildContext context, AsyncSnapshot<VocabularyWord?> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final VocabularyWord? value = snap.data;
          if (value == null) {
            return const Center(child: Text('This vocabulary word is unavailable.'));
          }
          return _WordContent(word: value);
        },
      ),
    );
  }
}

class _WordContent extends StatelessWidget {
  const _WordContent({required this.word});

  final VocabularyWord word;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                word.word,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            VocabPronunciationButton(text: word.word),
          ],
        ),
        if (word.partOfSpeech != null && word.partOfSpeech!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            word.partOfSpeech!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 28),
        const _Heading('MEANING'),
        const SizedBox(height: 6),
        Text(word.englishMeaning, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 22),
        const _Heading('URDU MEANING'),
        const SizedBox(height: 6),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            word.urduMeaning,
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
    );
  }
}

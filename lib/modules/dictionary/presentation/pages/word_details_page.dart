import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/error_view.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/dictionary_usecases.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';
import 'package:lexiora/modules/dictionary/presentation/widgets/part_of_speech_chip.dart';
import 'package:lexiora/modules/dictionary/presentation/widgets/pronunciation_button.dart';
import 'package:lexiora/modules/translation/domain/entities/translation.dart';
import 'package:lexiora/modules/translation/domain/entities/translation_outcome.dart';
import 'package:lexiora/modules/translation/presentation/providers/translation_providers.dart';

/// A professional, offline-first word profile for exam learners. Sections are
/// rendered in the mandated order: Meaning (same-sense Urdu + English),
/// Pronunciation (IPA + audio + part of speech), Other Common Meanings,
/// Synonyms & Antonyms, Usage, Collocations, Word Forms / Related Words, Idioms,
/// Exam Note. Any section whose data cannot be shown reliably is hidden.
class WordDetailsPage extends ConsumerStatefulWidget {
  const WordDetailsPage({super.key, required this.wordLower});

  final String wordLower;

  @override
  ConsumerState<WordDetailsPage> createState() => _WordDetailsPageState();
}

class _WordDetailsPageState extends ConsumerState<WordDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(dictionaryRepositoryProvider)
            .addSearchHistory(widget.wordLower),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<WordProfile> profileAsync =
        ref.watch(wordProfileProvider(widget.wordLower));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          profileAsync.maybeWhen(
            data: (WordProfile p) => p.displayWord,
            orElse: () => widget.wordLower,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy word info',
            onPressed: () => _copy(
              context,
              profileAsync.maybeWhen(
                data: (WordProfile p) => p,
                orElse: () => null,
              ),
            ),
          ),
          _BookmarkAction(wordLower: widget.wordLower, profileAsync: profileAsync),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => ErrorView(
          title: 'Could not open word',
          message: 'Something went wrong loading this word.',
          onRetry: () => ref.invalidate(wordProfileProvider(widget.wordLower)),
        ),
        data: (WordProfile p) => _ProfileView(profile: p),
      ),
    );
  }

  void _copy(BuildContext context, WordProfile? profile) {
    if (profile == null) return;
    final ExamWordData? e = profile.exam;
    final String? urdu = (e != null && e.urduMeanings.isNotEmpty)
        ? e.urduMeanings.join('، ')
        : ref
            .read(hybridTranslationProvider(
              (word: profile.wordLower, lang: 'ur'),
            ))
            .maybeWhen(
              data: (TranslationOutcome o) => o.translation?.text,
              orElse: () => null,
            );
    Clipboard.setData(ClipboardData(text: _buildCopyText(profile, urdu)));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied word info')));
  }

  String _buildCopyText(WordProfile p, String? urdu) {
    final ExamWordData? e = p.exam;
    final StringBuffer b = StringBuffer()..writeln(p.displayWord);
    if (urdu != null && urdu.isNotEmpty) b.writeln(urdu);
    final String? def = p.englishDefinition;
    if (def != null && def.isNotEmpty) b.writeln(def);
    final String? pron = p.pronunciation;
    if (pron != null && pron.isNotEmpty) b.writeln('Pronunciation: $pron');
    final String? pos = p.partOfSpeech;
    if (pos != null && pos.isNotEmpty) b.writeln('Part of speech: $pos');
    if (e != null) {
      if (e.synonyms.isNotEmpty) b.writeln('Synonyms: ${e.synonyms.join(', ')}');
      if (e.antonyms.isNotEmpty) b.writeln('Antonyms: ${e.antonyms.join(', ')}');
      final WordUsage? u = e.usage;
      if (u != null) {
        b.writeln('Usage (${u.context}): ${u.english}');
        if (u.urdu.isNotEmpty) b.writeln(u.urdu);
      }
      if (e.collocations.isNotEmpty) {
        b.writeln('Collocations: ${e.collocations.join(', ')}');
      }
      if (e.examNote != null && e.examNote!.isNotEmpty) {
        b.writeln('Exam note: ${e.examNote}');
      }
    }
    return b.toString().trim();
  }
}

class _BookmarkAction extends ConsumerWidget {
  const _BookmarkAction({required this.wordLower, required this.profileAsync});

  final String wordLower;
  final AsyncValue<WordProfile> profileAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSaved = ref
        .watch(isWordFavoriteProvider(wordLower))
        .maybeWhen(data: (bool v) => v, orElse: () => false);
    final WordProfile? p =
        profileAsync.maybeWhen(data: (WordProfile v) => v, orElse: () => null);
    return IconButton(
      icon: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_border,
        color: isSaved ? Colors.amber : null,
      ),
      tooltip: isSaved ? 'Remove bookmark' : 'Bookmark word',
      onPressed: p == null
          ? null
          : () => ref.read(toggleWordFavoriteProvider).call(
                ToggleFavoriteParams(
                  wordLower: p.wordLower,
                  word: p.displayWord,
                  meaning: p.englishDefinition ?? p.displayWord,
                  partOfSpeech: p.partOfSpeech,
                ),
              ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile});

  final WordProfile profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ExamWordData? e = profile.exam;
    final bool hasCuratedUrdu = e != null && e.urduMeanings.isNotEmpty;

    // Word Forms / Related Words: curated forms first, then derived family
    // words, deduped and excluding the headword itself.
    final List<String> forms = <String>[];
    final Set<String> seen = <String>{profile.wordLower};
    for (final String w in e?.wordForms ?? const <String>[]) {
      if (seen.add(w.toLowerCase())) forms.add(w);
    }
    for (final String w in profile.relatedWords) {
      if (seen.add(w.toLowerCase())) forms.add(w);
    }

    final List<Widget> otherMeanings = _buildOtherMeanings(context, profile);
    final bool showPronunciation =
        profile.existsLocally || profile.pronunciation != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        // Word + offline status.
        Text(
          profile.displayWord,
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _OfflineStatusBadge(
          wordLower: profile.wordLower,
          hasCuratedUrdu: hasCuratedUrdu,
        ),
        const SizedBox(height: 12),

        // 1) Meaning (Urdu + English definition, same sense).
        _Section(
          icon: Icons.translate,
          title: 'Meaning',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _UrduBlock(
                wordLower: profile.wordLower,
                curated: e?.urduMeanings ?? const <String>[],
              ),
              if (profile.englishDefinition != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  profile.englishDefinition!,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                ),
              ],
            ],
          ),
        ),

        // 2) Pronunciation + Audio + Part of Speech.
        if (showPronunciation) _PronunciationSection(profile: profile),

        // 3) Other Common Meanings (only if applicable).
        if (otherMeanings.isNotEmpty)
          _Section(
            icon: Icons.account_tree_outlined,
            title: 'Other Common Meanings',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: otherMeanings,
            ),
          ),

        // 4) Synonyms & Antonyms.
        if (e != null && (e.synonyms.isNotEmpty || e.antonyms.isNotEmpty))
          _Section(
            icon: Icons.swap_horiz,
            title: 'Synonyms & Antonyms',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (e.synonyms.isNotEmpty)
                  _ChipGroup(label: 'Synonyms', items: e.synonyms),
                if (e.antonyms.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _ChipGroup(label: 'Antonyms', items: e.antonyms, tonal: false),
                ],
              ],
            ),
          ),

        // 5) Usage.
        if (e?.usage != null)
          _UsageSection(word: profile.displayWord, usage: e!.usage!),

        // 6) Common Collocations.
        if (e != null && e.collocations.isNotEmpty)
          _Section(
            icon: Icons.link,
            title: 'Common Collocations',
            child: _ChipGroup(label: '', items: e.collocations),
          ),

        // 7) Word Forms / Related Words (merged, family only).
        if (forms.isNotEmpty)
          _Section(
            icon: Icons.category_outlined,
            title: 'Word Forms & Related Words',
            child: _RelatedWords(words: forms),
          ),

        // 8) Idioms / phrasal verbs / phrases.
        if (e != null && e.idioms.isNotEmpty)
          _Section(
            icon: Icons.format_quote,
            title: 'Idioms & Phrases',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final String idiom in e.idioms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $idiom',
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.3)),
                  ),
              ],
            ),
          ),

        // 9) Exam Note.
        if (e != null && e.examNote != null && e.examNote!.isNotEmpty)
          _Section(
            icon: Icons.lightbulb_outline,
            title: 'Exam Note',
            accent: theme.colorScheme.tertiary,
            child: Text(e.examNote!,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
          ),

        if (!profile.existsLocally)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No offline entry for this word yet. Its Urdu meaning is fetched '
              'and saved automatically when you are online.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  /// Curated other meanings when available; otherwise the base dictionary's
  /// additional senses (so multi-sense words keep that information).
  List<Widget> _buildOtherMeanings(BuildContext context, WordProfile profile) {
    final ExamWordData? e = profile.exam;
    if (e != null && e.otherMeanings.isNotEmpty) {
      return <Widget>[
        for (final OtherMeaning m in e.otherMeanings) _OtherMeaningRow(meaning: m),
      ];
    }
    final WordDetails? base = profile.base;
    if (base != null && base.senses.length > 1) {
      final ThemeData theme = Theme.of(context);
      return <Widget>[
        for (final DictionaryEntry s in base.senses.skip(1))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (s.partOfSpeech != null && s.partOfSpeech!.isNotEmpty)
                  PartOfSpeechChip(partOfSpeech: s.partOfSpeech!),
                const SizedBox(height: 4),
                Text(s.meaning,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.35)),
              ],
            ),
          ),
      ];
    }
    return const <Widget>[];
  }
}

class _PronunciationSection extends StatelessWidget {
  const _PronunciationSection({required this.profile});

  final WordProfile profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ExamWordData? e = profile.exam;
    final String? uk = e?.pronunciationUk;
    final String? us = e?.pronunciationUs;
    final String? single = profile.pronunciation;

    return _Section(
      icon: Icons.record_voice_over_outlined,
      title: 'Pronunciation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (uk != null || us != null) ...<Widget>[
            if (uk != null) _IpaLine(accent: 'UK', ipa: uk),
            if (us != null) _IpaLine(accent: 'US', ipa: us),
          ] else if (single != null)
            Text(single, style: theme.textTheme.titleMedium),
          if (profile.partOfSpeech != null) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text('Part of Speech  ',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                PartOfSpeechChip(partOfSpeech: profile.partOfSpeech!),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Audio buttons self-hide when that accent's voice is unavailable.
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              PronunciationButton(
                text: profile.displayWord,
                languageCode: 'en-US',
                label: 'US',
              ),
              PronunciationButton(
                text: profile.displayWord,
                languageCode: 'en-GB',
                label: 'UK',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IpaLine extends StatelessWidget {
  const _IpaLine({required this.accent, required this.ipa});

  final String accent;
  final String ipa;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Text('$accent:',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Text(ipa, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// 🟢 Available Offline / 🌐 Retrieved Online • Saved Offline.
class _OfflineStatusBadge extends ConsumerWidget {
  const _OfflineStatusBadge({
    required this.wordLower,
    required this.hasCuratedUrdu,
  });

  final String wordLower;
  final bool hasCuratedUrdu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool online = false;
    if (!hasCuratedUrdu) {
      online = ref
          .watch(hybridTranslationProvider((word: wordLower, lang: 'ur')))
          .maybeWhen(
            data: (TranslationOutcome o) =>
                o.status == TranslationOutcomeStatus.online,
            orElse: () => false,
          );
    }
    final ThemeData theme = Theme.of(context);
    final Color bg = online
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.secondaryContainer;
    final Color fg = online
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onSecondaryContainer;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          online ? '🌐 Retrieved Online • Saved Offline' : '🟢 Available Offline',
          style: theme.textTheme.labelMedium
              ?.copyWith(color: fg, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Renders the Urdu meaning(s): the curated ordered list when available, else
/// the hybrid (offline-first, cached online fallback) result.
class _UrduBlock extends ConsumerWidget {
  const _UrduBlock({required this.wordLower, required this.curated});

  final String wordLower;
  final List<String> curated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (curated.isNotEmpty) {
      return _urduList(context, curated);
    }
    final AsyncValue<TranslationOutcome> async =
        ref.watch(hybridTranslationProvider((word: wordLower, lang: 'ur')));
    return async.when(
      loading: () => Row(
        children: <Widget>[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text('Fetching Urdu meaning…',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
      error: (_, _) => _hint(context),
      data: (TranslationOutcome o) {
        final Translation? t = o.translation;
        if (t != null) {
          return _urduList(context, <String>[t.text],
              savedOnline: t.source == TranslationSource.online);
        }
        return _hint(context);
      },
    );
  }

  Widget _urduList(BuildContext context, List<String> items,
      {bool savedOnline = false}) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final String u in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    u,
                    style: theme.textTheme.headlineSmall?.copyWith(height: 1.5),
                  ),
                ),
            ],
          ),
        ),
        if (savedOnline) ...<Widget>[
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Icon(Icons.cloud_done_outlined,
                  size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text('Saved for offline use',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _hint(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      'Connect to the internet to load and save the Urdu meaning.',
      style: theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

class _UsageSection extends StatelessWidget {
  const _UsageSection({required this.word, required this.usage});

  final String word;
  final WordUsage usage;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return _Section(
      icon: Icons.article_outlined,
      title: 'Usage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (usage.context.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(usage.context,
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 12),
          _HighlightedSentence(sentence: usage.english, word: word),
          if (usage.urdu.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                usage.urdu,
                style: theme.textTheme.titleMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bolds the searched word (and simple inflections) inside a sentence.
class _HighlightedSentence extends StatelessWidget {
  const _HighlightedSentence({required this.sentence, required this.word});

  final String sentence;
  final String word;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base = theme.textTheme.bodyLarge!.copyWith(height: 1.45);
    final TextStyle hi = base.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.primary,
    );
    final String w = word.trim().toLowerCase();
    final String stem = w.length >= 5 ? w.substring(0, w.length - 2) : w;
    final RegExp re =
        RegExp('(${RegExp.escape(stem)}\\w*)', caseSensitive: false);

    final List<TextSpan> spans = <TextSpan>[];
    int last = 0;
    for (final RegExpMatch m in re.allMatches(sentence)) {
      if (m.start > last) {
        spans.add(TextSpan(text: sentence.substring(last, m.start)));
      }
      spans.add(TextSpan(text: m.group(0), style: hi));
      last = m.end;
    }
    if (last < sentence.length) {
      spans.add(TextSpan(text: sentence.substring(last)));
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}

class _OtherMeaningRow extends StatelessWidget {
  const _OtherMeaningRow({required this.meaning});

  final OtherMeaning meaning;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (meaning.urdu.isNotEmpty)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(meaning.urdu.join('، '),
                  style: theme.textTheme.titleMedium?.copyWith(height: 1.5)),
            ),
          if (meaning.english != null && meaning.english!.isNotEmpty)
            Text(meaning.english!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.label, required this.items, this.tonal = true});

  final String label;
  final List<String> items;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color bg = tonal
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.errorContainer;
    final Color fg = tonal
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onErrorContainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String item in items)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(item,
                    style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
              ),
          ],
        ),
      ],
    );
  }
}

class _RelatedWords extends StatelessWidget {
  const _RelatedWords({required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final String w in words)
          ActionChip(
            label: Text(w),
            labelStyle: theme.textTheme.bodyMedium,
            onPressed: () =>
                context.push(AppRoutes.dictionaryWord(w.toLowerCase())),
          ),
      ],
    );
  }
}

/// Consistent titled section card.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.accent,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color header = accent ?? theme.colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 18, color: header),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700, color: header)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

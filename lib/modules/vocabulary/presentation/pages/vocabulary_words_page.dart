import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/core/widgets/error_view.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_list.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';
import 'package:lexiora/modules/vocabulary/domain/vocabulary_grouping.dart';
import 'package:lexiora/modules/vocabulary/presentation/providers/vocabulary_providers.dart';
import 'package:lexiora/modules/vocabulary/presentation/widgets/alphabet_rail.dart';
import 'package:lexiora/modules/vocabulary/presentation/widgets/vocabulary_word_card.dart';
import 'package:lexiora/modules/vocabulary/presentation/widgets/vocabulary_word_detail_sheet.dart';

const double _kHeaderExtent = 44;
const double _kItemExtent = 120;

/// Browse one vocabulary list A–Z with sticky letter headers, a quick-jump
/// alphabet rail, and instant search (English word or Urdu meaning).
class VocabularyWordsPage extends ConsumerStatefulWidget {
  const VocabularyWordsPage({super.key, required this.listId});

  final String listId;

  @override
  ConsumerState<VocabularyWordsPage> createState() =>
      _VocabularyWordsPageState();
}

class _VocabularyWordsPageState extends ConsumerState<VocabularyWordsPage> {
  final TextEditingController _field = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Reset any query carried over from a previously opened list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vocabularyQueryProvider.notifier).set('');
    });
  }

  @override
  void dispose() {
    _field.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _jumpTo(List<VocabularySection> sections, String letter) {
    double offset = 0;
    for (final VocabularySection s in sections) {
      if (s.letter == letter) break;
      offset += _kHeaderExtent + s.words.length * _kItemExtent;
    }
    if (_scroll.hasClients) {
      _scroll.animateTo(
        math.min(offset, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _titleFor() => ref.watch(vocabularyListsProvider).maybeWhen(
        data: (List<VocabularyListSummary> ls) {
          for (final VocabularyListSummary l in ls) {
            if (l.id == widget.listId) return l.title;
          }
          return 'Vocabulary';
        },
        orElse: () => 'Vocabulary',
      );

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<VocabularyWord>> wordsAsync =
        ref.watch(vocabularyWordsProvider(widget.listId));
    final String query = ref.watch(vocabularyQueryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(), overflow: TextOverflow.ellipsis)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _field,
              textInputAction: TextInputAction.search,
              onChanged: (String v) =>
                  ref.read(vocabularyQueryProvider.notifier).set(v),
              decoration: InputDecoration(
                hintText: 'Search word or Urdu meaning',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear',
                        onPressed: () {
                          _field.clear();
                          ref.read(vocabularyQueryProvider.notifier).set('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: wordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => ErrorView(
                title: 'Could not load words',
                message: 'Something went wrong loading this list.',
                onRetry: () =>
                    ref.invalidate(vocabularyWordsProvider(widget.listId)),
              ),
              data: (List<VocabularyWord> all) {
                if (all.isEmpty) {
                  return const EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'No words yet',
                    message: 'This list has no words available offline.',
                  );
                }
                final String q = query.trim();
                if (q.isNotEmpty) {
                  return _SearchResults(
                    words: filterVocabulary(all, q),
                  );
                }
                return _BrowseView(
                  sections: groupByLetter(all),
                  scroll: _scroll,
                  onJump: _jumpTo,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.words});
  final List<VocabularyWord> words;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No matches',
        message: 'Try another word, in English or Urdu.',
      );
    }
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: words.length,
      itemBuilder: (BuildContext context, int i) =>
          VocabularyWordCard(
            word: words[i],
            onTap: () => showVocabularyWordDetail(context, words[i]),
          ),
    );
  }
}

class _BrowseView extends StatelessWidget {
  const _BrowseView({
    required this.sections,
    required this.scroll,
    required this.onJump,
  });

  final List<VocabularySection> sections;
  final ScrollController scroll;
  final void Function(List<VocabularySection>, String) onJump;

  @override
  Widget build(BuildContext context) {
    final Set<String> present =
        sections.map((VocabularySection s) => s.letter).toSet();
    return Stack(
      children: <Widget>[
        CustomScrollView(
          controller: scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: <Widget>[
            for (final VocabularySection s in sections)
              SliverMainAxisGroup(
                slivers: <Widget>[
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _LetterHeaderDelegate(s.letter),
                  ),
                  SliverFixedExtentList(
                    itemExtent: _kItemExtent,
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int i) =>
                          VocabularyWordCard(
                            word: s.words[i],
                            onTap: () =>
                                showVocabularyWordDetail(context, s.words[i]),
                          ),
                      childCount: s.words.length,
                    ),
                  ),
                ],
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: 22,
          child: AlphabetRail(
            presentLetters: present,
            onLetter: (String letter) => onJump(sections, letter),
          ),
        ),
      ],
    );
  }
}

class _LetterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _LetterHeaderDelegate(this.letter);
  final String letter;

  @override
  double get minExtent => _kHeaderExtent;
  @override
  double get maxExtent => _kHeaderExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final ThemeData theme = Theme.of(context);
    return Container(
      height: _kHeaderExtent,
      color: theme.colorScheme.surface,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Text(
        letter,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LetterHeaderDelegate oldDelegate) =>
      oldDelegate.letter != letter;
}

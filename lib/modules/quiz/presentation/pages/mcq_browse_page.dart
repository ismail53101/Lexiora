import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_repository.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';

/// Study-mode MCQ browser (Phase v0.12.0).
///
/// Mirrors the classic "All MCQs" reference layout: a scrollable list of
/// question cards where the **correct answer is highlighted inline** — a
/// learning surface, so the answer is always visible without tapping. The
/// timed stage ladder (answers hidden) lives under the Quiz card instead.
class McqBrowsePage extends ConsumerStatefulWidget {
  const McqBrowsePage({
    super.key,
    required this.subjectId,
    this.topicId,
    this.title,
  });

  final String subjectId;
  final String? topicId;
  final String? title;

  @override
  ConsumerState<McqBrowsePage> createState() => _McqBrowsePageState();
}

class _McqBrowsePageState extends ConsumerState<McqBrowsePage> {
  static const int _pageSize = 25;

  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  final List<QuizQuestion> _questions = <QuizQuestion>[];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _error = false;

  String _query = '';
  QuizDifficulty? _difficulty;
  QuestionType? _type;
  bool _onlyBookmarked = false;

  bool get _hasActiveFilters =>
      _query.trim().isNotEmpty ||
      _difficulty != null ||
      _type != null ||
      _onlyBookmarked;

  QuizFilter get _filter => QuizFilter(
        subjectId: widget.subjectId,
        topicId: widget.topicId,
        query: _query,
        difficulty: _difficulty,
        type: _type,
        onlyBookmarked: _onlyBookmarked,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirst());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final QuizRepository repo = ref.read(quizRepositoryProvider);
      final int total = await repo.countQuestions(_filter);
      final List<QuizQuestion> qs =
          await repo.questions(_filter, limit: _pageSize, offset: 0);
      if (!mounted) return;
      setState(() {
        _total = total;
        _questions
          ..clear()
          ..addAll(qs);
        _hasMore = qs.length < total;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final QuizRepository repo = ref.read(quizRepositoryProvider);
      final List<QuizQuestion> qs = await repo.questions(
        _filter,
        limit: _pageSize,
        offset: _questions.length,
      );
      if (!mounted) return;
      setState(() {
        _questions.addAll(qs);
        _hasMore = _questions.length < _total;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _toggleBookmark(int index) async {
    final QuizQuestion q = _questions[index];
    final bool next = !q.bookmarked;
    await ref.read(quizRepositoryProvider).setBookmarked(q.id, next);
    if (!mounted) return;
    setState(() => _questions[index] = q.copyWith(bookmarked: next));
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value);
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadFirst();
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    setState(() => _query = '');
    _loadFirst();
  }

  void _applyFilters() {
    _debounce?.cancel();
    _loadFirst();
  }

  void _resetFilters() {
    _debounce?.cancel();
    _search.clear();
    setState(() {
      _query = '';
      _difficulty = null;
      _type = null;
      _onlyBookmarked = false;
    });
    _loadFirst();
  }

  Widget _typeChip() {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<QuestionType?>(
        onSelected: (QuestionType? t) {
          setState(() => _type = t);
          _applyFilters();
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<QuestionType?>>[
          const PopupMenuItem<QuestionType?>(child: Text('Any type')),
          for (final QuestionType t in QuestionType.values)
            PopupMenuItem<QuestionType?>(value: t, child: Text(t.label)),
        ],
        child: Chip(
          label: Text(_type == null ? 'Type' : _type!.shortLabel),
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
          backgroundColor:
              _type == null ? null : theme.colorScheme.secondaryContainer,
        ),
      ),
    );
  }

  Widget _difficultyChip() {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<QuizDifficulty?>(
        onSelected: (QuizDifficulty? d) {
          setState(() => _difficulty = d);
          _applyFilters();
        },
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<QuizDifficulty?>>[
          const PopupMenuItem<QuizDifficulty?>(child: Text('Any')),
          for (final QuizDifficulty d in QuizDifficulty.values)
            PopupMenuItem<QuizDifficulty?>(value: d, child: Text(d.label)),
        ],
        child: Chip(
          label: Text(
              _difficulty == null ? 'Difficulty' : _difficulty!.label),
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
          backgroundColor: _difficulty == null
              ? null
              : theme.colorScheme.secondaryContainer,
        ),
      ),
    );
  }

  bool _nearBottom(ScrollNotification n) {
    if (n.metrics.maxScrollExtent == 0) return false;
    return n.metrics.pixels >= n.metrics.maxScrollExtent - 600;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'MCQs')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search questions…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: <Widget>[
                _typeChip(),
                _difficultyChip(),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Bookmarked'),
                    selected: _onlyBookmarked,
                    onSelected: (bool v) {
                      setState(() => _onlyBookmarked = v);
                      _applyFilters();
                    },
                  ),
                ),
                if (_hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Reset'),
                      onPressed: _resetFilters,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error
                    ? EmptyState(
                        icon: Icons.error_outline,
                        title: 'Could not load questions',
                        message: 'Please try again.',
                        action: FilledButton(
                          onPressed: _loadFirst,
                          child: const Text('Retry'),
                        ),
                      )
                    : _questions.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off_outlined,
                            title: _hasActiveFilters
                                ? 'No matches'
                                : 'No questions yet',
                            message: _hasActiveFilters
                                ? 'No questions match your search or filters.'
                                : 'Questions for this selection are added '
                                    'from the published content.',
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification n) {
                              if (_nearBottom(n)) unawaited(_loadMore());
                              return false;
                            },
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _questions.length + 2,
                              itemBuilder: (BuildContext context, int index) {
                                if (index == 0) {
                                  return _HeaderBanner(
                                    count: _total,
                                    scoped: widget.topicId != null,
                                    filtered: _hasActiveFilters,
                                  );
                                }
                                if (index == _questions.length + 1) {
                                  return _Footer(
                                      loading: _loadingMore,
                                      hasMore: _hasMore);
                                }
                                final int qi = index - 1;
                                return _McqCard(
                                  question: _questions[qi],
                                  number: qi + 1,
                                  onBookmark: () => _toggleBookmark(qi),
                                ).animate(
                                  delay: Duration(
                                      milliseconds: 20 * (qi < 6 ? qi : 6)),
                                ).fadeIn(duration: 220.ms);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

/// "X questions · answers shown" banner pinned above the card list.
class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({
    required this.count,
    required this.scoped,
    required this.filtered,
  });

  final int count;
  final bool scoped;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.visibility_outlined,
              size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              filtered
                  ? '$count matching · correct answers shown'
                  : '$count questions · correct answers shown',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          if (scoped)
            Icon(Icons.filter_alt_outlined,
                size: 18, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.loading, required this.hasMore});

  final bool loading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : hasMore
                ? const SizedBox.shrink()
                : Text(
                    'End of questions',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
      ),
    );
  }
}

/// One question card. The correct option is always highlighted — no tapping.
class _McqCard extends StatelessWidget {
  const _McqCard({
    required this.question,
    required this.number,
    required this.onBookmark,
  });

  final QuizQuestion question;
  final int number;
  final VoidCallback onBookmark;

  static const String _letters = 'ABCDEFGH';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final QuizQuestion q = question;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                QuestionTypeChip(type: q.type),
                if (q.difficulty != QuizDifficulty.none) ...<Widget>[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      q.difficulty.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: Icon(
                    q.bookmarked ? Icons.star_rounded : Icons.star_border,
                    color: q.bookmarked
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: q.bookmarked ? 'Remove bookmark' : 'Bookmark',
                  onPressed: onBookmark,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${q.type == QuestionType.mcqSingle ? '$number. ' : ''}${q.prompt}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            ..._answerRows(theme, q),
            if (q.explanation != null && q.explanation!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _ReadMore(explanation: q.explanation!),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _answerRows(ThemeData theme, QuizQuestion q) {
    switch (q.type) {
      case QuestionType.mcqSingle:
        return <Widget>[
          for (int i = 0; i < q.options.length; i++)
            _AnswerRow(
              leading: '${_letters[i % _letters.length]}.',
              text: q.options[i],
              isAnswer: q.answerIndex == i,
            ),
        ];
      case QuestionType.trueFalse:
        return <Widget>[
          _AnswerRow(
            leading: 'True',
            text: '',
            isAnswer: q.answerBool == true,
            plain: true,
          ),
          _AnswerRow(
            leading: 'False',
            text: '',
            isAnswer: q.answerBool == false,
            plain: true,
          ),
        ];
      case QuestionType.fillBlank:
        return <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: quizCorrectColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: quizCorrectColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.check_circle_rounded,
                    size: 18, color: quizCorrectColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: 'Answer: ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextSpan(
                          text: q.answerTexts.join(', '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: quizCorrectColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      case QuestionType.matching:
      case QuestionType.multiCorrect:
        return <Widget>[
          Text(
            'This question type is not displayed in the browse view.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ];
    }
  }
}

/// One option row; the correct one is bolded and tinted (reference-app style).
class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.leading,
    required this.text,
    required this.isAnswer,
    this.plain = false,
  });

  final String leading;
  final String text;
  final bool isAnswer;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isAnswer
            ? quizCorrectColor.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: isAnswer
            ? Border.all(
                color: quizCorrectColor.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isAnswer
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 19,
            color: isAnswer
                ? quizCorrectColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              plain ? leading : '$leading $text',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isAnswer ? FontWeight.w800 : FontWeight.w500,
                color: isAnswer
                    ? quizCorrectColor
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Read more ▾" expander, like the reference app's per-card read-more link.
class _ReadMore extends StatefulWidget {
  const _ReadMore({required this.explanation});

  final String explanation;

  @override
  State<_ReadMore> createState() => _ReadMoreState();
}

class _ReadMoreState extends State<_ReadMore> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _open ? 'Read less' : 'Read more',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.explanation,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ),
      ],
    );
  }
}

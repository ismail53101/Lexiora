import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/question_tile.dart';

/// A lazily-paginated question list (handles 100k+ via LIMIT/OFFSET). Reloads on
/// filter change and whenever [qRevisionProvider] bumps (after edits/imports).
class PaginatedQuestions extends ConsumerStatefulWidget {
  const PaginatedQuestions({
    super.key,
    required this.filter,
    this.padding,
    this.emptyTitle = 'No questions',
    this.emptyMessage = 'Import a JSON bank to add questions.',
  });

  final QuizFilter filter;
  final EdgeInsetsGeometry? padding;
  final String emptyTitle;
  final String emptyMessage;

  @override
  ConsumerState<PaginatedQuestions> createState() => _PaginatedQuestionsState();
}

class _PaginatedQuestionsState extends ConsumerState<PaginatedQuestions> {
  static const int _pageSize = 40;
  final ScrollController _scroll = ScrollController();
  final List<QuizQuestion> _items = <QuizQuestion>[];
  int _offset = 0;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void didUpdateWidget(PaginatedQuestions old) {
    super.didUpdateWidget(old);
    if (old.filter != widget.filter) _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!reset && !_hasMore)) return;
    _loading = true;
    if (reset) {
      _offset = 0;
      _hasMore = true;
    }
    final List<QuizQuestion> page = await ref
        .read(quizRepositoryProvider)
        .questions(widget.filter, limit: _pageSize, offset: _offset);
    if (!mounted) return;
    setState(() {
      if (reset) _items.clear();
      _items.addAll(page);
      _offset += page.length;
      _hasMore = page.length == _pageSize;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(qRevisionProvider, (_, _) => _load(reset: true));

    if (_items.isEmpty && !_loading) {
      return EmptyState(
        icon: Icons.help_outline,
        title: widget.emptyTitle,
        message: widget.emptyMessage,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 6),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (BuildContext context, int i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return QuestionTile(question: _items[i]);
        },
      ),
    );
  }
}

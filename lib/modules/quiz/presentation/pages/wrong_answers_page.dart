import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';

/// The Wrong-Answer Notebook: auto-collected mistakes with Retry / Delete /
/// Clear all.
class WrongAnswersPage extends ConsumerStatefulWidget {
  const WrongAnswersPage({super.key, this.subjectId});

  final String? subjectId;

  @override
  ConsumerState<WrongAnswersPage> createState() => _WrongAnswersPageState();
}

class _WrongAnswersPageState extends ConsumerState<WrongAnswersPage> {
  static const int _pageSize = 40;
  final ScrollController _scroll = ScrollController();
  final List<WrongAnswerEntry> _items = <WrongAnswerEntry>[];
  int _offset = 0;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        _load();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!reset && !_hasMore)) return;
    _loading = true;
    if (reset) {
      _offset = 0;
      _hasMore = true;
    }
    final List<WrongAnswerEntry> page = await ref
        .read(quizRepositoryProvider)
        .wrongAnswers(
            subjectId: widget.subjectId, limit: _pageSize, offset: _offset);
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
    final bool scoped = widget.subjectId != null;
    final int total = scoped
        ? _items.length
        : ref.watch(quizWrongCountProvider).maybeWhen(
              data: (int v) => v,
              orElse: () => _items.length,
            );
    final String retryPath = scoped
        ? '${AppRoutes.quizPlayer}?subject=${widget.subjectId}&wrong=1&mode=${QuizMode.practice.name}'
        : '${AppRoutes.quizPlayer}?wrong=1&mode=${QuizMode.practice.name}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wrong Answers'),
        actions: <Widget>[
          if (!scoped && total > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all',
              onPressed: _clearAll,
            ),
        ],
      ),
      floatingActionButton: total == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(retryPath),
              icon: const Icon(Icons.replay),
              label: const Text('Retry all'),
            ),
      body: (_items.isEmpty && !_loading)
          ? const EmptyState(
              icon: Icons.error_outline,
              title: 'No wrong answers',
              message:
                  'Questions you miss are collected here automatically for revision.',
            )
          : RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: ListView.builder(
                controller: _scroll,
                itemCount: _items.length + (_hasMore ? 1 : 0),
                itemBuilder: (BuildContext context, int i) {
                  if (i >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final WrongAnswerEntry e = _items[i];
                  return Card(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: ListTile(
                      leading: QuestionTypeChip(type: e.question.type),
                      title: Text(e.question.prompt,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(<String>[
                        if (e.question.subject != null) e.question.subject!,
                        'missed ${e.wrongCount}×',
                      ].join(' · ')),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove',
                        onPressed: () => _delete(e),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _delete(WrongAnswerEntry e) async {
    await ref.read(quizRepositoryProvider).deleteWrongAnswer(e.question.id);
    await _load(reset: true);
  }

  Future<void> _clearAll() async {
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Clear all wrong answers?'),
            content: const Text('This empties the wrong-answer notebook.'),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Clear all')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await ref.read(quizRepositoryProvider).clearWrongAnswers();
    await _load(reset: true);
  }
}

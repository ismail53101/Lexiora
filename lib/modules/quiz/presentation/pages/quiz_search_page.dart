import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/paginated_questions.dart';

/// Search & filter across all questions (subject/topic/text/tag + type,
/// difficulty, bookmarked, wrong, date, sort).
class QuizSearchPage extends ConsumerStatefulWidget {
  const QuizSearchPage({super.key});

  @override
  ConsumerState<QuizSearchPage> createState() => _QuizSearchPageState();
}

class _QuizSearchPageState extends ConsumerState<QuizSearchPage> {
  final TextEditingController _field = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(quizFilterProvider.notifier).reset());
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  QuizFilterNotifier get _n => ref.read(quizFilterProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final QuizFilter f = ref.watch(quizFilterProvider);
    final List<String> subjects = ref.watch(qSubjectSuggestionsProvider).maybeWhen(
          data: (List<String> s) => s,
          orElse: () => const <String>[],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Search & Filter')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _field,
              onChanged: _n.setQuery,
              decoration: InputDecoration(
                hintText: 'Search prompt, options, subject, tags…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: f.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _field.clear();
                          _n.setQuery('');
                        }),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                _menuChip<QuizSort>(
                  label: 'Sort',
                  value: f.sort,
                  isDefault: f.sort == QuizSort.recent,
                  options: QuizSort.values,
                  labelOf: (QuizSort v) => v.label,
                  onSelected: (QuizSort v) => _n.set(f.copyWith(sort: v)),
                ),
                _typeChip(f),
                _difficultyChip(f),
                _stringChip(
                  label: 'Subject',
                  value: f.subject,
                  options: subjects,
                  onSelected: (String? v) =>
                      _n.set(f.copyWith(subject: v, clearSubject: v == null)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Bookmarked'),
                    selected: f.onlyBookmarked,
                    onSelected: (bool v) => _n.set(f.copyWith(onlyBookmarked: v)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Wrong answers'),
                    selected: f.onlyWrong,
                    onSelected: (bool v) => _n.set(f.copyWith(onlyWrong: v)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: PaginatedQuestions(
              filter: f,
              emptyMessage: 'No questions match. Adjust your search or filters.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(QuizFilter f) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<QuestionType?>(
        onSelected: (QuestionType? t) =>
            _n.set(f.copyWith(type: t, clearType: t == null)),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<QuestionType?>>[
          const PopupMenuItem<QuestionType?>(child: Text('Any type')),
          for (final QuestionType t in QuestionType.values)
            PopupMenuItem<QuestionType?>(value: t, child: Text(t.label)),
        ],
        child: Chip(
          label: Text(f.type == null ? 'Type' : f.type!.shortLabel),
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
          backgroundColor: f.type == null
              ? null
              : Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }

  Widget _difficultyChip(QuizFilter f) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<QuizDifficulty?>(
        onSelected: (QuizDifficulty? d) =>
            _n.set(f.copyWith(difficulty: d, clearDifficulty: d == null)),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<QuizDifficulty?>>[
          const PopupMenuItem<QuizDifficulty?>(child: Text('Any')),
          for (final QuizDifficulty d in QuizDifficulty.values)
            PopupMenuItem<QuizDifficulty?>(value: d, child: Text(d.label)),
        ],
        child: Chip(
          label: Text(f.difficulty == null ? 'Difficulty' : f.difficulty!.label),
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
          backgroundColor: f.difficulty == null
              ? null
              : Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }

  Widget _menuChip<T>({
    required String label,
    required T value,
    required bool isDefault,
    required List<T> options,
    required String Function(T) labelOf,
    required ValueChanged<T> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<T>(
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<T>>[
          for (final T o in options)
            PopupMenuItem<T>(value: o, child: Text(labelOf(o))),
        ],
        child: Chip(
          label: Text(isDefault ? label : '$label: ${labelOf(value)}'),
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
          backgroundColor: isDefault
              ? null
              : Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }

  Widget _stringChip({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        onSelected: (String v) => onSelected(v.isEmpty ? null : v),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: '', child: Text('Any')),
          for (final String o in options)
            PopupMenuItem<String>(value: o, child: Text(o)),
        ],
        child: Chip(
          label: Text(value == null ? label : '$label: $value'),
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
          backgroundColor: value == null
              ? null
              : Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }
}

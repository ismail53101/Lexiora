import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_settings.dart';
import 'package:lexiora/modules/quiz/domain/quiz_grading.dart';
import 'package:lexiora/modules/quiz/presentation/pages/quiz_results_page.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';

/// The Quiz Player. A fully functional engine shell — it plays whatever
/// questions it is given and knows nothing about where they came from.
class QuizPlayerPage extends ConsumerStatefulWidget {
  const QuizPlayerPage({
    super.key,
    this.bankId,
    this.subjectId,
    this.topicId,
    required this.mode,
    this.onlyWrong = false,
    this.onlyBookmarked = false,
  });

  final String? bankId;
  final String? subjectId;
  final String? topicId;
  final QuizMode mode;
  final bool onlyWrong;
  final bool onlyBookmarked;

  @override
  ConsumerState<QuizPlayerPage> createState() => _QuizPlayerPageState();
}

class _QuizPlayerPageState extends ConsumerState<QuizPlayerPage> {
  List<QuizQuestion> _questions = <QuizQuestion>[];
  final Map<int, QuizGivenAnswer> _answers = <int, QuizGivenAnswer>{};
  final Set<int> _revealed = <int>{};
  final Map<int, int> _timeMs = <int, int>{};
  final TextEditingController _blank = TextEditingController();
  QuizSettings _settings = QuizSettings.defaults;
  int _index = 0;
  bool _loading = true;
  bool _submitting = false;
  DateTime _shownAt = DateTime.now();
  DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _blank.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final QuizSettings s = await ref.read(quizRepositoryProvider).loadSettings();
    final QuizFilter filter = QuizFilter(
      subjectId: widget.subjectId,
      topicId: widget.topicId,
      onlyWrong: widget.onlyWrong,
      onlyBookmarked: widget.onlyBookmarked,
    );
    final List<QuizQuestion> qs = await ref.read(quizRepositoryProvider).buildSession(
          bankId: widget.bankId,
          filter: filter,
          limit: s.questionsPerQuiz > 0 ? s.questionsPerQuiz : 100,
          shuffle: s.shuffleQuestions,
        );
    if (!mounted) return;
    setState(() {
      _settings = s;
      _questions = qs;
      _loading = false;
      _shownAt = DateTime.now();
      _startedAt = DateTime.now();
      _syncBlank();
    });
  }

  void _syncBlank() {
    final QuizGivenAnswer? g = _answers[_index];
    _blank.text = g?.text ?? '';
  }

  void _accrueTime() {
    _timeMs[_index] =
        (_timeMs[_index] ?? 0) + DateTime.now().difference(_shownAt).inMilliseconds;
  }

  bool get _isPractice => widget.mode == QuizMode.practice;

  void _select(QuizGivenAnswer given) {
    setState(() {
      _answers[_index] = given;
      if (_isPractice && _questions[_index].type != QuestionType.fillBlank) {
        _revealed.add(_index);
      }
    });
  }

  void _go(int to) {
    _accrueTime();
    setState(() {
      _index = to.clamp(0, _questions.length - 1);
      _shownAt = DateTime.now();
      _syncBlank();
    });
  }

  void _skip() {
    setState(() => _answers.remove(_index));
    if (_index < _questions.length - 1) {
      _go(_index + 1);
    }
  }

  Future<void> _toggleBookmark() async {
    final QuizQuestion q = _questions[_index];
    await ref.read(quizRepositoryProvider).setBookmarked(q.id, !q.bookmarked);
    setState(() =>
        _questions[_index] = q.copyWith(bookmarked: !q.bookmarked));
  }

  Future<void> _submit() async {
    _accrueTime();
    setState(() => _submitting = true);
    final List<QuestionOutcome> outcomes = <QuestionOutcome>[];
    for (int i = 0; i < _questions.length; i++) {
      final QuizGivenAnswer? g = _answers[i];
      outcomes.add(QuestionOutcome(
        question: _questions[i],
        given: g,
        skipped: g == null || g.isEmpty,
        timeMs: _timeMs[i] ?? 0,
      ));
    }
    final int duration =
        DateTime.now().difference(_startedAt).inMilliseconds;
    final QuizAttempt attempt =
        await ref.read(quizRepositoryProvider).recordAttempt(
              mode: widget.mode,
              outcomes: outcomes,
              bankId: widget.bankId,
              durationMs: duration,
            );
    ref.read(qRevisionProvider.notifier).bump();
    if (!mounted) return;
    unawaited(Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => QuizResultsPage(attempt: attempt, outcomes: outcomes),
    )));
  }

  Future<bool> _confirmQuit() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Leave quiz?'),
            content: const Text('Your progress in this session will be lost.'),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Stay')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Leave')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mode.label)),
        body: const Center(
            child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No questions available for this selection. Import a JSON bank to add content.',
            textAlign: TextAlign.center,
          ),
        )),
      );
    }

    final QuizQuestion q = _questions[_index];
    final bool revealed = _revealed.contains(_index);
    final bool isLast = _index == _questions.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) async {
        if (didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        if (await _confirmQuit() && mounted) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_index + 1} / ${_questions.length}'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
                value: (_index + 1) / _questions.length),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(q.bookmarked ? Icons.star : Icons.star_border),
              tooltip: 'Bookmark',
              onPressed: _toggleBookmark,
            ),
            TextButton(
              onPressed: _submitting ? null : _submit,
              child: const Text('Submit'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Row(
              children: <Widget>[
                Chip(
                  label: Text(q.type.label),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Text(widget.mode.label,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 16),
            Text(q.prompt, style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            ..._answerArea(theme, q, revealed),
            if (revealed &&
                _settings.showExplanations &&
                q.explanation != null &&
                q.explanation!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Explanation', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(q.explanation!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: _controls(isLast),
      ),
    );
  }

  List<Widget> _answerArea(ThemeData theme, QuizQuestion q, bool revealed) {
    switch (q.type) {
      case QuestionType.mcqSingle:
        return <Widget>[
          for (int i = 0; i < q.options.length; i++)
            _choice(q, i, q.options[i], revealed),
        ];
      case QuestionType.trueFalse:
        return <Widget>[
          _boolChoice(q, true, 'True', revealed),
          _boolChoice(q, false, 'False', revealed),
        ];
      case QuestionType.fillBlank:
        return <Widget>[
          TextField(
            controller: _blank,
            enabled: !revealed,
            decoration: const InputDecoration(
              labelText: 'Your answer',
              border: OutlineInputBorder(),
            ),
            onChanged: (String v) =>
                _answers[_index] = QuizGivenAnswer.blank(v),
          ),
          const SizedBox(height: 12),
          if (_isPractice && !revealed)
            FilledButton(
              onPressed: () {
                _select(QuizGivenAnswer.blank(_blank.text));
                setState(() => _revealed.add(_index));
              },
              child: const Text('Check'),
            ),
          if (revealed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                q.isCorrect(_answers[_index] ?? const QuizGivenAnswer())
                    ? 'Correct'
                    : 'Correct answer: ${q.answerTexts.join(", ")}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: q.isCorrect(_answers[_index] ?? const QuizGivenAnswer())
                      ? quizCorrectColor
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ];
      case QuestionType.matching:
      case QuestionType.multiCorrect:
        return <Widget>[
          Text('This question type is reserved and not playable in this version.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ];
    }
  }

  Widget _choice(QuizQuestion q, int i, String text, bool revealed) {
    final int? selected = _answers[_index]?.index;
    final bool isSelected = selected == i;
    final bool isAnswer = q.answerIndex == i;

    final QuizOptionState state;
    if (revealed && isAnswer) {
      state = QuizOptionState.correct;
    } else if (revealed && isSelected) {
      state = QuizOptionState.wrong;
    } else if (isSelected) {
      state = QuizOptionState.selected;
    } else {
      state = QuizOptionState.normal;
    }
    return QuizOptionCard(
      text: text,
      state: state,
      onTap: revealed ? null : () => _select(QuizGivenAnswer.choice(i)),
    );
  }

  Widget _boolChoice(QuizQuestion q, bool value, String text, bool revealed) {
    final bool? selected = _answers[_index]?.boolValue;
    final bool isSelected = selected == value;
    final bool isAnswer = q.answerBool == value;

    final QuizOptionState state;
    if (revealed && isAnswer) {
      state = QuizOptionState.correct;
    } else if (revealed && isSelected) {
      state = QuizOptionState.wrong;
    } else if (isSelected) {
      state = QuizOptionState.selected;
    } else {
      state = QuizOptionState.normal;
    }
    return QuizOptionCard(
      text: text,
      state: state,
      onTap: revealed ? null : () => _select(QuizGivenAnswer.boolean(value)),
    );
  }

  Widget _controls(bool isLast) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Row(
          children: <Widget>[
            OutlinedButton(
              onPressed: _index == 0 ? null : () => _go(_index - 1),
              child: const Text('Previous'),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: _skip, child: const Text('Skip')),
            const Spacer(),
            if (isLast)
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.done_all),
                label: const Text('Finish'),
              )
            else
              FilledButton.icon(
                onPressed: () => _go(_index + 1),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
          ],
        ),
      ),
    );
  }
}

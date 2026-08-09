import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/quiz_grading.dart';
import 'package:lexiora/modules/quiz/domain/quiz_stages.dart';
import 'package:lexiora/modules/quiz/presentation/pages/stage_results_page.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';

/// The timed, exam-style player for a single stage (Phase v0.11.0).
///
/// Exam rules: 30 seconds per question (timeout = skipped), no instant
/// feedback — the score, stars and review all appear on the results screen.
/// Answering the last question (or the last timer expiring) submits the stage
/// and records the attempt + stage progress.
class StagePlayerPage extends ConsumerStatefulWidget {
  const StagePlayerPage({
    super.key,
    required this.subjectId,
    required this.stageIndex,
    this.subjectName = '',
  });

  final String subjectId;
  final int stageIndex;
  final String subjectName;

  @override
  ConsumerState<StagePlayerPage> createState() => _StagePlayerPageState();
}

class _StagePlayerPageState extends ConsumerState<StagePlayerPage> {
  List<QuizQuestion> _questions = <QuizQuestion>[];
  final Map<int, QuizGivenAnswer> _answers = <int, QuizGivenAnswer>{};
  final Map<int, int> _timeMs = <int, int>{};
  final TextEditingController _blank = TextEditingController();
  int _index = 0;
  int _remaining = quizStageSecondsPerQuestion;
  bool _loading = true;
  bool _submitting = false;
  Timer? _timer;
  DateTime _shownAt = DateTime.now();
  DateTime _startedAt = DateTime.now();

  int get _stageNumber => widget.stageIndex + 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blank.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final List<QuizQuestion> qs = await ref
        .read(quizRepositoryProvider)
        .stageQuestions(widget.subjectId, widget.stageIndex);
    if (!mounted) return;
    setState(() {
      _questions = qs;
      _loading = false;
      _startedAt = DateTime.now();
      _shownAt = DateTime.now();
      _syncBlank();
      _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = quizStageSecondsPerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_remaining <= 1) {
        _onTimeout();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _onTimeout() {
    _timer?.cancel();
    _accrueTime();
    if (_index >= _questions.length - 1) {
      _submit();
    } else {
      setState(() {
        _answers.remove(_index);
        _index++;
        _shownAt = DateTime.now();
        _syncBlank();
        _startTimer();
      });
    }
  }

  void _syncBlank() {
    _blank.text = _answers[_index]?.text ?? '';
  }

  void _accrueTime() {
    _timeMs[_index] = (_timeMs[_index] ?? 0) +
        DateTime.now().difference(_shownAt).inMilliseconds;
  }

  void _select(QuizGivenAnswer given) {
    setState(() => _answers[_index] = given);
  }

  void _goNext() {
    _timer?.cancel();
    _accrueTime();
    if (_index >= _questions.length - 1) {
      _submit();
      return;
    }
    setState(() {
      _index++;
      _shownAt = DateTime.now();
      _syncBlank();
      _startTimer();
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _timer?.cancel();
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
    final QuizAttempt attempt = await ref
        .read(quizRepositoryProvider)
        .recordAttempt(
          mode: QuizMode.stage,
          title: 'Stage $_stageNumber',
          outcomes: outcomes,
          durationMs: duration,
        );
    final int correct = attempt.correct;
    final int total = attempt.totalQuestions;
    await ref.read(quizRepositoryProvider).saveStageResult(
          subjectId: widget.subjectId,
          stageIndex: widget.stageIndex,
          correct: correct,
          total: total,
        );
    ref.read(qRevisionProvider.notifier).bump();
    if (!mounted) return;
    unawaited(Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => StageResultsPage(
        subjectId: widget.subjectId,
        subjectName: widget.subjectName,
        stageIndex: widget.stageIndex,
        attempt: attempt,
        outcomes: outcomes,
      ),
    )));
  }

  Future<bool> _confirmQuit() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Leave stage?'),
            content: const Text('Your progress in this stage will be lost.'),
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
        appBar: AppBar(title: Text('Stage $_stageNumber')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No questions available for this stage.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final QuizQuestion q = _questions[_index];
    final bool isLast = _index == _questions.length - 1;
    final QuizGivenAnswer? given = _answers[_index];
    final bool answered = given != null && !given.isEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) async {
        if (didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        if (await _confirmQuit() && mounted) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Stage $_stageNumber'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: _remaining / quizStageSecondsPerQuestion,
              minHeight: 4,
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _remaining <= 5
                        ? Icons.timer_off_outlined
                        : Icons.timer_outlined,
                    size: 18,
                    color: _remaining <= 5
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_remaining}s',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _remaining <= 5
                          ? theme.colorScheme.error
                          : null,
                    ),
                  ),
                ],
              ),
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
                Text(
                  '${_index + 1}/${_questions.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            QuizQuestionCard(prompt: q.prompt),
            const SizedBox(height: 20),
            ..._answerArea(theme, q, given),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _quit,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('QUIT'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _submitting ? null : (answered ? _goNext : null),
                  icon: Icon(isLast ? Icons.done_all : Icons.arrow_forward),
                  label: Text(isLast ? 'FINISH' : 'NEXT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _quit() async {
    _timer?.cancel();
    final NavigatorState navigator = Navigator.of(context);
    if (await _confirmQuit() && mounted) navigator.pop();
  }

  List<Widget> _answerArea(
      ThemeData theme, QuizQuestion q, QuizGivenAnswer? given) {
    final bool answered = given != null && !given.isEmpty;
    switch (q.type) {
      case QuestionType.mcqSingle:
        return <Widget>[
          for (int i = 0; i < q.options.length; i++)
            _choice(q, i, q.options[i], given),
        ];
      case QuestionType.trueFalse:
        return <Widget>[
          _boolChoice(q, true, 'True', given),
          _boolChoice(q, false, 'False', given),
        ];
      case QuestionType.fillBlank:
        return <Widget>[
          TextField(
            controller: _blank,
            enabled: !answered,
            decoration: const InputDecoration(
              labelText: 'Your answer',
              border: OutlineInputBorder(),
            ),
            onChanged: (String v) => setState(
                () => _answers[_index] = QuizGivenAnswer.blank(v)),
          ),
          if (answered) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              q.isCorrect(given!)
                  ? 'Correct ✓'
                  : 'Correct answer: ${q.answerTexts.join(', ')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: q.isCorrect(given!)
                    ? quizCorrectColor
                    : theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ];
      case QuestionType.matching:
      case QuestionType.multiCorrect:
        return <Widget>[
          Text(
            'This question type is reserved and not playable in this version.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ];
    }
  }

  Widget _choice(
      QuizQuestion q, int i, String text, QuizGivenAnswer? given) {
    final bool answered = given != null && !given.isEmpty;
    final bool isSelected = given?.index == i;
    final bool isAnswer = q.answerIndex == i;
    return QuizOptionCard(
      text: text,
      state: answered
          ? quizOptionStateAfterAnswer(
              isAnswer: isAnswer, isSelected: isSelected)
          : QuizOptionState.normal,
      onTap: answered ? null : () => _select(QuizGivenAnswer.choice(i)),
    );
  }

  Widget _boolChoice(QuizQuestion q, bool value, String text,
      QuizGivenAnswer? given) {
    final bool answered = given != null && !given.isEmpty;
    final bool isSelected = given?.boolValue == value;
    final bool isAnswer = q.answerBool == value;
    return QuizOptionCard(
      text: text,
      state: answered
          ? quizOptionStateAfterAnswer(
              isAnswer: isAnswer, isSelected: isSelected)
          : QuizOptionState.normal,
      onTap: answered ? null : () => _select(QuizGivenAnswer.boolean(value)),
    );
  }
}

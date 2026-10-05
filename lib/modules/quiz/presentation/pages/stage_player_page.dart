import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_stage_progress.dart';
import 'package:lexiora/modules/quiz/domain/quiz_grading.dart';
import 'package:lexiora/modules/quiz/domain/quiz_stages.dart';
import 'package:lexiora/modules/quiz/presentation/pages/stage_results_page.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';

/// The timed, exam-style player for a single stage (Phase v0.11.0).
///
/// Exam rules: 50 seconds per question (timeout = skipped), options shuffled
/// per question so the correct answer is never predictably in position A, and
/// instant green/red feedback — the timer FREEZES the moment the user answers,
/// the options lock, and NEXT (or FINISH) resets the timer for the next
/// question. The score, stars and review all appear on the results screen.
/// Answering the last question (or the last timer expiring) submits the stage
/// and records the attempt + stage progress.
class StagePlayerPage extends ConsumerStatefulWidget {
  const StagePlayerPage({
    super.key,
    required this.subjectId,
    required this.stageIndex,
    this.subjectName = '',
    this.topicId,
  });

  final String subjectId;
  final int stageIndex;
  final String subjectName;
  final String? topicId;

  @override
  ConsumerState<StagePlayerPage> createState() => _StagePlayerPageState();
}

class _StagePlayerPageState extends ConsumerState<StagePlayerPage> {
  List<QuizQuestion> _questions = <QuizQuestion>[];
  final Map<int, QuizGivenAnswer> _answers = <int, QuizGivenAnswer>{};
  final Map<int, int> _timeMs = <int, int>{};
  final TextEditingController _blank = TextEditingController();
  final Random _random = Random();
  List<int> _displayOrder = const <int>[];
  int _index = 0;
  int _remaining = quizStageSecondsPerQuestion;
  bool _loading = true;
  bool _accessDenied = false;
  bool _submitting = false;
  bool _frozen = false;
  bool _confirmingQuit = false;
  bool _leaving = false;
  Timer? _timer;
  DateTime _shownAt = DateTime.now();
  DateTime _startedAt = DateTime.now();

  int get _stageNumber => widget.stageIndex + 1;
  bool get _mainQuiz => isMainQuizScope(QuizStageScope(
        subjectId: widget.subjectId,
        topicId: widget.topicId,
      ));

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
    final repository = ref.read(quizRepositoryProvider);
    final QuizStageScope scope = QuizStageScope(
      subjectId: widget.subjectId,
      topicId: widget.topicId,
    );
    if (isMainQuizScope(scope)) {
      final List<QuizStageProgress> progress =
          await repository.watchStageProgress(widget.subjectId).first;
      final Set<int> passed = <int>{
        for (final QuizStageProgress item in progress)
          if (item.passed) item.stageIndex,
      };
      final Set<int> rewardUnlocks =
          await repository.mainQuizRewardedMilestoneStages(widget.subjectId);
      if (!quizStageUnlocked(
        widget.stageIndex,
        passed,
        requireRewardedMilestones: true,
        rewardedUnlockedStageIndices: rewardUnlocks,
      )) {
        if (!mounted) return;
        setState(() {
          _accessDenied = true;
          _loading = false;
        });
        return;
      }
    }
    final List<QuizQuestion> qs = await repository.stageQuestions(
      widget.subjectId,
      widget.stageIndex,
      topicId: widget.topicId,
    );
    if (!mounted) return;
    setState(() {
      _questions = qs;
      _loading = false;
      _startedAt = DateTime.now();
      _shownAt = DateTime.now();
      _frozen = false;
      _prepareQuestion();
      _syncBlank();
      _startTimer();
    });
  }

  /// Shuffles the current question's options once (per question load, never
  /// per rebuild) and keeps the display→original mapping for grading.
  void _prepareQuestion() {
    if (_questions.isEmpty) return;
    final QuizQuestion q = _questions[_index];
    final ShuffledOptions shuffled =
        shuffleOptions(q.options, q.answerIndex, _random);
    _displayOrder = shuffled.order;
  }

  void _startTimer({bool resetRemaining = true}) {
    _timer?.cancel();
    if (resetRemaining) _remaining = quizStageSecondsPerQuestion;
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
        _frozen = false;
        _shownAt = DateTime.now();
        _prepareQuestion();
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
    _freezeIfAnswered();
  }

  /// Stops the countdown the instant the current question is answered. The
  /// timer stays frozen (no ticks, no negative time) until NEXT/FINISH.
  void _freezeIfAnswered() {
    if (_frozen) return;
    final QuizGivenAnswer? given = _answers[_index];
    if (given == null || given.isEmpty) return;
    _frozen = true;
    _timer?.cancel();
    _accrueTime();
    _shownAt = DateTime.now();
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
      _frozen = false;
      _shownAt = DateTime.now();
      _prepareQuestion();
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
          topicId: widget.topicId,
          stageIndex: widget.stageIndex,
          correct: correct,
          total: total,
        );
    ref.read(qRevisionProvider.notifier).bump();
    if (!_mainQuiz &&
        sl<RewardedAdManager>().recordNonMainQuizCompletion() &&
        mounted) {
      await _offerReward(context);
    }
    if (!mounted) return;
    unawaited(Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => StageResultsPage(
        subjectId: widget.subjectId,
        subjectName: widget.subjectName,
        topicId: widget.topicId,
        stageIndex: widget.stageIndex,
        attempt: attempt,
        outcomes: outcomes,
      ),
    )));
  }

  Future<void> _offerReward(BuildContext context) async {
    final bool watch = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Keep your streak going'),
            content: const Text(
              'You completed five quizzes. Watch a short ad for a bonus reward?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Watch ad'),
              ),
            ],
          ),
        ) ??
        false;
    if (!watch || !mounted) return;
    final RewardedAdResult result = await sl<RewardedAdManager>().showRewarded(
      placement: RewardedAdPlacement.quiz,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == RewardedAdResult.rewarded
              ? 'Reward claimed.'
              : 'The ad was not completed. You can continue normally.',
        ),
      ),
    );
  }

  Future<bool> _confirmQuit() async {
    // Android Back, the AppBar button, and QUIT can all arrive through
    // separate callbacks. Never allow two confirmation dialogs (or two pops)
    // for one leave request.
    if (_confirmingQuit) return false;
    _confirmingQuit = true;
    if (_mainQuiz) {
      if (!_loading && !_frozen && _questions.isNotEmpty) _accrueTime();
      _timer?.cancel();
    }
    bool leave = false;
    try {
      leave = await showDialog<bool>(
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
    } finally {
      _confirmingQuit = false;
      if (_mainQuiz && !leave && mounted && !_submitting) {
        // Exclude time spent in the confirmation dialog from the question's
        // elapsed time. Preserve both the selected answer and remaining timer.
        _shownAt = DateTime.now();
        if (!_loading && !_frozen && _questions.isNotEmpty) {
          _startTimer(resetRemaining: false);
        }
      }
    }
    return leave;
  }

  void _returnToStageList() {
    if (_mainQuiz) {
      // StageMap opens the player through GoRouter, while subsequent Result/
      // Next routes are imperative MaterialPageRoutes. A plain pop can therefore
      // reveal the stale original player (often Stage 1). Rebase the router to
      // this subject's stage list and discard quiz routes.
      context.go(AppRoutes.quizStageMap(widget.subjectId));
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _leaveQuiz() async {
    if (_submitting || _leaving) return;
    if (_accessDenied) {
      _leaving = true;
      if (mounted) _returnToStageList();
      return;
    }
    if (await _confirmQuit() && mounted && !_leaving) {
      _leaving = true;
      _timer?.cancel();
      _returnToStageList();
    }
  }

  Widget _guardLeave(Widget child) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? _) async {
          if (didPop) return;
          await _leaveQuiz();
        },
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (_loading) {
      const Scaffold loading =
          Scaffold(body: Center(child: CircularProgressIndicator()));
      return _mainQuiz ? _guardLeave(loading) : loading;
    }
    if (_accessDenied) {
      return _guardLeave(
        Scaffold(
          appBar: AppBar(
            title: Text('Stage $_stageNumber'),
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: _leaveQuiz,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to stages',
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.lock_outline, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'This stage is locked. Return to the subject stage list to '
                    'complete earlier stages or unlock this milestone.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _leaveQuiz,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to stages'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_questions.isEmpty && !_mainQuiz) {
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
    if (_questions.isEmpty) {
      return _guardLeave(
        Scaffold(
          appBar: AppBar(
            title: Text('Stage $_stageNumber'),
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: _leaveQuiz,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
          ),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No questions available for this stage.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final QuizQuestion q = _questions[_index];
    final bool isLast = _index == _questions.length - 1;
    final QuizGivenAnswer? given = _answers[_index];
    final bool answered = given != null && !given.isEmpty;

    return _guardLeave(
      Scaffold(
        appBar: AppBar(
          title: Text('Stage $_stageNumber'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: _leaveQuiz,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
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
    await _leaveQuiz();
  }

  List<Widget> _answerArea(
      ThemeData theme, QuizQuestion q, QuizGivenAnswer? given) {
    final bool answered = given != null && !given.isEmpty;
    switch (q.type) {
      case QuestionType.mcqSingle:
        // Options are shown shuffled (fixed for this question); the displayed
        // position maps back to the original index for grading.
        return <Widget>[
          for (int display = 0; display < _displayOrder.length; display++)
            _choice(
                q, display, q.options[_displayOrder[display]], given),
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
            onChanged: (String v) {
              setState(() => _answers[_index] = QuizGivenAnswer.blank(v));
              _freezeIfAnswered();
            },
          ),
          if (answered) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              q.isCorrect(given)
                  ? 'Correct ✓'
                  : 'Correct answer: ${q.answerTexts.join(', ')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: q.isCorrect(given)
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
      QuizQuestion q, int displayIndex, String text, QuizGivenAnswer? given) {
    final int originalIndex = _displayOrder[displayIndex];
    final bool answered = given != null && !given.isEmpty;
    final bool isSelected = given?.index == originalIndex;
    final bool isAnswer = q.answerIndex == originalIndex;
    return QuizOptionCard(
      text: text,
      state: answered
          ? quizOptionStateAfterAnswer(
              isAnswer: isAnswer, isSelected: isSelected)
          : QuizOptionState.normal,
      onTap: answered
          ? null
          : () => _select(QuizGivenAnswer.choice(originalIndex)),
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

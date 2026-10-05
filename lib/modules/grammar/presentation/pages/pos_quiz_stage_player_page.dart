import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/grammar_quiz_stages.dart';
import 'package:lexiora/modules/grammar/presentation/providers/grammar_providers.dart';

/// Returned to the stage map so it can keep one ladder route underneath each
/// player and safely handle normal progression or a rewarded milestone.
enum GrammarQuizPlayerAction {
  backToStages,
  nextStage,
  requestMilestoneReward,
}

class PosQuizStagePlayerPage extends ConsumerStatefulWidget {
  const PosQuizStagePlayerPage({
    super.key,
    required this.lesson,
    required this.stageIndex,
  });

  final GrammarLesson lesson;
  final int stageIndex;

  @override
  ConsumerState<PosQuizStagePlayerPage> createState() =>
      _PosQuizStagePlayerPageState();
}

class _PosQuizStagePlayerPageState
    extends ConsumerState<PosQuizStagePlayerPage> {
  static const int _secondsPerQuestion = 50;
  late final List<GrammarQuestion> _questions;
  Timer? _timer;
  int _questionIndex = 0;
  int _secondsLeft = _secondsPerQuestion;
  int _score = 0;
  int? _selectedIndex;
  bool _showResult = false;
  bool _finishing = false;

  GrammarQuestion get _question => _questions[_questionIndex];
  bool get _answered => _selectedIndex != null;

  @override
  void initState() {
    super.initState();
    final int start = widget.stageIndex * 10;
    _questions = widget.lesson.quiz.skip(start).take(10).toList(growable: false);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _showResult || _finishing) return;
      if (_secondsLeft <= 1) {
        _selectAnswer(null);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _selectAnswer(int? index) {
    if (_answered || _showResult || _finishing) return;
    final bool correct = index != null && index == _question.answerIndex;
    setState(() {
      _selectedIndex = index ?? -1;
      if (correct) _score++;
    });
    _timer?.cancel();
  }

  void _next() {
    if (!_answered || _finishing) return;
    if (_questionIndex == _questions.length - 1) {
      unawaited(_finishStage());
      return;
    }
    setState(() {
      _questionIndex++;
      _selectedIndex = null;
      _secondsLeft = _secondsPerQuestion;
    });
    _startTimer();
  }

  Future<void> _finishStage() async {
    if (_finishing || _showResult) return;
    setState(() => _finishing = true);
    _timer?.cancel();
    try {
      await ref.read(grammarRepositoryProvider).recordGrammarQuizStageResult(
            quizId: widget.lesson.id,
            stageIndex: widget.stageIndex,
            correct: _score,
            total: _questions.length,
          );
      if (!mounted) return;
      setState(() {
        _showResult = true;
        _finishing = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not save this result. Please try again.'),
          ),
        );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) return _buildResult(context);
    final ThemeData theme = Theme.of(context);
    final double progress = (_questionIndex + 1) / _questions.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Stage ${widget.stageIndex + 1}'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Row(children: <Widget>[
              const Icon(Icons.timer_outlined, size: 20),
              const SizedBox(width: 5),
              Text('${_secondsLeft}s',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: <Widget>[
          LinearProgressIndicator(value: progress, minHeight: 6),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Question ${_questionIndex + 1} of ${_questions.length}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text('Score: $_score',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.45)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                  children: _boldMarkedSpans(_question.question),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < _question.options.length; i++) _option(context, i),
          const SizedBox(height: 16),
          if (_answered) _feedback(context),
          if (_finishing) ...<Widget>[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _finishing
                    ? null
                    : () => Navigator.of(context)
                        .pop(GrammarQuizPlayerAction.backToStages),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('QUIT'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _answered && !_finishing ? _next : null,
                icon: Icon(_questionIndex == _questions.length - 1
                    ? Icons.flag_outlined
                    : Icons.arrow_forward),
                label: Text(
                    _questionIndex == _questions.length - 1 ? 'FINISH' : 'NEXT'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, int index) {
    final ThemeData theme = Theme.of(context);
    final bool selected = _selectedIndex == index;
    final bool correct = index == _question.answerIndex;
    const Color correctColor = Color(0xFF2E7D32);
    const Color incorrectColor = Color(0xFFC62828);
    Color? color;
    if (_answered && correct) color = correctColor.withValues(alpha: 0.16);
    if (_answered && selected && !correct) color = incorrectColor.withValues(alpha: 0.16);
    return Card(
      color: color,
      child: RadioListTile<int>(
        value: index,
        groupValue: _selectedIndex,
        onChanged: _answered || _finishing ? null : _selectAnswer,
        title: Text(_question.options[index]),
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _feedback(BuildContext context) {
    final bool correct = _selectedIndex == _question.answerIndex;
    final String title = _selectedIndex == -1
        ? 'Time is up'
        : correct
            ? 'Correct'
            : 'Incorrect';
    const Color correctColor = Color(0xFF2E7D32);
    const Color incorrectColor = Color(0xFFC62828);
    return Card(
      color: (correct ? correctColor : incorrectColor).withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: correct ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Answer: ${_question.answer}',
            style: TextStyle(
              color: correct ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_question.explanation?.isNotEmpty ?? false) ...<Widget>[
            const SizedBox(height: 5),
            Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
                children: _boldMarkedSpans(_question.explanation!),
              ),
            ),
          ],
          if (_question.examTip?.isNotEmpty ?? false) ...<Widget>[
            const SizedBox(height: 5),
            Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
                children: <TextSpan>[
                  const TextSpan(
                    text: 'Exam tip: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  ..._boldMarkedSpans(_question.examTip!),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final bool passed = _score >= (_questions.length / 2).ceil();
    final int nextStageIndex = widget.stageIndex + 1;
    final bool hasNextStage = nextStageIndex * 10 < widget.lesson.quiz.length;
    final bool milestoneNext =
        hasNextStage && isGrammarQuizRewardMilestone(nextStageIndex);
    final String nextStageLabel = 'Stage ${nextStageIndex + 1}';
    final String resultMessage = !passed
        ? 'Score at least 50% to pass this stage. You can retry it from the stage list.'
        : !hasNextStage
            ? 'You completed every stage in this Grammar quiz.'
            : milestoneNext
                ? 'Your pass is saved. $nextStageLabel requires a rewarded ad.'
                : 'Your pass is saved. $nextStageLabel is unlocked.';

    return Scaffold(
      appBar: AppBar(title: Text('Stage ${widget.stageIndex + 1} Result')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                passed ? Icons.emoji_events_outlined : Icons.refresh,
                size: 72,
                color: passed ? Colors.amber : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                passed ? 'Stage Passed' : 'Stage Not Passed',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text('$_score / ${_questions.length}',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(resultMessage, textAlign: TextAlign.center),
              const SizedBox(height: 28),
              if (passed && hasNextStage)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      milestoneNext
                          ? GrammarQuizPlayerAction.requestMilestoneReward
                          : GrammarQuizPlayerAction.nextStage,
                    ),
                    child: Text(milestoneNext
                        ? 'WATCH AD TO CONTINUE TO $nextStageLabel'
                        : 'NEXT STAGE'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pop(GrammarQuizPlayerAction.backToStages),
                    child: const Text('BACK TO STAGES'),
                  ),
                ),
              if (passed && hasNextStage) ...<Widget>[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pop(GrammarQuizPlayerAction.backToStages),
                  child: Text(milestoneNext ? 'NOT NOW' : 'BACK TO STAGES'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

List<TextSpan> _boldMarkedSpans(String text) {
  final List<TextSpan> spans = <TextSpan>[];
  final RegExp marker = RegExp(r'\*\*(.+?)\*\*');
  int cursor = 0;
  for (final RegExpMatch match in marker.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    spans.add(TextSpan(
      text: match.group(1),
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        decoration: TextDecoration.underline,
        decorationThickness: 2,
      ),
    ));
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return spans.isEmpty ? <TextSpan>[TextSpan(text: text)] : spans;
}

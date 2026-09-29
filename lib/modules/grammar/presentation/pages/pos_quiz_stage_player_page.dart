import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';

class PosQuizStagePlayerPage extends StatefulWidget {
  const PosQuizStagePlayerPage({super.key, required this.lesson, required this.stageIndex});

  final GrammarLesson lesson;
  final int stageIndex;

  @override
  State<PosQuizStagePlayerPage> createState() => _PosQuizStagePlayerPageState();
}

class _PosQuizStagePlayerPageState extends State<PosQuizStagePlayerPage> {
  static const int _secondsPerQuestion = 50;
  late final List<GrammarQuestion> _questions;
  Timer? _timer;
  int _questionIndex = 0;
  int _secondsLeft = _secondsPerQuestion;
  int _score = 0;
  int? _selectedIndex;
  bool _showResult = false;

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
      if (!mounted || _showResult) return;
      if (_secondsLeft <= 1) {
        _selectAnswer(null);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _selectAnswer(int? index) {
    if (_answered || _showResult) return;
    final bool correct = index != null && index == _question.answerIndex;
    setState(() {
      _selectedIndex = index ?? -1;
      if (correct) _score++;
    });
    _timer?.cancel();
  }

  void _next() {
    if (!_answered) return;
    if (_questionIndex == _questions.length - 1) {
      setState(() => _showResult = true);
      return;
    }
    setState(() {
      _questionIndex++;
      _selectedIndex = null;
      _secondsLeft = _secondsPerQuestion;
    });
    _startTimer();
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
              Text('${_secondsLeft}s', style: const TextStyle(fontWeight: FontWeight.w700)),
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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text('Score: $_score',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
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
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  children: _boldMarkedSpans(_question.question),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < _question.options.length; i++) _option(context, i),
          const SizedBox(height: 16),
          if (_answered) _feedback(context),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('QUIT'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _answered ? _next : null,
                icon: Icon(_questionIndex == _questions.length - 1 ? Icons.flag_outlined : Icons.arrow_forward),
                label: Text(_questionIndex == _questions.length - 1 ? 'FINISH' : 'NEXT'),
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
        onChanged: _answered ? null : _selectAnswer,
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
    return Scaffold(
      appBar: AppBar(title: Text('Stage ${widget.stageIndex + 1} Result')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Icon(passed ? Icons.emoji_events_outlined : Icons.refresh,
                size: 72, color: passed ? Colors.amber : Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(passed ? 'Stage Passed' : 'Stage Not Passed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('$_score / ${_questions.length}', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(passed ? 'You scored 50% or more. The next stage is unlocked.' : 'Score at least 50% to unlock the next stage.', textAlign: TextAlign.center),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(passed),
              child: const Text('BACK TO STAGES'),
            ),
          ]),
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

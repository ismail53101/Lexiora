import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/quiz_grading.dart';
import 'package:lexiora/modules/quiz/domain/quiz_stages.dart';
import 'package:lexiora/modules/quiz/presentation/pages/quiz_review_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/stage_player_page.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';

/// End-of-stage score screen (Phase v0.11.0): animated percentage ring, star
/// rating, pass/unlock banner, per-question review and next-stage CTA.
class StageResultsPage extends ConsumerStatefulWidget {
  const StageResultsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.topicId,
    required this.stageIndex,
    required this.attempt,
    required this.outcomes,
  });

  final String subjectId;
  final String subjectName;
  final String? topicId;
  final int stageIndex;
  final QuizAttempt attempt;
  final List<QuestionOutcome> outcomes;

  @override
  ConsumerState<StageResultsPage> createState() => _StageResultsPageState();
}

class _StageResultsPageState extends ConsumerState<StageResultsPage> {
  bool? _nextStageUnlocked;

  int get _stageNumber => widget.stageIndex + 1;
  String get subjectId => widget.subjectId;
  String get subjectName => widget.subjectName;
  String? get topicId => widget.topicId;
  int get stageIndex => widget.stageIndex;
  QuizAttempt get attempt => widget.attempt;
  List<QuestionOutcome> get outcomes => widget.outcomes;

  @override
  void initState() {
    super.initState();
    _refreshNextStageUnlock();
  }

  Future<void> _refreshNextStageUnlock() async {
    final int nextQuizNumber = widget.stageIndex + 2;
    final bool unlocked =
        !AdConfiguration.isRewardedQuizMilestone(nextQuizNumber) ||
        await sl<RewardedAdManager>().hasMainQuizUnlock(nextQuizNumber);
    if (mounted) setState(() => _nextStageUnlocked = unlocked);
  }

  Future<void> _unlockNextStage() async {
    final int nextQuizNumber = widget.stageIndex + 2;
    final bool unlocked = await sl<RewardedAdManager>().watchAdToUnlockQuiz(
      placement: RewardedAdPlacement.quiz,
      quizNumber: nextQuizNumber,
    );
    if (!mounted) return;
    if (unlocked) {
      setState(() => _nextStageUnlocked = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The next stage remains locked until the ad is completed.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int stageCount = ref
        .watch(
          quizStageCountProvider(
            QuizStageScope(subjectId: subjectId, topicId: topicId),
          ),
        )
        .maybeWhen(data: (int n) => n, orElse: () => -1);

    final int correct = attempt.correct;
    final int total = attempt.totalQuestions;
    final int score = total == 0 ? 0 : (correct * 100 / total).round();
    final bool passed = quizStagePassed(correct, total);
    final int stars = quizStageStars(correct, total);
    final bool hasNext = stageCount > stageIndex + 1;
    final bool nextStageUnlocked =
        hasNext &&
        (_nextStageUnlocked ??
            !AdConfiguration.isRewardedQuizMilestone(stageIndex + 2));

    return Scaffold(
      appBar: AppBar(
        title: Text('Stage $_stageNumber · Results'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: score / 100),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double v, Widget? child) =>
                    Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        CircularProgressIndicator(
                          value: v,
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: passed
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                '${(v * 100).round()}%',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'score',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 30,
                      color: i < stars
                          ? const Color(0xFFFFB300)
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  (passed ? theme.colorScheme.primary : theme.colorScheme.error)
                      .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  passed && nextStageUnlocked
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline,
                  color: passed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    passed
                        ? (hasNext
                              ? (nextStageUnlocked
                                    ? 'Stage passed! Stage ${stageIndex + 2} is now unlocked.'
                                    : 'Stage passed! Watch an ad to unlock Stage ${stageIndex + 2}.')
                              : 'Stage passed! You completed the ladder.')
                        : 'Score 50% or more to unlock the next stage.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: <Widget>[
              _tile(
                context,
                Icons.check_circle_outline,
                '$correct',
                'Correct',
                theme.colorScheme.primary,
              ),
              _tile(
                context,
                Icons.cancel_outlined,
                '${attempt.wrong}',
                'Wrong',
                theme.colorScheme.error,
              ),
              _tile(
                context,
                Icons.skip_next_outlined,
                '${attempt.skipped}',
                'Skipped',
                theme.colorScheme.tertiary,
              ),
              _tile(
                context,
                Icons.timer_outlined,
                _duration(attempt.durationMs),
                'Time',
                theme.colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: () {
              if (!passed) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => StagePlayerPage(
                      subjectId: subjectId,
                      subjectName: subjectName,
                      topicId: topicId,
                      stageIndex: stageIndex,
                    ),
                  ),
                );
                return;
              }
              if (!hasNext) {
                Navigator.of(context).pop();
                return;
              }
              if (!nextStageUnlocked) {
                _unlockNextStage();
                return;
              }
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => StagePlayerPage(
                    subjectId: subjectId,
                    subjectName: subjectName,
                    topicId: topicId,
                    stageIndex: stageIndex + 1,
                  ),
                ),
              );
            },
            icon: Icon(
              passed && hasNext && nextStageUnlocked
                  ? Icons.arrow_forward_rounded
                  : Icons.lock_outline,
            ),
            label: Text(
              passed && hasNext
                  ? (nextStageUnlocked
                        ? 'Next stage'
                        : 'Watch Ad to Unlock Stage ${stageIndex + 2}')
                  : (passed ? 'Done' : 'Try again'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => QuizReviewPage(
                  items: outcomes
                      .map(
                        (QuestionOutcome o) => AnsweredQuestion(
                          question: o.question,
                          given: o.given,
                          isCorrect: o.isCorrect,
                          skipped:
                              o.skipped || o.given == null || o.given!.isEmpty,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Review answers'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => StagePlayerPage(
                  subjectId: subjectId,
                  subjectName: subjectName,
                  topicId: topicId,
                  stageIndex: stageIndex,
                ),
              ),
            ),
            icon: const Icon(Icons.replay),
            label: const Text('Retry this stage'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(subjectName.isEmpty ? 'Back' : 'Back to $subjectName'),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _duration(int ms) {
    final int totalSec = ms ~/ 1000;
    final int m = totalSec ~/ 60;
    final int s = totalSec % 60;
    return m == 0 ? '${s}s' : '${m}m ${s}s';
  }
}

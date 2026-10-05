import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_quiz_stage_progress.dart';
import 'package:lexiora/modules/grammar/domain/grammar_quiz_stages.dart';
import 'package:lexiora/modules/grammar/presentation/pages/pos_quiz_stage_player_page.dart';
import 'package:lexiora/modules/grammar/presentation/providers/grammar_providers.dart';
import 'package:lexiora/modules/grammar/presentation/services/grammar_quiz_reward_unlock.dart';

/// Stage map reused by the three staged Grammar quizzes. Progress is persisted
/// independently under each quiz's stable lesson ID.
class PosQuizStageMapPage extends ConsumerStatefulWidget {
  const PosQuizStageMapPage({
    super.key,
    this.lessonId = 'pos/quiz',
    this.title = 'Parts of Speech Quiz',
  });

  final String lessonId;
  final String title;

  @override
  ConsumerState<PosQuizStageMapPage> createState() =>
      _PosQuizStageMapPageState();
}

class _PosQuizStageMapPageState extends ConsumerState<PosQuizStageMapPage> {
  bool _rewardFlowActive = false;

  Future<void> _openStage(
    GrammarLesson lesson,
    int index,
    List<GrammarQuizStageProgress> rows,
  ) async {
    final Set<int> passedStages = rows
        .where((GrammarQuizStageProgress row) => row.passed)
        .map((GrammarQuizStageProgress row) => row.stageIndex)
        .toSet();
    final Set<int> rewardedStages = rows
        .where((GrammarQuizStageProgress row) => row.rewardedUnlocked)
        .map((GrammarQuizStageProgress row) => row.stageIndex)
        .toSet();

    if (!isGrammarQuizStageUnlocked(
      stageIndex: index,
      passedStages: passedStages,
      rewardedStages: rewardedStages,
    )) {
      if (canRequestGrammarQuizMilestone(
        stageIndex: index,
        passedStages: passedStages,
        rewardedStages: rewardedStages,
      )) {
        final bool unlocked = await _requestMilestoneUnlock(lesson.id, index);
        if (!unlocked || !mounted) return;
        await _openStage(
          lesson,
          index,
          await ref
              .read(grammarRepositoryProvider)
              .grammarQuizStageProgress(lesson.id),
        );
        return;
      }
      _showMessage('Pass Stage $index first. Your saved progress is unchanged.');
      return;
    }

    final int stageCount = (lesson.quiz.length + 9) ~/ 10;
    final GrammarQuizPlayerAction? action =
        await Navigator.of(context).push<GrammarQuizPlayerAction>(
      MaterialPageRoute<GrammarQuizPlayerAction>(
        builder: (_) => PosQuizStagePlayerPage(
          lesson: lesson,
          stageIndex: index,
        ),
      ),
    );
    if (!mounted) return;

    // The player saves results before presenting its result actions. Read the
    // latest rows rather than trusting any widget-local completion state.
    final List<GrammarQuizStageProgress> latest = await ref
        .read(grammarRepositoryProvider)
        .grammarQuizStageProgress(lesson.id);
    ref.invalidate(grammarQuizStageProgressProvider(lesson.id));
    final int nextStage = index + 1;
    if (nextStage >= stageCount) return;

    if (action == GrammarQuizPlayerAction.nextStage) {
      await _openStage(lesson, nextStage, latest);
    } else if (action == GrammarQuizPlayerAction.requestMilestoneReward) {
      final bool unlocked = await _requestMilestoneUnlock(lesson.id, nextStage);
      if (!unlocked || !mounted) return;
      await _openStage(
        lesson,
        nextStage,
        await ref
            .read(grammarRepositoryProvider)
            .grammarQuizStageProgress(lesson.id),
      );
    }
  }

  Future<bool> _requestMilestoneUnlock(String quizId, int stageIndex) async {
    if (_rewardFlowActive) return false;
    setState(() => _rewardFlowActive = true);
    try {
      final RewardedAdManager adsManager =
          ref.read(grammarRewardedAdManagerProvider);
      final RewardedAdReadiness readinessBeforeRequest =
          adsManager.rewardedReadiness;
      final GrammarQuizRewardOutcome outcome =
          await requestGrammarQuizMilestoneUnlock(
        quizId: quizId,
        stageIndex: stageIndex,
        repository: ref.read(grammarRepositoryProvider),
        requestAd: ({
          required RewardedAdPlacement placement,
          required RewardCallback? onRewarded,
        }) =>
            adsManager.showRewarded(
          placement: placement,
          onRewarded: onRewarded,
        ),
      );
      if (!mounted) return false;
      ref.invalidate(grammarQuizStageProgressProvider(quizId));
      if (outcome.unlockPersisted) return true;

      final String message = switch (outcome.adResult) {
        RewardedAdResult.unavailable => switch (readinessBeforeRequest) {
            RewardedAdReadiness.loading =>
              'The rewarded ad is loading. Please try again shortly. '
                  'Stage ${stageIndex + 1} remains locked.',
            RewardedAdReadiness.retrying =>
              'The rewarded ad is being prepared. Please try again shortly. '
                  'Stage ${stageIndex + 1} remains locked.',
            RewardedAdReadiness.showing =>
              'Another rewarded ad is in progress. Please wait. '
                  'Stage ${stageIndex + 1} remains locked.',
            RewardedAdReadiness.ready =>
              'The rewarded ad could not be started. Please try again. '
                  'Stage ${stageIndex + 1} remains locked.',
            RewardedAdReadiness.notReady =>
              'A rewarded ad is being prepared. Please try again shortly. '
                  'Stage ${stageIndex + 1} remains locked.',
          },
        RewardedAdResult.cooldown =>
          'Please wait before requesting another ad. Stage ${stageIndex + 1} remains locked.',
        RewardedAdResult.premium =>
          'Stage ${stageIndex + 1} is still locked; no rewarded unlock was recorded.',
        RewardedAdResult.failed =>
          'No reward was earned. Stage ${stageIndex + 1} remains locked.',
        RewardedAdResult.rewarded =>
          'The reward could not be saved. Stage ${stageIndex + 1} remains locked.',
      };
      _showMessage(message);
      return false;
    } finally {
      if (mounted) setState(() => _rewardFlowActive = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildLadder(
    BuildContext context,
    GrammarLesson lesson,
    List<GrammarQuizStageProgress> rows,
  ) {
    if (lesson.quiz.isEmpty) {
      return const Center(child: Text('No quiz questions available.'));
    }
    final int stageCount = (lesson.quiz.length + 9) ~/ 10;
    final Map<int, GrammarQuizStageProgress> byStage = <int, GrammarQuizStageProgress>{
      for (final GrammarQuizStageProgress row in rows) row.stageIndex: row,
    };
    final Set<int> passedStages = rows
        .where((GrammarQuizStageProgress row) => row.passed)
        .map((GrammarQuizStageProgress row) => row.stageIndex)
        .toSet();
    final Set<int> rewardedStages = rows
        .where((GrammarQuizStageProgress row) => row.rewardedUnlocked)
        .map((GrammarQuizStageProgress row) => row.stageIndex)
        .toSet();
    final int passedCount = passedStages.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.flag_outlined,
                        color: Theme.of(context).colorScheme.primary, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Stage ladder',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '$passedCount / $stageCount passed',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Score 50% or more to pass each stage. Every fifth stage requires its own rewarded unlock.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_rewardFlowActive) ...<Widget>[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stageCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (BuildContext context, int index) {
            final bool unlocked = isGrammarQuizStageUnlocked(
              stageIndex: index,
              passedStages: passedStages,
              rewardedStages: rewardedStages,
            );
            final bool canReward = canRequestGrammarQuizMilestone(
              stageIndex: index,
              passedStages: passedStages,
              rewardedStages: rewardedStages,
            );
            final bool passed = byStage[index]?.passed ?? false;
            final bool rewardLocked = !unlocked && canReward;
            final bool tappable = unlocked || rewardLocked;
            final int count = index == stageCount - 1
                ? lesson.quiz.length - index * 10
                : 10;
            final ColorScheme colors = Theme.of(context).colorScheme;
            final Color borderColor = passed
                ? Colors.green
                : rewardLocked
                    ? colors.tertiary
                    : unlocked
                        ? colors.primary
                        : Theme.of(context).dividerColor;
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: tappable && !_rewardFlowActive
                  ? () => _openStage(lesson, index, rows)
                  : null,
              child: Card(
                color: rewardLocked
                    ? colors.tertiaryContainer.withValues(alpha: 0.45)
                    : unlocked
                        ? colors.surface
                        : colors.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: borderColor,
                    width: passed || unlocked || rewardLocked ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Icon(
                            passed
                                ? Icons.check_circle_outline
                                : rewardLocked
                                    ? Icons.lock_outline
                                    : unlocked
                                        ? Icons.play_arrow_rounded
                                        : Icons.lock_outline,
                            color: passed
                                ? Colors.green
                                : rewardLocked
                                    ? colors.tertiary
                                    : unlocked
                                        ? colors.primary
                                        : Theme.of(context).disabledColor,
                            size: 30,
                          ),
                          if (rewardLocked)
                            Icon(Icons.play_circle_outline,
                                color: colors.tertiary),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'Stage ${index + 1}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        passed
                            ? 'Passed · Best ${byStage[index]?.bestScore ?? 0}%'
                            : rewardLocked
                                ? 'WATCH AD TO CONTINUE'
                                : unlocked
                                    ? '$count questions · 50s each'
                                    : 'Pass Stage $index to unlock',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: rewardLocked ? colors.tertiary : null,
                              fontWeight: rewardLocked ? FontWeight.w700 : null,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<GrammarLesson?> lessonValue =
        ref.watch(grammarLeafProvider(widget.lessonId));
    final AsyncValue<List<GrammarQuizStageProgress>> progressValue =
        ref.watch(grammarQuizStageProgressProvider(widget.lessonId));
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: lessonValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load quiz questions.')),
        data: (GrammarLesson? lesson) {
          if (lesson == null || lesson.quiz.isEmpty) {
            return const Center(child: Text('No quiz questions available.'));
          }
          return progressValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(
              child: Text('Could not load your saved Grammar quiz progress.'),
            ),
            data: (List<GrammarQuizStageProgress> rows) =>
                _buildLadder(context, lesson, rows),
          );
        },
      ),
    );
  }
}

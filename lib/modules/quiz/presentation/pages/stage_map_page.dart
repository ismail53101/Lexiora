import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_stage_progress.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_subject.dart';
import 'package:lexiora/modules/quiz/domain/quiz_stages.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/services/main_quiz_reward_unlock.dart';

/// The stage ladder for one subject (Phase v0.11.0): every 10-question slice
/// of the subject's pool as a card. Stage 1 is always open; each later stage
/// unlocks after the previous one is passed (>= 50%). Best score, stars and
/// attempts are shown per stage, and the grid is paginated so even 200+ stage
/// subjects stay clean.
class StageMapPage extends ConsumerStatefulWidget {
  const StageMapPage({
    super.key,
    required this.subjectId,
    this.topicId,
    this.title,
  });

  final String subjectId;
  final String? topicId;
  final String? title;

  @override
  ConsumerState<StageMapPage> createState() => _StageMapPageState();
}

class _StageMapPageState extends ConsumerState<StageMapPage> {
  static const int _pageSize = 18;
  int _page = 0;
  final Set<int> _earnedRewardUnlocksThisVisit = <int>{};
  bool _rewardFlowActive = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<QuizSubjectSummary> subjects =
        ref.watch(quizSubjectsProvider(false)).maybeWhen(
              data: (List<QuizSubjectSummary> s) => s,
              orElse: () => const <QuizSubjectSummary>[],
            );
    QuizSubject? subject;
    for (final QuizSubjectSummary s in subjects) {
      if (s.subject.id == widget.subjectId) {
        subject = s.subject;
        break;
      }
    }
    final Color color = subject?.colorValue ?? theme.colorScheme.primary;

    final QuizStageScope scope = QuizStageScope(
      subjectId: widget.subjectId,
      topicId: widget.topicId,
    );
    final int? stageCountValue =
        ref.watch(quizStageCountProvider(scope)).maybeWhen(
              data: (int n) => n,
              orElse: () => null,
            );
    final List<QuizStageProgress>? progressValue =
        ref.watch(quizStageProgressProvider(scope)).maybeWhen(
              data: (List<QuizStageProgress> p) => p,
              orElse: () => null,
            );
    final bool mainQuiz = isMainQuizScope(scope);
    final Set<int>? storedRewardUnlocks = mainQuiz
        ? ref.watch(quizMainRewardUnlocksProvider(widget.subjectId)).maybeWhen(
              data: (Set<int> stages) => stages,
              orElse: () => null,
            )
        : const <int>{};
    final String pageTitle = widget.title ?? subject?.name ?? 'Quiz';

    if (stageCountValue == null || progressValue == null ||
        storedRewardUnlocks == null) {
      return Scaffold(
        appBar: AppBar(title: Text(pageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final int stageCount = stageCountValue;
    final List<QuizStageProgress> progress = progressValue;
    final Set<int> rewardUnlocks = <int>{
      ...storedRewardUnlocks,
      ..._earnedRewardUnlocksThisVisit,
    };
    if (stageCount == 0) {
      return Scaffold(
        appBar: AppBar(title: Text(pageTitle)),
        body: const EmptyState(
          icon: Icons.flag_outlined,
          title: 'No stages yet',
          message: 'This subject needs questions before stages can be built.',
        ),
      );
    }

    final Set<int> passed =
        <int>{for (final QuizStageProgress p in progress) if (p.passed) p.stageIndex};
    int current = 0;
    if (mainQuiz) {
      // Progress is subject-scoped; retries do not increase the count because
      // each stage contributes at most one successful pass.
      current = stageCount - 1;
      for (int i = 0; i < stageCount; i++) {
        if (!passed.contains(i)) {
          current = i;
          break;
        }
      }
    } else {
      // Preserve the legacy ladder highlight behavior for topic/Grammar maps.
      for (int i = 0; i < stageCount; i++) {
        if (!passed.contains(i) && quizStageUnlocked(i, passed)) {
          current = i;
          break;
        }
        current = i;
      }
    }
    final Map<int, QuizStageProgress> byStage = <int, QuizStageProgress>{
      for (final QuizStageProgress p in progress) p.stageIndex: p,
    };

    final int totalPages = (stageCount + _pageSize - 1) ~/ _pageSize;
    if (_page >= totalPages) _page = totalPages - 1;
    if (_page < 0) _page = 0;
    final int from = _page * _pageSize;
    final int to = (from + _pageSize).clamp(0, stageCount);

    return Scaffold(
      appBar: AppBar(title: Text(subject?.name ?? 'Quiz')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _LadderHeader(
            color: color,
            passedCount: passed.length,
            stageCount: stageCount,
            mainQuiz: mainQuiz,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: to - from,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 148,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (BuildContext context, int i) {
              final int stage = from + i;
              final QuizStageProgress? p = byStage[stage];
              final bool unlocked = quizStageUnlocked(
                stage,
                passed,
                requireRewardedMilestones: mainQuiz,
                rewardedUnlockedStageIndices: rewardUnlocks,
              );
              final bool rewardLocked = mainQuiz &&
                  !unlocked &&
                  !passed.contains(stage) &&
                  !rewardUnlocks.contains(stage) &&
                  quizMilestoneEligible(stage, passed);
              return _StageCard(
                stageIndex: stage,
                color: color,
                isCurrent: mainQuiz
                    ? stage == current && (p == null || !p.passed) && unlocked
                    : stage == current && p == null,
                locked: !unlocked,
                rewardLocked: rewardLocked,
                progress: p,
                onTap: () => _open(stage, passed, rewardUnlocks, mainQuiz),
              ).animate().fadeIn(duration: 220.ms);
            },
          ),
          const SizedBox(height: 12),
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  onPressed:
                      _page == 0 ? null : () => setState(() => _page--),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous',
                ),
                Text(
                  'Stages ${from + 1}–$to of $stageCount',
                  style: theme.textTheme.labelLarge,
                ),
                IconButton(
                  onPressed: _page == totalPages - 1
                      ? null
                      : () => setState(() => _page++),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next',
                ),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _open(
    int stage,
    Set<int> passed,
    Set<int> rewardUnlocks,
    bool mainQuiz,
  ) async {
    final bool unlocked = quizStageUnlocked(
      stage,
      passed,
      requireRewardedMilestones: mainQuiz,
      rewardedUnlockedStageIndices: rewardUnlocks,
    );
    if (!unlocked) {
      if (mainQuiz && quizMilestoneEligible(stage, passed)) {
        await _requestMilestoneReward(stage);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mainQuiz
                ? 'Pass Stage $stage with at least 50% to unlock Stage ${stage + 1}.'
                : 'Pass Stage $stage with 50% to unlock it.',
          ),
        ),
      );
      return;
    }
    _pushStage(stage);
  }

  Future<void> _requestMilestoneReward(int stageIndex) async {
    if (_rewardFlowActive) return;
    _rewardFlowActive = true;
    try {
      final bool watch = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text('Unlock Stage ${stageIndex + 1}'),
              content: const Text(
                'Complete a rewarded ad to unlock this milestone stage for '
                'this subject. You can continue without watching it now.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Not now'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Watch ad'),
                ),
              ],
            ),
          ) ??
          false;
      if (!watch || !mounted) return;

      final RewardedAdManager manager = sl<RewardedAdManager>();
      final MainQuizRewardOutcome outcome =
          await requestMainQuizMilestoneUnlock(
        subjectId: widget.subjectId,
        stageIndex: stageIndex,
        placement: _rewardPlacementForSubject(widget.subjectId),
        repository: ref.read(quizRepositoryProvider),
        requestAd: ({
          required RewardedAdPlacement placement,
          required RewardCallback? onRewarded,
        }) =>
            manager.showRewarded(
          placement: placement,
          onRewarded: onRewarded,
        ),
      );
      if (!mounted) return;

      if (outcome.unlockPersisted) {
        setState(() => _earnedRewardUnlocksThisVisit.add(stageIndex));
        ref.invalidate(quizMainRewardUnlocksProvider(widget.subjectId));
        _pushStage(stageIndex);
        return;
      }

      final String message = switch (outcome.adResult) {
        RewardedAdResult.unavailable =>
          'A rewarded ad is not ready yet. Stage ${stageIndex + 1} remains locked; try again shortly.',
        RewardedAdResult.cooldown =>
          'Please wait before requesting another reward for this subject.',
        RewardedAdResult.rewarded =>
          'The reward was received, but its unlock could not be saved. Stage ${stageIndex + 1} remains locked.',
        RewardedAdResult.premium =>
          'Stage ${stageIndex + 1} unlocks only after the rewarded ad is completed.',
        RewardedAdResult.failed =>
          'The ad was not completed. Stage ${stageIndex + 1} remains locked.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      _rewardFlowActive = false;
    }
  }

  RewardedAdPlacement _rewardPlacementForSubject(String subjectId) =>
      switch (subjectId) {
        'pakistan-affairs' => RewardedAdPlacement.mainQuizPakistanAffairs,
        'islamic-studies' => RewardedAdPlacement.mainQuizIslamicStudies,
        'general-science-ability' =>
          RewardedAdPlacement.mainQuizGeneralScienceAbility,
        'english' => RewardedAdPlacement.mainQuizEnglish,
        _ => RewardedAdPlacement.quiz,
      };

  void _pushStage(int stage) {
    context.push(
        '${AppRoutes.quizStagePlay}?subjectId=${Uri.encodeComponent(widget.subjectId)}${widget.topicId == null ? '' : '&topicId=${Uri.encodeComponent(widget.topicId!)}'}${widget.title == null ? '' : '&title=${Uri.encodeComponent(widget.title!)}'}&stage=$stage');
  }
}

/// Ladder summary: passed count, overall progress and the unlock hint.
class _LadderHeader extends StatelessWidget {
  const _LadderHeader({
    required this.color,
    required this.passedCount,
    required this.stageCount,
    required this.mainQuiz,
  });

  final Color color;
  final int passedCount;
  final int stageCount;
  final bool mainQuiz;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double fraction = stageCount == 0 ? 0 : passedCount / stageCount;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.flag_outlined, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Stage ladder',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '$passedCount / $stageCount passed',
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mainQuiz
                  ? 'Each stage is 10 questions. Score at least 50% to pass; '
                      'watch a rewarded ad after every five passed stages.'
                  : 'Each stage is 10 questions. Score 50% or more to unlock '
                      'the next level.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stageIndex,
    required this.color,
    required this.isCurrent,
    required this.locked,
    required this.rewardLocked,
    required this.onTap,
    this.progress,
  });

  final int stageIndex;
  final Color color;
  final bool isCurrent;
  final bool locked;
  final bool rewardLocked;
  final QuizStageProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int number = stageIndex + 1;
    final Widget visual = _visual(theme);

    final Color borderColor;
    if (isCurrent) {
      borderColor = color;
    } else if (rewardLocked) {
      borderColor = color.withValues(alpha: 0.55);
    } else if (locked) {
      borderColor = theme.colorScheme.outlineVariant;
    } else {
      borderColor = Colors.transparent;
    }

    return Material(
      color: theme.colorScheme.surfaceContainerHigh.withValues(
          alpha: locked && !rewardLocked ? 0.45 : 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: isCurrent ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  visual,
                  const Spacer(),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PLAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    )
                  else if (rewardLocked)
                    Icon(Icons.lock_outline_rounded, size: 18, color: color)
                  else if (locked)
                    Icon(Icons.lock_outline,
                        size: 18, color: theme.colorScheme.outline)
                  else
                    Icon(Icons.check_circle,
                        size: 18, color: theme.colorScheme.primary),
                ],
              ),
              const Spacer(),
              Text(
                'Stage $number',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: locked ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _subtitle(theme),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: rewardLocked
                      ? color
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: rewardLocked ? FontWeight.w800 : null,
                  letterSpacing: rewardLocked ? 0.35 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _visual(ThemeData theme) {
    if (rewardLocked) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.play_circle_outline_rounded, size: 20, color: color),
      );
    }
    if (locked) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.lock_outline,
            size: 18, color: theme.colorScheme.outline),
      );
    }
    if (progress == null) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.play_arrow_rounded, size: 22, color: color),
      );
    }
    // Completed / attempted — best-score ring + stars.
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CircularProgressIndicator(
            value: progress!.bestScore / 100,
            strokeWidth: 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: color,
          ),
          Center(
            child: Text(
              '${progress!.bestScore}%',
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w800, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(ThemeData theme) {
    if (rewardLocked) return 'WATCH AD TO CONTINUE';
    if (locked) return 'Pass Stage $stageIndex to unlock';
    if (progress == null) return '10 questions · 50s each';
    final String stars = '★' * progress!.bestStars +
        '☆' * (3 - progress!.bestStars);
    return 'Best $stars · ${progress!.attempts} attempt'
        '${progress!.attempts == 1 ? '' : 's'}';
  }
}

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/modules/grammar/data/datasources/grammar_local_data_source.dart';
import 'package:lexiora/modules/grammar/data/repositories/grammar_repository_impl.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_quiz_stage_progress.dart';
import 'package:lexiora/modules/grammar/domain/grammar_quiz_stages.dart';
import 'package:lexiora/modules/grammar/domain/repositories/grammar_repository.dart';
import 'package:lexiora/modules/grammar/presentation/services/grammar_quiz_reward_unlock.dart';

void main() {
  late AppDatabase db;
  late GrammarRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = GrammarRepositoryImpl(GrammarLocalDataSource(db));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> passStages(String quizId, int lastIndex) async {
    for (int stageIndex = 0; stageIndex <= lastIndex; stageIndex++) {
      await repository.recordGrammarQuizStageResult(
        quizId: quizId,
        stageIndex: stageIndex,
        correct: 5,
        total: 10,
      );
    }
  }

  Future<GrammarQuizRewardOutcome> requestUnlock({
    required String quizId,
    required int stageIndex,
    required GrammarRewardedAdRequest requestAd,
  }) =>
      requestGrammarQuizMilestoneUnlock(
        quizId: quizId,
        stageIndex: stageIndex,
        repository: repository,
        requestAd: requestAd,
      );

  test('all three quiz ladders persist independent stage-5 unlocks', () async {
    for (final String quizId in stagedGrammarQuizIds) {
      await passStages(quizId, 3);
      final GrammarQuizRewardOutcome outcome = await requestUnlock(
        quizId: quizId,
        stageIndex: 4,
        requestAd: ({
          required RewardedAdPlacement placement,
          required RewardCallback? onRewarded,
        }) async {
          expect(placement, RewardedAdPlacement.grammarQuiz);
          await onRewarded?.call();
          return RewardedAdResult.rewarded;
        },
      );
      expect(outcome.unlockPersisted, isTrue, reason: quizId);

      final List<GrammarQuizStageProgress> rows =
          await repository.grammarQuizStageProgress(quizId);
      expect(
        rows.where((GrammarQuizStageProgress row) => row.passed)
            .map((GrammarQuizStageProgress row) => row.stageIndex)
            .toSet(),
        <int>{0, 1, 2, 3},
      );
      expect(rows.singleWhere((row) => row.stageIndex == 4).rewardedUnlocked,
          isTrue);
      expect(
        isGrammarQuizStageUnlocked(
          stageIndex: 4,
          passedStages: rows
              .where((GrammarQuizStageProgress row) => row.passed)
              .map((GrammarQuizStageProgress row) => row.stageIndex)
              .toSet(),
          rewardedStages: rows
              .where((GrammarQuizStageProgress row) => row.rewardedUnlocked)
              .map((GrammarQuizStageProgress row) => row.stageIndex)
              .toSet(),
        ),
        isTrue,
      );
    }
  });

  test('an ad failure does not save a milestone unlock', () async {
    await passStages('pos/quiz', 3);
    final GrammarQuizRewardOutcome outcome = await requestUnlock(
      quizId: 'pos/quiz',
      stageIndex: 4,
      requestAd: ({
        required RewardedAdPlacement placement,
        required RewardCallback? onRewarded,
      }) async => RewardedAdResult.failed,
    );

    expect(outcome.unlockPersisted, isFalse);
    expect(
      (await repository.grammarQuizStageProgress('pos/quiz'))
          .where((GrammarQuizStageProgress row) => row.rewardedUnlocked),
      isEmpty,
    );
  });

  test('an ad result without the official earned callback cannot unlock',
      () async {
    await passStages('pos/quiz', 3);
    final GrammarQuizRewardOutcome outcome = await requestUnlock(
      quizId: 'pos/quiz',
      stageIndex: 4,
      requestAd: ({
        required RewardedAdPlacement placement,
        required RewardCallback? onRewarded,
      }) async => RewardedAdResult.rewarded,
    );

    expect(outcome.adResult, RewardedAdResult.rewarded);
    expect(outcome.unlockPersisted, isFalse);
    expect(
      (await repository.grammarQuizStageProgress('pos/quiz'))
          .where((GrammarQuizStageProgress row) => row.rewardedUnlocked),
      isEmpty,
    );
  });

  test('only the earned callback writes, and duplicate callbacks are safe',
      () async {
    await passStages('active-passive-voice/practice-quiz', 3);
    final GrammarQuizRewardOutcome outcome = await requestUnlock(
      quizId: 'active-passive-voice/practice-quiz',
      stageIndex: 4,
      requestAd: ({
        required RewardedAdPlacement placement,
        required RewardCallback? onRewarded,
      }) async {
        await onRewarded?.call();
        await onRewarded?.call();
        return RewardedAdResult.rewarded;
      },
    );

    expect(outcome.unlockPersisted, isTrue);
    final List<GrammarQuizStageProgress> rows = await repository
        .grammarQuizStageProgress('active-passive-voice/practice-quiz');
    expect(rows.where((row) => row.rewardedUnlocked).length, 1);
    expect(
      await repository.grammarQuizStageProgress('pos/quiz'),
      isEmpty,
    );
    expect(
      await repository
          .grammarQuizStageProgress('direct-indirect-speech/practice-quiz'),
      isEmpty,
    );
    expect(
      isGrammarQuizStageUnlocked(
        stageIndex: 4,
        passedStages: <int>{},
        rewardedStages: <int>{},
      ),
      isFalse,
      reason: 'another Grammar quiz starts with its Stage 5 gate locked',
    );
  });

  test('a milestone cannot be granted before all earlier stages pass',
      () async {
    expect(
      await repository.grantGrammarQuizMilestoneUnlock(
        quizId: 'pos/quiz',
        stageIndex: 4,
      ),
      isFalse,
    );
    await passStages('pos/quiz', 2);
    expect(
      await repository.grantGrammarQuizMilestoneUnlock(
        quizId: 'pos/quiz',
        stageIndex: 4,
      ),
      isFalse,
    );
    await expectLater(
      repository.recordGrammarQuizStageResult(
        quizId: 'pos/quiz',
        stageIndex: 4,
        correct: 10,
        total: 10,
      ),
      throwsStateError,
    );
  });

  test('inline lesson quizzes cannot be stored as staged Grammar progress',
      () async {
    await expectLater(
      repository.recordGrammarQuizStageResult(
        quizId: 'modals/can',
        stageIndex: 0,
        correct: 3,
        total: 3,
      ),
      throwsArgumentError,
    );
  });

  test('progress and unlock survive closing and reopening the database',
      () async {
    final Directory directory =
        await Directory.systemTemp.createTemp('grammar_quiz_progress_');
    final File file = File('${directory.path}/lexiora.db');
    AppDatabase persistentDb = AppDatabase(NativeDatabase(file));
    try {
      GrammarRepository persistentRepository = GrammarRepositoryImpl(
        GrammarLocalDataSource(persistentDb),
      );
      for (final int stageIndex in <int>[0, 1, 2, 3]) {
        await persistentRepository.recordGrammarQuizStageResult(
          quizId: 'direct-indirect-speech/practice-quiz',
          stageIndex: stageIndex,
          correct: 7,
          total: 10,
        );
      }
      final GrammarQuizRewardOutcome outcome =
          await requestGrammarQuizMilestoneUnlock(
        quizId: 'direct-indirect-speech/practice-quiz',
        stageIndex: 4,
        repository: persistentRepository,
        requestAd: ({
          required RewardedAdPlacement placement,
          required RewardCallback? onRewarded,
        }) async {
          await onRewarded?.call();
          return RewardedAdResult.rewarded;
        },
      );
      expect(outcome.unlockPersisted, isTrue);
      await persistentDb.close();

      persistentDb = AppDatabase(NativeDatabase(file));
      persistentRepository = GrammarRepositoryImpl(
        GrammarLocalDataSource(persistentDb),
      );
      final List<GrammarQuizStageProgress> restored = await persistentRepository
          .grammarQuizStageProgress('direct-indirect-speech/practice-quiz');
      expect(
        restored.where((row) => row.passed).map((row) => row.stageIndex),
        containsAll(<int>[0, 1, 2, 3]),
      );
      expect(restored.singleWhere((row) => row.stageIndex == 4).rewardedUnlocked,
          isTrue);
    } finally {
      await persistentDb.close();
      await directory.delete(recursive: true);
    }
  });
}

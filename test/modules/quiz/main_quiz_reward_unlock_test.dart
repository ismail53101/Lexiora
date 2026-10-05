import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/modules/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:lexiora/modules/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:lexiora/modules/quiz/presentation/services/main_quiz_reward_unlock.dart';

void main() {
  late AppDatabase db;
  late QuizRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = QuizRepositoryImpl(QuizLocalDataSource(db));
    for (int stage = 0; stage < 5; stage++) {
      await repository.saveStageResult(
        subjectId: 'pakistan-affairs',
        stageIndex: stage,
        correct: 5,
        total: 10,
      );
    }
  });

  tearDown(() async {
    await db.close();
  });

  test('each Main Quiz subject uses its own rewarded placement', () {
    expect(
      mainQuizRewardPlacementForSubject('pakistan-affairs'),
      RewardedAdPlacement.mainQuizPakistanAffairs,
    );
    expect(
      mainQuizRewardPlacementForSubject('islamic-studies'),
      RewardedAdPlacement.mainQuizIslamicStudies,
    );
    expect(
      mainQuizRewardPlacementForSubject('general-science-ability'),
      RewardedAdPlacement.mainQuizGeneralScienceAbility,
    );
    expect(
      mainQuizRewardPlacementForSubject('english'),
      RewardedAdPlacement.mainQuizEnglish,
    );
    expect(
      () => mainQuizRewardPlacementForSubject('custom-subject'),
      throwsArgumentError,
    );
  });

  Future<MainQuizRewardOutcome> runFlow({
    required MainQuizRewardedAdRequest request,
  }) =>
      requestMainQuizMilestoneUnlock(
        subjectId: 'pakistan-affairs',
        stageIndex: 5,
        placement: RewardedAdPlacement.mainQuizPakistanAffairs,
        repository: repository,
        requestAd: request,
      );

  test('an unearned/failed ad does not persist an unlock', () async {
    final MainQuizRewardOutcome outcome = await runFlow(
      request: ({
        required RewardedAdPlacement placement,
        required RewardCallback? onRewarded,
      }) async => RewardedAdResult.failed,
    );

    expect(outcome.unlockPersisted, isFalse);
    expect(
      await repository.mainQuizRewardedMilestoneStages('pakistan-affairs'),
      isEmpty,
    );
  });

  test('an ad result alone cannot unlock without the earned callback',
      () async {
    final MainQuizRewardOutcome outcome = await runFlow(
      request: ({
        required RewardedAdPlacement placement,
        required RewardCallback? onRewarded,
      }) async => RewardedAdResult.rewarded,
    );

    expect(outcome.adResult, RewardedAdResult.rewarded);
    expect(outcome.unlockPersisted, isFalse);
    expect(
      await repository.mainQuizRewardedMilestoneStages('pakistan-affairs'),
      isEmpty,
    );
  });

  test('official earned callback persists the subject milestone', () async {
    final MainQuizRewardOutcome outcome = await runFlow(
      request: ({
        required RewardedAdPlacement placement,
        required RewardCallback? onRewarded,
      }) async {
        await onRewarded?.call();
        return RewardedAdResult.rewarded;
      },
    );

    expect(outcome.unlockPersisted, isTrue);
    expect(
      await repository.mainQuizRewardedMilestoneStages('pakistan-affairs'),
      <int>{5},
    );
    expect(
      await repository.mainQuizRewardedMilestoneStages('islamic-studies'),
      isEmpty,
    );
  });

  test('duplicate earned callbacks remain idempotent', () async {
    final MainQuizRewardOutcome outcome = await runFlow(
      request: ({
        required RewardedAdPlacement placement,
        required RewardCallback? onRewarded,
      }) async {
        await onRewarded?.call();
        await onRewarded?.call();
        return RewardedAdResult.rewarded;
      },
    );

    expect(outcome.unlockPersisted, isTrue);
    expect(
      await repository.mainQuizRewardedMilestoneStages('pakistan-affairs'),
      <int>{5},
    );
  });
}

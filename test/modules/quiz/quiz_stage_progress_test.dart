import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:lexiora/modules/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_stage_progress.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_subject.dart';
import 'package:lexiora/modules/quiz/domain/quiz_stages.dart';

/// Verifies the staged-quiz data path against a real in-memory database:
/// deterministic stages with preserved sizes and the best-result merge on
/// `saveStageResult` (best score/stars kept, attempt count incremented,
/// passed latches true).
void main() {
  late AppDatabase db;
  late QuizRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = QuizRepositoryImpl(QuizLocalDataSource(db));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedSubject(int questionCount) async {
    final DateTime now = DateTime.now();
    await repo.saveSubject(QuizSubject(
      id: 'sub',
      name: 'Pakistan Affairs',
      createdAt: now,
      updatedAt: now,
    ));
    for (int i = 0; i < questionCount; i++) {
      await repo.saveQuestion(QuizQuestion(
        id: 'q${i.toString().padLeft(3, '0')}',
        bankId: 'bank1',
        type: QuestionType.mcqSingle,
        prompt: 'Question $i',
        options: const <String>['A', 'B', 'C', 'D'],
        answerIndex: 0,
        subject: 'Pakistan Affairs',
        subjectId: 'sub',
        createdAt: now,
        updatedAt: now,
      ));
    }
  }

  test('stage slicing preserves exact ladder sizes without overlap', () async {
    await seedSubject(25);

    expect(await repo.stageQuestionCount('sub'), 25);
    expect(quizStageCount(25), 3);

    final List<QuizQuestion> s0 = await repo.stageQuestions('sub', 0);
    final List<QuizQuestion> s1 = await repo.stageQuestions('sub', 1);
    final List<QuizQuestion> s2 = await repo.stageQuestions('sub', 2);
    final List<QuizQuestion> s3 = await repo.stageQuestions('sub', 3);

    expect(s0.length, 10);
    expect(s1.length, 10);
    expect(s2.length, 5);
    expect(s3, isEmpty);

    expect(s0.every((QuizQuestion q) => q.subjectId == 'sub'), isTrue);
    expect(s1.every((QuizQuestion q) => q.subjectId == 'sub'), isTrue);
    expect(s2.every((QuizQuestion q) => q.subjectId == 'sub'), isTrue);
    expect(<String>{...s0.map((QuizQuestion q) => q.id)}.length, 10);
    expect(<String>{...s1.map((QuizQuestion q) => q.id)}.length, 10);
    expect(<String>{...s2.map((QuizQuestion q) => q.id)}.length, 5);
  });

  test('saveStageResult records the result and keeps the best', () async {
    await seedSubject(10);

    await repo.saveStageResult(
        subjectId: 'sub', stageIndex: 0, correct: 7, total: 10);

    List<QuizStageProgress> progress = await repo.watchStageProgress('sub').first;
    expect(progress, hasLength(1));
    expect(progress.single.bestScore, 70);
    expect(progress.single.bestStars, 2);
    expect(progress.single.attempts, 1);
    expect(progress.single.passed, isTrue);

    // A worse attempt must not overwrite the best result.
    await repo.saveStageResult(
        subjectId: 'sub', stageIndex: 0, correct: 3, total: 10);

    progress = await repo.watchStageProgress('sub').first;
    expect(progress.single.bestScore, 70, reason: 'best score is kept');
    expect(progress.single.bestStars, 2, reason: 'best stars are kept');
    expect(progress.single.attempts, 2, reason: 'attempt count increments');
    expect(progress.single.passed, isTrue, reason: 'passed latches');
  });

  test('Main Quiz milestones use unique successful passes per subject',
      () async {
    // Four passed stages plus a failed fifth stage do not satisfy the first
    // milestone. Failed attempts are stored, but never count as completions.
    for (int stage = 0; stage < 4; stage++) {
      await repo.saveStageResult(
        subjectId: 'pakistan-affairs',
        stageIndex: stage,
        correct: 5,
        total: 10,
      );
    }
    await repo.saveStageResult(
      subjectId: 'pakistan-affairs',
      stageIndex: 4,
      correct: 4,
      total: 10,
    );
    List<QuizStageProgress> pakistanProgress =
        await repo.watchStageProgress('pakistan-affairs').first;
    Set<int> pakistanPassed = <int>{
      for (final QuizStageProgress item in pakistanProgress)
        if (item.passed) item.stageIndex,
    };
    expect(quizConsecutivePassedStages(pakistanPassed), 4);
    expect(quizMilestoneEligible(5, pakistanPassed), isFalse);
    expect(
      await repo.grantMainQuizMilestoneUnlock(
        subjectId: 'pakistan-affairs',
        stageIndex: 5,
      ),
      isFalse,
    );

    // Pass Stage 5. Repeating Stage 1 does not inflate the unique count.
    await repo.saveStageResult(
      subjectId: 'pakistan-affairs',
      stageIndex: 4,
      correct: 5,
      total: 10,
    );
    await repo.saveStageResult(
      subjectId: 'pakistan-affairs',
      stageIndex: 0,
      correct: 10,
      total: 10,
    );
    pakistanProgress =
        await repo.watchStageProgress('pakistan-affairs').first;
    pakistanPassed = <int>{
      for (final QuizStageProgress item in pakistanProgress)
        if (item.passed) item.stageIndex,
    };
    expect(pakistanPassed.length, 5);
    expect(quizMilestoneEligible(5, pakistanPassed), isTrue);
    expect(
      quizStageUnlocked(
        5,
        pakistanPassed,
        requireRewardedMilestones: true,
      ),
      isFalse,
    );

    expect(
      await repo.grantMainQuizMilestoneUnlock(
        subjectId: 'pakistan-affairs',
        stageIndex: 5,
      ),
      isTrue,
    );
    Set<int> pakistanUnlocks =
        await repo.mainQuizRewardedMilestoneStages('pakistan-affairs');
    expect(
      quizStageUnlocked(
        5,
        pakistanPassed,
        requireRewardedMilestones: true,
        rewardedUnlockedStageIndices: pakistanUnlocks,
      ),
      isTrue,
    );
    for (final String otherSubject in <String>[
      'islamic-studies',
      'general-science-ability',
      'english',
    ]) {
      final List<QuizStageProgress> otherProgress =
          await repo.watchStageProgress(otherSubject).first;
      final Set<int> otherPassed = <int>{
        for (final QuizStageProgress item in otherProgress)
          if (item.passed) item.stageIndex,
      };
      expect(
        quizStageUnlocked(
          5,
          otherPassed,
          requireRewardedMilestones: true,
          rewardedUnlockedStageIndices:
              await repo.mainQuizRewardedMilestoneStages(otherSubject),
        ),
        isFalse,
        reason: 'Pakistan Affairs unlock must not affect $otherSubject',
      );
    }

    // Stage 6 is passed; stages 7–10 remain free. Stage 11 is the next gate.
    for (int stage = 5; stage < 10; stage++) {
      await repo.saveStageResult(
        subjectId: 'pakistan-affairs',
        stageIndex: stage,
        correct: 5,
        total: 10,
      );
    }
    pakistanProgress =
        await repo.watchStageProgress('pakistan-affairs').first;
    pakistanPassed = <int>{
      for (final QuizStageProgress item in pakistanProgress)
        if (item.passed) item.stageIndex,
    };
    expect(
      quizStageUnlocked(
        6,
        pakistanPassed,
        requireRewardedMilestones: true,
        rewardedUnlockedStageIndices: pakistanUnlocks,
      ),
      isTrue,
    );
    expect(quizMilestoneEligible(10, pakistanPassed), isTrue);
    expect(
      quizStageUnlocked(
        10,
        pakistanPassed,
        requireRewardedMilestones: true,
        rewardedUnlockedStageIndices: pakistanUnlocks,
      ),
      isFalse,
    );

    // The same progress and reward keys are not shared with Islamic Studies.
    for (int stage = 0; stage < 5; stage++) {
      await repo.saveStageResult(
        subjectId: 'islamic-studies',
        stageIndex: stage,
        correct: 5,
        total: 10,
      );
    }
    final Set<int> islamicPassed = <int>{0, 1, 2, 3, 4};
    expect(
      quizStageUnlocked(
        5,
        islamicPassed,
        requireRewardedMilestones: true,
        rewardedUnlockedStageIndices:
            await repo.mainQuizRewardedMilestoneStages('islamic-studies'),
      ),
      isFalse,
    );
    expect(
      await repo.grantMainQuizMilestoneUnlock(
        subjectId: 'islamic-studies',
        stageIndex: 5,
      ),
      isTrue,
    );
    expect(
      await repo.mainQuizRewardedMilestoneStages('islamic-studies'),
      <int>{5},
    );
    expect(
      await repo.mainQuizRewardedMilestoneStages('general-science-ability'),
      isEmpty,
    );
    expect(await repo.mainQuizRewardedMilestoneStages('english'), isEmpty);
  });

  test('a failing stage stores a failed result (no unlock)', () async {
    await seedSubject(10);

    await repo.saveStageResult(
        subjectId: 'sub', stageIndex: 1, correct: 2, total: 10);

    final List<QuizStageProgress> progress =
        await repo.watchStageProgress('sub').first;
    expect(progress.single.stageIndex, 1);
    expect(progress.single.bestScore, 20);
    expect(progress.single.bestStars, 0);
    expect(progress.single.passed, isFalse);
    // Stage 1 stays locked because stage 0 was never passed.
    expect(
        quizStageUnlocked(1,
            <int>{for (final QuizStageProgress p in progress) if (p.passed) p.stageIndex}),
        isFalse);
  });
}

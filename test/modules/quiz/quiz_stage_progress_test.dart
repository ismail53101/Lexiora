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

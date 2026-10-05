import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/modules/grammar/data/datasources/grammar_local_data_source.dart';
import 'package:lexiora/modules/grammar/data/repositories/grammar_repository_impl.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/grammar_quiz_stages.dart';
import 'package:lexiora/modules/grammar/presentation/pages/pos_quiz_stage_map_page.dart';
import 'package:lexiora/modules/grammar/presentation/providers/grammar_providers.dart';

class _FakeRewardedAdManager extends RewardedAdManager {
  _FakeRewardedAdManager() : super(isPremium: () async => false);

  int requestCount = 0;

  @override
  Future<RewardedAdResult> showRewarded({
    required RewardedAdPlacement placement,
    RewardCallback? onRewarded,
  }) async {
    requestCount++;
    if (placement != RewardedAdPlacement.grammarQuiz) {
      throw StateError('Unexpected rewarded placement: $placement');
    }
    await onRewarded?.call();
    return RewardedAdResult.rewarded;
  }
}

GrammarLesson _lesson(String quizId) => GrammarLesson(
      id: quizId,
      title: 'Test Grammar Quiz',
      quiz: List<GrammarQuestion>.generate(
        50,
        (int index) => GrammarQuestion(
          question: 'Question $index?',
          options: const <String>['Choice A', 'Choice B', 'Choice C', 'Choice D'],
          answerIndex: 0,
        ),
      ),
    );

Future<void> _passPriorStages(
  GrammarRepositoryImpl repository,
  String quizId,
  int lastStageIndex,
) async {
  for (int stageIndex = 0; stageIndex <= lastStageIndex; stageIndex++) {
    await repository.recordGrammarQuizStageResult(
      quizId: quizId,
      stageIndex: stageIndex,
      correct: 5,
      total: 10,
    );
  }
}

void main() {
  for (final String quizId in stagedGrammarQuizIds) {
    testWidgets('$quizId Stage 5 opens only after an earned ad unlock',
        (WidgetTester tester) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final GrammarRepositoryImpl repository =
          GrammarRepositoryImpl(GrammarLocalDataSource(db));
      await _passPriorStages(repository, quizId, 3);
      final _FakeRewardedAdManager ads = _FakeRewardedAdManager();
      final GrammarLesson lesson = _lesson(quizId);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            grammarRepositoryProvider.overrideWithValue(repository),
            grammarLeafProvider(quizId)
                .overrideWith((Ref ref) async => lesson),
            grammarRewardedAdManagerProvider.overrideWithValue(ads),
          ],
          child: MaterialApp(
            home: PosQuizStageMapPage(
              lessonId: quizId,
              title: 'Test Grammar Quiz',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stage 5'), findsOneWidget);
      expect(find.text('WATCH AD TO CONTINUE'), findsOneWidget);
      expect(ads.requestCount, 0);

      await tester.tap(find.text('WATCH AD TO CONTINUE'));
      await tester.pumpAndSettle();

      expect(ads.requestCount, 1);
      expect(find.text('Stage 5'), findsOneWidget);
      expect(
        (await repository.grammarQuizStageProgress(quizId))
            .singleWhere((row) => row.stageIndex == 4)
            .rewardedUnlocked,
        isTrue,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets('NOT NOW returns to stages without requesting or granting an ad',
      (WidgetTester tester) async {
    const String quizId = 'pos/quiz';
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final GrammarRepositoryImpl repository =
        GrammarRepositoryImpl(GrammarLocalDataSource(db));
    await _passPriorStages(repository, quizId, 2);
    final _FakeRewardedAdManager ads = _FakeRewardedAdManager();
    final GrammarLesson lesson = _lesson(quizId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          grammarRepositoryProvider.overrideWithValue(repository),
          grammarLeafProvider(quizId).overrideWith((Ref ref) async => lesson),
          grammarRewardedAdManagerProvider.overrideWithValue(ads),
        ],
        child: MaterialApp(
          home: PosQuizStageMapPage(lessonId: quizId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stage 4'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of 10'), findsOneWidget);

    for (int question = 0; question < 10; question++) {
      await tester.tap(find.text('Choice A').first);
      await tester.pump();
      await tester.tap(find.text(question == 9 ? 'FINISH' : 'NEXT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Stage 5 requires a rewarded ad.'),
      findsOneWidget,
    );
    expect(find.text('NOT NOW'), findsOneWidget);
    await tester.tap(find.text('NOT NOW'));
    await tester.pumpAndSettle();

    expect(ads.requestCount, 0);
    expect(find.text('WATCH AD TO CONTINUE'), findsOneWidget);
    expect(
      (await repository.grammarQuizStageProgress(quizId))
          .where((row) => row.rewardedUnlocked),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

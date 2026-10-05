import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/core/services/ad_return_navigation_scope.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_stage_progress.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_repository.dart';
import 'package:lexiora/modules/quiz/presentation/pages/stage_player_page.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';

const String _gsaSubjectId = 'general-science-ability';

class _StagePlayerRepository implements QuizRepository {
  final List<QuizQuestion> _questions = <QuizQuestion>[
    QuizQuestion(
      id: 'gsa-stage-six-question',
      bankId: 'gsa-test-bank',
      type: QuestionType.mcqSingle,
      prompt: 'Test question for GSA Stage 6?',
      options: const <String>['Option A', 'Option B'],
      answerIndex: 0,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
  ];

  @override
  Stream<List<QuizStageProgress>> watchStageProgress(
    String subjectId, {
    String? topicId,
  }) =>
      Stream<List<QuizStageProgress>>.value(
        List<QuizStageProgress>.generate(
          5,
          (int stageIndex) => QuizStageProgress(
            subjectId: subjectId,
            stageIndex: stageIndex,
            bestScore: 50,
            bestStars: 1,
            attempts: 1,
            passed: true,
          ),
        ),
      );

  @override
  Future<Set<int>> mainQuizRewardedMilestoneStages(String subjectId) async =>
      <int>{5};

  @override
  Future<List<QuizQuestion>> stageQuestions(
    String subjectId,
    int stageIndex, {
    int perStage = 10,
    String? topicId,
  }) async =>
      _questions;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PendingInterstitialManager extends RewardedAdManager {
  _PendingInterstitialManager(this.pendingResult)
      : super(isPremium: () async => false);

  final Completer<bool> pendingResult;
  int requestCount = 0;

  @override
  Future<bool> showReturnInterstitial() {
    requestCount++;
    return pendingResult.future;
  }
}

class _FailingInterstitialManager extends RewardedAdManager {
  _FailingInterstitialManager() : super(isPremium: () async => false);

  int requestCount = 0;

  @override
  Future<bool> showReturnInterstitial() async {
    requestCount++;
    throw StateError('Simulated interstitial failure');
  }
}

GoRouter _stagePlayerRouter() => GoRouter(
      initialLocation:
          '/quiz/stage-play?subjectId=$_gsaSubjectId&stage=5',
      routes: <RouteBase>[
        GoRoute(
          path: '/quiz/stage-map/:subjectId',
          builder: (BuildContext context, GoRouterState state) => Scaffold(
            body: Center(
              child: Text('Stage Map: ${state.pathParameters['subjectId']}'),
            ),
          ),
        ),
        GoRoute(
          path: '/quiz/stage-play',
          builder: (BuildContext context, GoRouterState state) {
            final Map<String, String> query = state.uri.queryParameters;
            return StagePlayerPage(
              subjectId: query['subjectId']!,
              stageIndex: int.parse(query['stage']!),
            );
          },
        ),
      ],
    );

Future<GoRouter> _pumpGsaStageSix(WidgetTester tester) async {
  final GoRouter router = _stagePlayerRouter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        quizRepositoryProvider.overrideWithValue(_StagePlayerRepository()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Stage 6'), findsOneWidget);
  expect(find.text('Test question for GSA Stage 6?'), findsOneWidget);
  return router;
}

Future<void> _pushScopedFeature(
  WidgetTester tester,
  RewardedAdManager manager,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => AdReturnNavigationScope(
                    manager: manager,
                    child: const Scaffold(
                      body: Center(child: Text('Scoped feature')),
                    ),
                  ),
                ),
              ),
              child: const Text('Open feature'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open feature'));
  await tester.pumpAndSettle();
  expect(find.text('Scoped feature'), findsOneWidget);
}

void main() {
  testWidgets('GSA Stage 6 AppBar Back returns directly to its Stage Map',
      (WidgetTester tester) async {
    final GoRouter router = await _pumpGsaStageSix(tester);
    addTearDown(router.dispose);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Stage Map: $_gsaSubjectId'), findsOneWidget);
    expect(find.text('Stage 6'), findsNothing);
  });

  testWidgets('Android system Back from GSA Stage 6 returns to its Stage Map',
      (WidgetTester tester) async {
    final GoRouter router = await _pumpGsaStageSix(tester);
    addTearDown(router.dispose);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Stage Map: $_gsaSubjectId'), findsOneWidget);
    expect(find.text('Stage 6'), findsNothing);
  });

  testWidgets(
      'return navigation does not wait for a missing interstitial terminal callback',
      (WidgetTester tester) async {
    final Completer<bool> neverCompletes = Completer<bool>();
    final _PendingInterstitialManager manager =
        _PendingInterstitialManager(neverCompletes);
    await _pushScopedFeature(tester, manager);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Open feature'), findsOneWidget);
    expect(find.text('Scoped feature'), findsNothing);
    expect(manager.requestCount, 1);

    // Release the deliberately pending test future so it does not leak beyond
    // this test; navigation already completed before this terminal result.
    neverCompletes.complete(false);
    await tester.pump();
  });

  testWidgets('return navigation continues when an interstitial attempt throws',
      (WidgetTester tester) async {
    final _FailingInterstitialManager manager = _FailingInterstitialManager();
    await _pushScopedFeature(tester, manager);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Open feature'), findsOneWidget);
    expect(find.text('Scoped feature'), findsNothing);
    expect(manager.requestCount, 1);
  });
}

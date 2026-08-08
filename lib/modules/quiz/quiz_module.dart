import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/modules/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:lexiora/modules/quiz/data/quiz_seeder.dart';
import 'package:lexiora/modules/quiz/data/repositories/quiz_admin_repository_impl.dart';
import 'package:lexiora/modules/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_admin_repository.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_repository.dart';
import 'package:lexiora/modules/quiz/presentation/pages/bookmarks_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/quiz_analytics_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/quiz_home_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/quiz_player_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/quiz_search_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/quiz_settings_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/stage_map_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/stage_player_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/subject_detail_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/subjects_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/topic_detail_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/wrong_answers_page.dart';

/// Phase v0.9.0 (engine) / v0.9.1 (subject-first) / v0.9.2 (learning-only).
///
/// A fully independent, content-agnostic [FeatureModule]. The app is a LEARNING
/// surface only: it displays subjects → topics → quizzes and *reads* published
/// content. It contains NO admin/content-management UI, and no navigation to
/// any authoring, import, export or publishing screens. Those internals
/// (repositories, JSON loader, question providers, import/export services)
/// remain as architecture for a future standalone **Sapiora CMS**, which will
/// publish content via Local JSON / Cloud — the app never knows the source. A
/// tiny bundled demo is seeded once as read-only published content.
class QuizModule extends FeatureModule {
  @override
  String get id => 'quiz';

  @override
  String get name => 'Quiz Engine';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      ..registerLazySingleton<QuizLocalDataSource>(
        () => QuizLocalDataSource(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<QuizRepository>(
        () => QuizRepositoryImpl(getIt<QuizLocalDataSource>()),
      )
      ..registerLazySingleton<QuizAdminRepository>(
        () => QuizAdminRepositoryImpl(getIt<QuizRepository>()),
      )
      ..registerLazySingleton<QuizSeeder>(
        () => QuizSeeder(
            getIt<QuizRepository>(), getIt<QuizLocalDataSource>()),
      );
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.quiz,
          builder: (_, _) => const QuizHomePage(),
        ),
        GoRoute(
          path: AppRoutes.quizMcqs,
          builder: (_, _) =>
              const SubjectsPage(variant: QuizSubjectsVariant.mcqs),
        ),
        GoRoute(
          path: AppRoutes.quizStages,
          builder: (_, _) =>
              const SubjectsPage(variant: QuizSubjectsVariant.stages),
        ),
        GoRoute(
          path: AppRoutes.quizStageMapPattern,
          name: AppRoutes.quizStageMapName,
          builder: (BuildContext context, GoRouterState state) => StageMapPage(
              subjectId: state.pathParameters['subjectId'] ?? ''),
        ),
        GoRoute(
          path: AppRoutes.quizStagePlay,
          builder: (BuildContext context, GoRouterState state) {
            final Map<String, String> q = state.uri.queryParameters;
            return StagePlayerPage(
              subjectId: q['subjectId'] ?? '',
              stageIndex: int.tryParse(q['stage'] ?? '') ?? 0,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.quizSubjectPattern,
          name: AppRoutes.quizSubjectName,
          builder: (BuildContext context, GoRouterState state) =>
              SubjectDetailPage(subjectId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: AppRoutes.quizTopicPattern,
          name: AppRoutes.quizTopicName,
          builder: (BuildContext context, GoRouterState state) =>
              TopicDetailPage(topicId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: AppRoutes.quizPlayer,
          builder: (BuildContext context, GoRouterState state) {
            final Map<String, String> q = state.uri.queryParameters;
            final QuizMode mode = QuizMode.values.firstWhere(
              (QuizMode m) => m.name == (q['mode'] ?? QuizMode.practice.name),
              orElse: () => QuizMode.practice,
            );
            return QuizPlayerPage(
              bankId: q['bank'],
              subjectId: q['subject'],
              topicId: q['topic'],
              mode: mode,
              onlyWrong: q['wrong'] == '1',
              onlyBookmarked: q['bookmarked'] == '1',
            );
          },
        ),
        GoRoute(
          path: AppRoutes.quizAnalytics,
          builder: (_, _) => const QuizAnalyticsPage(),
        ),
        GoRoute(
          path: AppRoutes.quizWrong,
          builder: (_, _) => const WrongAnswersPage(),
        ),
        GoRoute(
          path: AppRoutes.quizBookmarks,
          builder: (_, _) => const BookmarksPage(),
        ),
        GoRoute(
          path: AppRoutes.quizSearch,
          builder: (_, _) => const QuizSearchPage(),
        ),
        GoRoute(
          path: AppRoutes.quizSettings,
          builder: (_, _) => const QuizSettingsPage(),
        ),
      ];

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'quiz',
          label: 'Quiz',
          subtitle: 'Practice by subject',
          icon: Icons.quiz_outlined,
          routePath: AppRoutes.quiz,
          order: 15,
        ),
      ];
}

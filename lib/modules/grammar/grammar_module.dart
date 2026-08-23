import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/modules/grammar/data/datasources/grammar_local_data_source.dart';
import 'package:lexiora/modules/grammar/data/grammar_seeder.dart';
import 'package:lexiora/modules/grammar/data/repositories/grammar_repository_impl.dart';
import 'package:lexiora/modules/grammar/domain/repositories/grammar_repository.dart';
import 'package:lexiora/modules/grammar/presentation/pages/grammar_page.dart';
import 'package:lexiora/modules/grammar/presentation/pages/lesson_page.dart';
import 'package:lexiora/modules/grammar/presentation/pages/pos_quiz_stage_map_page.dart';
import 'package:lexiora/modules/grammar/presentation/pages/topic_page.dart';
import 'package:lexiora/modules/grammar/presentation/pages/type_detail_page.dart';

/// Phase v0.4.0 — the offline Grammar module.
///
/// Wires its data source, repository and seeder into DI, and contributes the
/// `/grammar` routes and a Home tile. All of this is additive: no existing
/// module, the router, or the injector was modified to enable it — it plugs in
/// through the [FeatureModule] contract exactly like the Dictionary and
/// Translation modules.
class GrammarModule extends FeatureModule {
  @override
  String get id => 'grammar';

  @override
  String get name => 'Grammar';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      ..registerLazySingleton<GrammarLocalDataSource>(
        () => GrammarLocalDataSource(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<GrammarRepository>(
        () => GrammarRepositoryImpl(getIt<GrammarLocalDataSource>()),
      )
      ..registerLazySingleton<GrammarSeeder>(
        () => GrammarSeeder(getIt<GrammarLocalDataSource>()),
      );
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.grammar,
          builder: (_, _) => const GrammarPage(),
        ),
        GoRoute(
          name: AppRoutes.grammarTopicName,
          path: AppRoutes.grammarTopicPattern,
          builder: (BuildContext context, GoRouterState state) => TopicPage(
            topicId: state.pathParameters['id'] ?? '',
          ),
        ),
        GoRoute(
          name: AppRoutes.grammarLessonName,
          path: AppRoutes.grammarLessonPattern,
          builder: (BuildContext context, GoRouterState state) {
            final String lessonId = state.pathParameters['id'] ?? '';
            if (lessonId == 'pos/quiz') {
              return const PosQuizStageMapPage();
            }
            return LessonPage(lessonId: lessonId);
          },
        ),
        GoRoute(
          name: AppRoutes.grammarTypeName,
          path: AppRoutes.grammarTypePattern,
          builder: (BuildContext context, GoRouterState state) =>
              TypeDetailPage(
            lessonId: state.pathParameters['id'] ?? '',
            typeName: Uri.decodeComponent(state.pathParameters['type'] ?? ''),
          ),
        ),
      ];

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'grammar',
          label: 'Grammar',
          subtitle: 'Learn grammar offline',
          icon: Icons.spellcheck,
          routePath: AppRoutes.grammar,
          imageAsset: 'assets/branding/grammar_explore.png',
          order: 12,
        ),
      ];
}

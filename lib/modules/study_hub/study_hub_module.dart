import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/modules/study_hub/data/datasources/study_hub_local_data_source.dart';
import 'package:lexiora/modules/study_hub/data/repositories/study_hub_repository_impl.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/study_hub_repository.dart';
import 'package:lexiora/modules/study_hub/presentation/pages/export_backup_page.dart';
import 'package:lexiora/modules/study_hub/presentation/pages/manage_subjects_page.dart';
import 'package:lexiora/modules/study_hub/presentation/pages/monthly_planner_page.dart';
import 'package:lexiora/modules/study_hub/presentation/pages/search_page.dart';
import 'package:lexiora/modules/study_hub/presentation/pages/study_hub_page.dart';
import 'package:lexiora/modules/study_hub/presentation/pages/templates_page.dart';
import 'package:lexiora/modules/study_hub/presentation/pages/weekly_planner_page.dart';

/// Phase v0.7.0 — the Study Hub module (personal learning dashboard).
///
/// Purely additive: wires its own data source + repository into DI, adds the
/// `/study-hub` route, and contributes a Home tile placed right after Library.
/// It touches no existing module. Storage is local (three additive Drift
/// tables) with UUID ids + timestamps, structured so a future Cloud Sync layer
/// can be added without changing this module's contracts.
class StudyHubModule extends FeatureModule {
  @override
  String get id => 'study_hub';

  @override
  String get name => 'Study Hub';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      ..registerLazySingleton<StudyHubLocalDataSource>(
        () => StudyHubLocalDataSource(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<StudyHubRepository>(
        () => StudyHubRepositoryImpl(getIt<StudyHubLocalDataSource>()),
      );
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.studyHub,
          builder: (_, _) => const StudyHubPage(),
        ),
        GoRoute(
          path: AppRoutes.studyHubWeekly,
          builder: (_, _) => const WeeklyPlannerPage(),
        ),
        GoRoute(
          path: AppRoutes.studyHubMonthly,
          builder: (_, _) => const MonthlyPlannerPage(),
        ),
        GoRoute(
          path: AppRoutes.studyHubTemplates,
          builder: (_, _) => const TemplatesPage(),
        ),
        GoRoute(
          path: AppRoutes.studyHubSearch,
          builder: (_, _) => const SearchPage(),
        ),
        GoRoute(
          path: AppRoutes.studyHubSubjects,
          builder: (_, _) => const ManageSubjectsPage(),
        ),
        GoRoute(
          path: AppRoutes.studyHubExport,
          builder: (_, _) => const ExportBackupPage(),
        ),
      ];

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'study_hub',
          label: 'Study Hub',
          subtitle: 'Plan, track & focus',
          icon: Icons.school_outlined,
          routePath: AppRoutes.studyHub,
          order: 1,
        ),
      ];
}

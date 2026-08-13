import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/modules/flashcards/data/datasources/flashcard_local_data_source.dart';
import 'package:lexiora/modules/flashcards/data/repositories/flashcard_repository_impl.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/flashcard_repository.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/deck_detail_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/decks_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/flashcard_export_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/flashcard_search_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/flashcard_stats_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/flashcards_dashboard_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/import_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/study_page.dart';

/// Phase v0.8.0 — the Flashcards Learning Engine.
///
/// A fully independent [FeatureModule]: it wires its own data source +
/// repository into DI, contributes the `/flashcards/*` routes, and replaces the
/// old "Coming Soon" tile with a live Home entry. It reads other modules'
/// tables (study_subjects for colours; dictionary/vocabulary/study_tasks for
/// import) strictly read-only, and modifies no existing module. Storage is
/// three additive Drift tables with UUID ids + timestamps, structured so a
/// future Cloud Sync / spaced-repetition layer can be added without changing
/// these contracts.
class FlashcardsModule extends FeatureModule {
  @override
  String get id => 'flashcards';

  @override
  String get name => 'Flashcards';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      ..registerLazySingleton<FlashcardLocalDataSource>(
        () => FlashcardLocalDataSource(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<FlashcardRepository>(
        () => FlashcardRepositoryImpl(getIt<FlashcardLocalDataSource>()),
      );
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.flashcards,
          builder: (_, _) => const FlashcardsDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.flashcardsDecks,
          builder: (_, _) => const DecksPage(),
        ),
        GoRoute(
          path: AppRoutes.flashcardsDeckPattern,
          name: AppRoutes.flashcardsDeckName,
          builder: (BuildContext context, GoRouterState state) =>
              DeckDetailPage(deckId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: AppRoutes.flashcardsStudy,
          builder: (BuildContext context, GoRouterState state) {
            final String? deck = state.uri.queryParameters['deck'];
            final String modeName =
                state.uri.queryParameters['mode'] ?? StudyMode.due.name;
            final StudyMode mode = StudyMode.values.firstWhere(
              (StudyMode m) => m.name == modeName,
              orElse: () => StudyMode.due,
            );
            return StudyPage(deckId: deck, mode: mode);
          },
        ),
        GoRoute(
          path: AppRoutes.flashcardsSearch,
          builder: (_, _) => const FlashcardSearchPage(),
        ),
        GoRoute(
          path: AppRoutes.flashcardsStats,
          builder: (_, _) => const FlashcardStatsPage(),
        ),
        GoRoute(
          path: AppRoutes.flashcardsImport,
          builder: (_, _) => const ImportPage(),
        ),
        GoRoute(
          path: AppRoutes.flashcardsExport,
          builder: (_, _) => const FlashcardExportPage(),
        ),
      ];

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'flashcards',
          label: 'Flashcards',
          subtitle: 'Spaced-repetition revision',
          icon: Icons.style_outlined,
          routePath: AppRoutes.flashcards,
          imageAsset: 'assets/branding/flashcards_explore.png',
          order: 14,
        ),
      ];
}

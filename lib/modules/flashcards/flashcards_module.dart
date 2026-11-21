import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/core/services/ad_return_navigation_scope.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/modules/flashcards/data/drift_fc_sql.dart';
import 'package:lexiora/modules/flashcards/data/fc_repository_impl.dart';
import 'package:lexiora/modules/flashcards/data/flashcard_store.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/fc_repository.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/deck_detail_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/decks_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/export_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/flashcards_home_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/import_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/search_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/stats_page.dart';
import 'package:lexiora/modules/flashcards/presentation/pages/study_page.dart';

/// Flashcards v2: an FSRS-6 spaced-repetition engine with basic, cloze and
/// type-the-answer cards, per-deck limits, statistics, import/export and
/// backups.
///
/// Storage: the original `decks` / `flashcards` / `review_logs` tables are
/// kept as they are (so nobody loses data); FSRS scheduling state and deck
/// settings live in two sidecar tables created by [FcSchema] when the
/// database opens. Other modules' tables (study_subjects, dictionary_entries,
/// vocabulary_words, study_tasks) are only ever read.
class FlashcardsModule extends FeatureModule {
  @override
  String get id => 'flashcards';

  @override
  String get name => 'Flashcards';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      ..registerLazySingleton<FlashcardStore>(
        () => FlashcardStore(DriftFcSql(getIt<AppDatabase>())),
      )
      ..registerLazySingleton<FcRepository>(
        () => FcRepositoryImpl(getIt<FlashcardStore>()),
      );
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.flashcards,
          builder: (_, _) => AdReturnNavigationScope(
            manager: getIt<RewardedAdManager>(),
            child: const FlashcardsHomePage(),
          ),
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
          builder: (_, _) => const FlashcardsSearchPage(),
        ),
        GoRoute(
          path: AppRoutes.flashcardsStats,
          builder: (_, _) => const FlashcardsStatsPage(),
        ),
        GoRoute(
          path: AppRoutes.flashcardsImport,
          builder: (_, _) => const FlashcardsImportPage(),
        ),
        GoRoute(
          path: AppRoutes.flashcardsExport,
          builder: (BuildContext context, GoRouterState state) =>
              FlashcardsExportPage(deckId: state.uri.queryParameters['deck']),
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
          imageAsset: 'assets/branding/flashcards_explore.webp',
          order: 14,
        ),
      ];
}

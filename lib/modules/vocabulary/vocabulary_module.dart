import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/core/services/pronunciation_service.dart';
import 'package:lexiora/modules/vocabulary/data/datasources/vocabulary_local_data_source.dart';
import 'package:lexiora/modules/vocabulary/data/repositories/vocabulary_repository_impl.dart';
import 'package:lexiora/modules/vocabulary/data/vocabulary_seeder.dart';
import 'package:lexiora/modules/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:lexiora/modules/vocabulary/presentation/pages/vocabulary_lists_page.dart';
import 'package:lexiora/modules/vocabulary/presentation/pages/vocabulary_words_page.dart';
import 'package:lexiora/modules/vocabulary/presentation/pages/vocabulary_word_page.dart';

/// Phase v0.6.0 — the offline Vocabulary module.
///
/// A learning feature (organized A–Z word lists), distinct from the Dictionary.
/// Wires its data source, repository and multi-pack seeder into DI, and
/// contributes the `/vocabulary` routes plus a Home tile. Purely additive — no
/// existing module, the router, or the injector was modified to enable it; it
/// plugs in through the [FeatureModule] contract like every other module.
class VocabularyModule extends FeatureModule {
  @override
  String get id => 'vocabulary';

  @override
  String get name => 'Vocabulary';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      ..registerLazySingleton<VocabularyLocalDataSource>(
        () => VocabularyLocalDataSource(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<VocabularyRepository>(
        () => VocabularyRepositoryImpl(getIt<VocabularyLocalDataSource>()),
      )
      ..registerLazySingleton<VocabularySeeder>(
        () => VocabularySeeder(getIt<VocabularyLocalDataSource>()),
      );

    // Reuse the shared on-device TTS service. Register it only if no other
    // module already did, so Vocabulary is self-sufficient without coupling to
    // the Dictionary module's registration (and never double-registers).
    if (!getIt.isRegistered<PronunciationService>()) {
      getIt.registerLazySingleton<PronunciationService>(
        TtsPronunciationService.new,
      );
    }
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.vocabulary,
          builder: (_, _) => const VocabularyListsPage(),
        ),
        GoRoute(
          name: AppRoutes.vocabularyWordName,
          path: AppRoutes.vocabularyWordPattern,
          builder: (BuildContext context, GoRouterState state) =>
              VocabularyWordPage(word: state.pathParameters['word'] ?? ''),
        ),
        GoRoute(
          name: AppRoutes.vocabularyListName,
          path: AppRoutes.vocabularyListPattern,
          builder: (BuildContext context, GoRouterState state) =>
              VocabularyWordsPage(listId: state.pathParameters['id'] ?? ''),
        ),
      ];

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'vocabulary',
          label: 'Vocabulary',
          subtitle: 'Learn word lists A–Z',
          icon: Icons.style_outlined,
          routePath: AppRoutes.vocabulary,
          imageAsset: 'assets/branding/vocabulary_explore.png',
          order: 13,
        ),
      ];
}

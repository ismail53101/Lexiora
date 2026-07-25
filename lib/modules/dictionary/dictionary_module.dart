import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/core/reader_engine/word_action.dart';
import 'package:lexiora/core/services/pronunciation_service.dart';
import 'package:lexiora/modules/dictionary/data/datasources/dictionary_local_data_source.dart';
import 'package:lexiora/modules/dictionary/data/dictionary_seeder.dart';
import 'package:lexiora/modules/dictionary/data/exam_words_seeder.dart';
import 'package:lexiora/modules/dictionary/data/repositories/dictionary_repository_impl.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';
import 'package:lexiora/modules/dictionary/presentation/pages/dictionary_page.dart';
import 'package:lexiora/modules/dictionary/presentation/pages/word_details_page.dart';
import 'package:lexiora/modules/dictionary/presentation/word_actions/define_word_action.dart';

/// Phase 2.1 — the offline Dictionary module.
///
/// Wires its data source, repository and seeder into DI, contributes the
/// `/dictionary` routes and a Home tile, and registers a [WordAction] so the
/// reader can look up a selected word. All of this is additive: no existing
/// module, the router, or the injector was modified to enable it.
class DictionaryModule extends FeatureModule {
  @override
  String get id => 'dictionary';

  @override
  String get name => 'Dictionary';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      ..registerLazySingleton<DictionaryLocalDataSource>(
        () => DictionaryLocalDataSource(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<DictionaryRepository>(
        () => DictionaryRepositoryImpl(getIt<DictionaryLocalDataSource>()),
      )
      ..registerLazySingleton<DictionarySeeder>(
        () => DictionarySeeder(getIt<DictionaryLocalDataSource>()),
      )
      ..registerLazySingleton<ExamWordsSeeder>(
        () => ExamWordsSeeder(getIt<DictionaryLocalDataSource>()),
      )
      ..registerLazySingleton<PronunciationService>(
        TtsPronunciationService.new,
      );

    // Contribute the "Look up" action to the shared reader registry (a core
    // singleton registered before modules). Idempotent by action id.
    getIt<WordActionRegistry>().register(const DefineWordAction());
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.dictionary,
          builder: (_, _) => const DictionaryPage(),
        ),
        GoRoute(
          name: AppRoutes.dictionaryWordName,
          path: AppRoutes.dictionaryWordPattern,
          builder: (BuildContext context, GoRouterState state) => WordDetailsPage(
            wordLower:
                Uri.decodeComponent(state.pathParameters['word'] ?? ''),
          ),
        ),
      ];

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'dictionary',
          label: 'Dictionary',
          subtitle: 'Look up words offline',
          icon: Icons.menu_book_outlined,
          routePath: AppRoutes.dictionary,
          order: 10,
        ),
      ];
}

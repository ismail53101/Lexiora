import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/features/library/data/repositories/library_repository_impl.dart';
import 'package:lexiora/features/library/domain/repositories/library_repository.dart';
import 'package:lexiora/features/library/presentation/pages/library_page.dart';

/// Wires the Library feature: DI, the `/library` route, and a Home tile.
class LibraryModule extends FeatureModule {
  @override
  String get id => 'library';

  @override
  String get name => 'Library';

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton<LibraryRepository>(
      () => LibraryRepositoryImpl(getIt<AppDatabase>()),
    );
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.library,
          builder: (_, _) => const LibraryPage(),
        ),
      ];

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'library',
          label: 'Library',
          subtitle: 'All your documents',
          icon: Icons.folder_copy_outlined,
          routePath: AppRoutes.library,
          order: 0,
        ),
      ];
}

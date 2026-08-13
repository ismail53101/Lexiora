import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/features/home/config/current_affairs_config.dart';
import 'package:lexiora/features/home/data/current_affairs_api_client.dart';
import 'package:lexiora/features/home/data/current_affairs_repository.dart';
import 'package:lexiora/features/home/presentation/pages/home_page.dart';

/// Wires the Home dashboard and owns the root `/` route.
class HomeModule extends FeatureModule {
  @override
  String get id => 'home';

  @override
  String get name => 'Home';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      ..registerLazySingleton<CurrentAffairsConfig>(
        CurrentAffairsConfig.fromEnvironment,
      )
      ..registerLazySingleton<CurrentAffairsApiClient>(
        () => CurrentAffairsApiClient(getIt<CurrentAffairsConfig>()),
      )
      ..registerLazySingleton<CurrentAffairsRepository>(
        () => CurrentAffairsRepositoryImpl(
          getIt<CurrentAffairsApiClient>(),
        ),
      );
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const HomePage(),
        ),
      ];
}

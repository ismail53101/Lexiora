import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:lexiora/features/settings/domain/repositories/settings_repository.dart';
import 'package:lexiora/features/settings/presentation/pages/settings_page.dart';

/// Wires the Settings feature into the app (DI + routing).
class SettingsModule extends FeatureModule {
  @override
  String get id => 'settings';

  @override
  String get name => 'Settings';

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(getIt<AppDatabase>()),
    );
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => const SettingsPage(),
        ),
      ];
}

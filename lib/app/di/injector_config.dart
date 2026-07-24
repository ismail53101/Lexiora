import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/app/di/module_registry.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/core/reader_engine/word_action.dart';
import 'package:lexiora/core/services/file_import_service.dart';
import 'package:lexiora/core/services/permission_service.dart';
import 'package:lexiora/core/services/storage_paths.dart';

/// Configures the GetIt service locator.
///
/// Registers the cross-cutting core singletons, then delegates to every module
/// in [appModules] so each registers its own dependencies. Finally it collects
/// the Home destinations the modules contribute into a single registry.
Future<void> configureDependencies() async {
  // ── Core singletons ────────────────────────────────────────────────────
  sl
    ..registerLazySingleton<AppDatabase>(AppDatabase.new)
    ..registerLazySingleton<StoragePaths>(StoragePaths.new)
    ..registerLazySingleton<PermissionService>(() => const PermissionService())
    ..registerLazySingleton<FileImportService>(
      () => FileImportService(sl<StoragePaths>()),
    )
    // The tap-on-word extension registry — empty in Phase 1, populated by
    // future language modules.
    ..registerLazySingleton<WordActionRegistry>(WordActionRegistry.new);

  // ── Module dependencies ────────────────────────────────────────────────
  for (final FeatureModule module in appModules) {
    module.registerDependencies(sl);
  }

  // ── Aggregate Home dashboard destinations ──────────────────────────────
  final List<HomeDestination> destinations = <HomeDestination>[];
  for (final FeatureModule module in appModules) {
    destinations.addAll(module.homeDestinations(sl));
  }
  destinations.sort((HomeDestination a, HomeDestination b) =>
      a.order.compareTo(b.order));
  sl.registerSingleton<HomeDestinationRegistry>(
    HomeDestinationRegistry(List<HomeDestination>.unmodifiable(destinations)),
  );
}

import 'package:get_it/get_it.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/features/reading_progress/data/repositories/reading_progress_repository_impl.dart';
import 'package:lexiora/features/reading_progress/domain/repositories/reading_progress_repository.dart';

/// Wires the Reading Progress feature (DI only; it contributes no routes).
class ReadingProgressModule extends FeatureModule {
  @override
  String get id => 'reading_progress';

  @override
  String get name => 'Reading Progress';

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton<ReadingProgressRepository>(
      () => ReadingProgressRepositoryImpl(getIt<AppDatabase>()),
    );
  }
}

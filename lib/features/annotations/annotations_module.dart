import 'package:get_it/get_it.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/features/annotations/data/repositories/annotations_repository_impl.dart';
import 'package:lexiora/features/annotations/domain/repositories/annotations_repository.dart';

/// Wires the Annotations (highlight/underline) feature (DI only).
class AnnotationsModule extends FeatureModule {
  @override
  String get id => 'annotations';

  @override
  String get name => 'Annotations';

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton<AnnotationsRepository>(
      () => AnnotationsRepositoryImpl(getIt<AppDatabase>()),
    );
  }
}

import 'package:get_it/get_it.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:lexiora/features/notes/domain/repositories/notes_repository.dart';

/// Wires the Notes feature (DI only; notes are presented inside the reader).
class NotesModule extends FeatureModule {
  @override
  String get id => 'notes';

  @override
  String get name => 'Notes';

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton<NotesRepository>(
      () => NotesRepositoryImpl(getIt<AppDatabase>()),
    );
  }
}

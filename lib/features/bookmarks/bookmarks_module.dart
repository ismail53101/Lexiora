import 'package:get_it/get_it.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/features/bookmarks/data/repositories/bookmarks_repository_impl.dart';
import 'package:lexiora/features/bookmarks/domain/repositories/bookmarks_repository.dart';

/// Wires the Bookmarks feature (DI only; bookmarks are presented in the reader).
class BookmarksModule extends FeatureModule {
  @override
  String get id => 'bookmarks';

  @override
  String get name => 'Bookmarks';

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton<BookmarksRepository>(
      () => BookmarksRepositoryImpl(getIt<AppDatabase>()),
    );
  }
}

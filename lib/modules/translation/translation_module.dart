import 'package:get_it/get_it.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/reader_engine/word_action.dart';
import 'package:lexiora/modules/translation/data/datasources/translation_local_data_source.dart';
import 'package:lexiora/modules/translation/data/repositories/translation_repository_impl.dart';
import 'package:lexiora/modules/translation/data/translation_seeder.dart';
import 'package:lexiora/modules/translation/domain/repositories/translation_repository.dart';
import 'package:lexiora/modules/translation/presentation/word_actions/translate_word_action.dart';

/// The offline Translate module.
///
/// Reader-only in this phase: it contributes a "Translate" [WordAction] to the
/// shared registry (beside the dictionary's "Look up") and wires its own data
/// source, repository and seeder. It adds no route or Home tile. Everything is
/// additive — no existing module was modified to enable it.
class TranslationModule extends FeatureModule {
  @override
  String get id => 'translation';

  @override
  String get name => 'Translation';

  @override
  void registerDependencies(GetIt getIt) {
    getIt
      ..registerLazySingleton<TranslationLocalDataSource>(
        () => TranslationLocalDataSource(getIt<AppDatabase>()),
      )
      ..registerLazySingleton<TranslationRepository>(
        () => TranslationRepositoryImpl(getIt<TranslationLocalDataSource>()),
      )
      ..registerLazySingleton<TranslationSeeder>(
        () => TranslationSeeder(getIt<TranslationLocalDataSource>()),
      );

    // Contribute "Translate" to the shared reader registry (idempotent by id).
    getIt<WordActionRegistry>().register(const TranslateWordAction());
  }
}

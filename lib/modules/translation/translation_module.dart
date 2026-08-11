import 'package:get_it/get_it.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/reader_engine/word_action.dart';
import 'package:lexiora/core/services/connectivity_service.dart';
import 'package:lexiora/modules/dictionary/data/services/online_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';
import 'package:lexiora/modules/translation/data/datasources/translation_local_data_source.dart';
import 'package:lexiora/modules/translation/data/repositories/translation_repository_impl.dart';
import 'package:lexiora/modules/translation/data/services/http_translation_service.dart';
import 'package:lexiora/modules/translation/data/services/word_meaning_service.dart';
import 'package:lexiora/modules/translation/data/translation_seeder.dart';
import 'package:lexiora/modules/translation/domain/repositories/translation_repository.dart';
import 'package:lexiora/modules/translation/domain/services/remote_translation_service.dart';
import 'package:lexiora/modules/translation/presentation/word_actions/translate_word_action.dart';
import 'package:lexiora/modules/vocabulary/domain/repositories/vocabulary_repository.dart';

/// The offline-first Translate module with a hybrid online fallback (v0.4.1).
///
/// Reader-only: it contributes a "Translate" [WordAction] to the shared registry
/// (beside the dictionary's "Look up") and wires its own data source, repository,
/// seeder, and the two swappable services that power the online fallback — a
/// [RemoteTranslationService] (configurable provider) and a [ConnectivityService].
/// Everything is additive; no existing module was modified to enable it.
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
      )
      // Online-fallback services, both behind interfaces so they can be swapped
      // without touching the repository, use case or UI.
      ..registerLazySingleton<RemoteTranslationService>(
        HttpTranslationService.new,
      )
      ..registerLazySingleton<ConnectivityService>(
        NetworkConnectivityService.new,
      )
      // Resolves a single word's best English meaning (+ curated Urdu when
      // available) across the exam packs, the base dictionary and the free
      // online dictionary — shared by the popup's English-meaning section and
      // the sense-aware Urdu translation path.
      ..registerLazySingleton<WordMeaningService>(
        () => WordMeaningService(
          dictionary: getIt<DictionaryRepository>(),
          vocabulary: getIt<VocabularyRepository>(),
          online: OnlineDictionaryService(),
        ),
      );

    // Contribute "Translate" to the shared reader registry (idempotent by id).
    getIt<WordActionRegistry>().register(const TranslateWordAction());
  }
}

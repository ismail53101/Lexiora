import 'package:lexiora/modules/translation/data/datasources/translation_local_data_source.dart';
import 'package:lexiora/modules/translation/domain/repositories/translation_repository.dart';

/// [TranslationRepository] backed by the local database via
/// [TranslationLocalDataSource] (bundled data set + offline cache).
class TranslationRepositoryImpl implements TranslationRepository {
  TranslationRepositoryImpl(this._local);

  final TranslationLocalDataSource _local;

  @override
  Future<String?> translate(String word, String languageCode) =>
      _local.translate(word, languageCode);

  @override
  Future<int> entryCount() => _local.entryCount();

  @override
  Future<bool> isCached(String word, String languageCode) =>
      _local.isCached(word, languageCode);

  @override
  Future<void> cacheTranslation({
    required String word,
    required String languageCode,
    required String translation,
  }) =>
      _local.cacheTranslation(
        word: word,
        languageCode: languageCode,
        translation: translation,
      );

  @override
  Future<int> cachedCount() => _local.cachedCount();
}

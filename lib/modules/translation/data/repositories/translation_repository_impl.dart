import 'package:lexiora/modules/translation/data/datasources/translation_local_data_source.dart';
import 'package:lexiora/modules/translation/domain/repositories/translation_repository.dart';

/// [TranslationRepository] backed by the local database via
/// [TranslationLocalDataSource].
class TranslationRepositoryImpl implements TranslationRepository {
  TranslationRepositoryImpl(this._local);

  final TranslationLocalDataSource _local;

  @override
  Future<String?> translate(String word, String languageCode) =>
      _local.translate(word, languageCode);

  @override
  Future<int> entryCount() => _local.entryCount();
}

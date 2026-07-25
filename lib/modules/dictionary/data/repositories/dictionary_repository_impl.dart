import 'package:lexiora/modules/dictionary/data/datasources/dictionary_local_data_source.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';

/// [DictionaryRepository] backed entirely by the local database, through
/// [DictionaryLocalDataSource]. The repository is a thin mapping seam; all SQL
/// lives in the data source.
class DictionaryRepositoryImpl implements DictionaryRepository {
  DictionaryRepositoryImpl(this._local);

  final DictionaryLocalDataSource _local;

  @override
  Future<List<DictionaryResult>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) =>
      _local.search(query, limit: limit, offset: offset);

  @override
  Future<WordDetails?> wordDetails(String wordLower) =>
      _local.wordDetails(wordLower);

  @override
  Future<DictionaryResult?> lookup(String wordLower) => _local.lookup(wordLower);

  @override
  Future<int> entryCount() => _local.entryCount();

  @override
  Future<void> addFavorite({
    required String wordLower,
    required String word,
    required String meaning,
    String? partOfSpeech,
  }) =>
      _local.addFavorite(
        wordLower: wordLower,
        word: word,
        meaning: meaning,
        partOfSpeech: partOfSpeech,
      );

  @override
  Future<void> removeFavorite(String wordLower) =>
      _local.removeFavorite(wordLower);

  @override
  Future<bool> isFavorite(String wordLower) => _local.isFavorite(wordLower);

  @override
  Stream<bool> watchIsFavorite(String wordLower) =>
      _local.watchIsFavorite(wordLower);

  @override
  Stream<List<DictionaryResult>> watchFavorites() => _local.watchFavorites();

  @override
  Future<void> registerExternalWord({
    required String word,
    required String meaning,
    String? partOfSpeech,
  }) =>
      _local.registerExternalWord(
        word: word,
        meaning: meaning,
        partOfSpeech: partOfSpeech,
      );

  @override
  Future<ExamWordData?> examData(String wordLower) =>
      _local.examData(wordLower);

  @override
  Future<List<String>> relatedWords(String wordLower, {int limit = 8}) =>
      _local.relatedWords(wordLower, limit: limit);

  @override
  Future<void> addSearchHistory(String word) => _local.addSearchHistory(word);

  @override
  Stream<List<String>> watchRecentSearches({int limit = 20}) =>
      _local.watchRecentSearches(limit: limit);

  @override
  Future<void> clearSearchHistory() => _local.clearSearchHistory();
}

import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';

/// Parameters for a paged dictionary search.
class SearchParams {
  const SearchParams(this.query, {this.limit = 50, this.offset = 0});
  final String query;
  final int limit;
  final int offset;
}

/// Runs a grouped prefix search over the offline dictionary.
class SearchDictionary implements UseCase<List<DictionaryResult>, SearchParams> {
  const SearchDictionary(this._repo);
  final DictionaryRepository _repo;

  @override
  ResultFuture<List<DictionaryResult>> call(SearchParams params) => guard(
        () => _repo.search(
          params.query,
          limit: params.limit,
          offset: params.offset,
        ),
      );
}

/// Loads every sense for a headword (for the Word Details screen).
class GetWordDetails implements UseCase<WordDetails?, String> {
  const GetWordDetails(this._repo);
  final DictionaryRepository _repo;

  @override
  ResultFuture<WordDetails?> call(String wordLower) =>
      guard(() => _repo.wordDetails(wordLower));
}

/// Looks up a word's primary sense for the lightweight reader popup.
class LookUpWord implements UseCase<DictionaryResult?, String> {
  const LookUpWord(this._repo);
  final DictionaryRepository _repo;

  @override
  ResultFuture<DictionaryResult?> call(String wordLower) =>
      guard(() => _repo.lookup(wordLower));
}

/// Parameters describing the word whose favorite state is being toggled.
class ToggleFavoriteParams {
  const ToggleFavoriteParams({
    required this.wordLower,
    required this.word,
    required this.meaning,
    this.partOfSpeech,
  });

  final String wordLower;
  final String word;
  final String meaning;
  final String? partOfSpeech;
}

/// Toggles a word's saved state and returns the new value (`true` = saved).
class ToggleWordFavorite implements UseCase<bool, ToggleFavoriteParams> {
  const ToggleWordFavorite(this._repo);
  final DictionaryRepository _repo;

  @override
  ResultFuture<bool> call(ToggleFavoriteParams params) => guard(() async {
        final bool currently = await _repo.isFavorite(params.wordLower);
        if (currently) {
          await _repo.removeFavorite(params.wordLower);
          return false;
        }
        await _repo.addFavorite(
          wordLower: params.wordLower,
          word: params.word,
          meaning: params.meaning,
          partOfSpeech: params.partOfSpeech,
        );
        return true;
      });
}

/// Streams the saved-words list.
class WatchFavorites implements StreamUseCase<List<DictionaryResult>, NoParams> {
  const WatchFavorites(this._repo);
  final DictionaryRepository _repo;

  @override
  Stream<List<DictionaryResult>> call(NoParams params) =>
      _repo.watchFavorites();
}

import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_list.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';
import 'package:lexiora/modules/vocabulary/domain/repositories/vocabulary_repository.dart';

/// Streams the vocabulary lists for the home screen.
class WatchVocabularyLists
    implements StreamUseCase<List<VocabularyListSummary>, NoParams> {
  const WatchVocabularyLists(this._repo);
  final VocabularyRepository _repo;

  @override
  Stream<List<VocabularyListSummary>> call(NoParams params) =>
      _repo.watchLists();
}

/// Streams the A–Z words for a single list (by id).
class WatchVocabularyWords
    implements StreamUseCase<List<VocabularyWord>, String> {
  const WatchVocabularyWords(this._repo);
  final VocabularyRepository _repo;

  @override
  Stream<List<VocabularyWord>> call(String listId) =>
      _repo.watchWords(listId);
}

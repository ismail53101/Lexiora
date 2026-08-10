import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_list.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';

/// Domain contract for the Vocabulary module. The presentation layer depends on
/// this interface only, never on Drift or the data source implementation.
abstract interface class VocabularyRepository {
  /// All vocabulary lists, ordered for display. Reactive.
  Stream<List<VocabularyListSummary>> watchLists();

  /// All words in [listId], ordered A–Z (letter, then word). Reactive.
  Stream<List<VocabularyWord>> watchWords(String listId);

  /// One-shot, case-insensitive headword lookup across every vocabulary pack
  /// (used by the reader/translation popup to show the curated meaning of an
  /// exam word). Returns the first pack containing the word, or `null`.
  Future<VocabularyWord?> lookupWord(String wordLower);
}

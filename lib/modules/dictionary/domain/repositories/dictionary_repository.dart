import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';

/// Domain contract for the offline dictionary.
///
/// Implementations are backed by the local database only — the dictionary is
/// fully offline. Search is a grouped, index-backed prefix query (one result
/// per headword); favorites are stored independently of the read-only entry
/// data so the dictionary can be re-seeded without losing saved words.
abstract interface class DictionaryRepository {
  /// Grouped prefix search over headwords. Returns one [DictionaryResult] per
  /// matching word, exact matches first, then alphabetical. [limit]/[offset]
  /// drive lazy pagination.
  Future<List<DictionaryResult>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  });

  /// All senses for a headword (identified by its lowercased form), or `null`
  /// when the word is not in the dictionary.
  Future<WordDetails?> wordDetails(String wordLower);

  /// The primary (first) sense for a word — used by the lightweight reader
  /// popup. `null` when the word is unknown.
  Future<DictionaryResult?> lookup(String wordLower);

  /// Total number of indexed senses (diagnostics / seed verification).
  Future<int> entryCount();

  // ── Favorites (saved vocabulary) ──────────────────────────────────────────

  /// Saves a word to favorites, snapshotting a representative meaning.
  Future<void> addFavorite({
    required String wordLower,
    required String word,
    required String meaning,
    String? partOfSpeech,
  });

  /// Removes a word from favorites.
  Future<void> removeFavorite(String wordLower);

  /// One-shot favorite check.
  Future<bool> isFavorite(String wordLower);

  /// Reactive favorite check for a single word (keeps the star in sync).
  Stream<bool> watchIsFavorite(String wordLower);

  /// Reactive list of saved words, most recently saved first.
  Stream<List<DictionaryResult>> watchFavorites();
}

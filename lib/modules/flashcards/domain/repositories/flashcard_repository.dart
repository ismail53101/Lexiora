import 'package:lexiora/modules/flashcards/domain/entities/deck.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';

/// Domain contract for the Flashcards module. Local-first; structured so a
/// future Cloud Sync can reuse [exportBackup]/[importBackup] unchanged.
abstract interface class FlashcardRepository {
  // ── Decks ───────────────────────────────────────────────────────────────────
  Stream<List<DeckSummary>> watchDecks({bool includeArchived});
  Future<Deck?> deck(String id);
  Future<void> saveDeck(Deck deck);
  Future<void> setDeckArchived(String id, bool archived);
  Future<void> deleteDeck(String id); // also deletes its cards + logs

  // ── Cards (paginated for 100k+) ─────────────────────────────────────────────
  Future<List<Flashcard>> cards(FlashcardFilter filter,
      {int limit = 50, int offset = 0});
  Future<Flashcard?> card(String id);
  Future<void> saveCard(Flashcard card);
  Future<void> deleteCard(String id);
  Future<void> setBookmarked(String id, bool value);
  Future<void> setFavorite(String id, bool value);
  Future<void> setDifficulty(String id, CardDifficulty difficulty);

  // ── Review ──────────────────────────────────────────────────────────────────
  Future<void> recordReview(String cardId, CardRating rating,
      {int durationMs});
  Future<List<Flashcard>> buildStudySession(
      {String? deckId, required StudyMode mode, int limit});
  Stream<ReviewQueue> watchReviewQueue();

  // ── Dashboard / stats ───────────────────────────────────────────────────────
  Stream<FlashcardStats> watchStats();
  Stream<List<Flashcard>> watchDifficultCards({int limit});
  Stream<List<ReviewActivity>> watchRecentActivity({int limit});

  // ── Colours (reused from Study Hub) + suggestions ───────────────────────────
  Stream<Map<String, int>> watchSubjectColors();
  Future<List<String>> subjectSuggestions();
  Future<List<String>> tagSuggestions();

  // ── Import from other modules (read-only) ───────────────────────────────────
  Future<List<ImportCandidate>> importCandidates(ImportSource source,
      {String query, int limit});
  Future<int> importCards(String deckId, List<ImportCandidate> items);

  // ── Backup / restore ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> exportBackup();
  Future<void> importBackup(Map<String, dynamic> data);
}

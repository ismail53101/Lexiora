import 'package:lexiora/modules/flashcards/domain/logic/csv_codec.dart';
import 'package:lexiora/modules/flashcards/domain/logic/study_session.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_query.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_stats_models.dart';

/// Result of [FcRepository.addCards].
class AddCardsResult {
  const AddCardsResult({required this.created, required this.skipped});
  final int created;
  final int skipped;
}

abstract interface class FcRepository {
  /// Emits a new number whenever any flashcards data changes; lets paginated
  /// lists know when to reload.
  Stream<int> watchRevision();

  // Decks
  Stream<List<FcDeckSummary>> watchDecks({bool includeArchived = false});
  Stream<FcDeckSummary?> watchDeck(String id);
  Future<FcDeck?> deck(String id);
  Future<FcDeck> createDeck({
    required String name,
    String? description,
    String? subject,
    String? topic,
    int? color,
  });
  Future<void> updateDeck(FcDeck deck);
  Future<void> setDeckArchived(String id, bool archived);
  Future<void> deleteDeck(String id);
  Future<DeckSettings> deckSettings(String deckId);
  Future<void> saveDeckSettings(String deckId, DeckSettings settings);

  // Cards
  Future<List<FcCard>> browse(FcCardQuery query);
  Future<FcCard?> card(String id);

  /// Creates cards from [drafts]. [reversed] adds a back→front twin of every
  /// basic card; [clozePerDeletion] makes one card per `cN` number.
  Future<AddCardsResult> addCards(
    String deckId,
    List<CardDraft> drafts, {
    bool reversed = false,
    bool clozePerDeletion = true,
    String? subject,
    String? topic,
  });
  Future<void> updateCard(FcCard card);
  Future<void> setStarred(String id, bool starred);
  Future<void> setSuspended(String id, bool suspended);

  /// Hides the card until the next study day.
  Future<void> buryUntilTomorrow(String id);
  Future<void> deleteCards(List<String> ids);
  Future<void> moveCards(List<String> ids, String deckId);

  // Studying
  Future<StudySession> startSession({String? deckId, StudyMode mode = StudyMode.due});

  /// Persists an answer; returns the review-log id (needed to undo it).
  Future<String> recordAnswer(AnswerOutcome outcome, {required int durationMs});
  Future<void> undoAnswer(FcCard before, String logId);

  // Dashboard & statistics
  Stream<FcDashboard> watchDashboard();
  Stream<FcStats> watchStats();
  Stream<List<FcActivity>> watchRecentActivity({int limit = 8});

  // Suggestions
  Future<List<String>> subjectSuggestions();
  Future<List<String>> tagSuggestions();
  Stream<Map<String, int>> watchSubjectColors();

  // Import from other modules (read-only) and backup
  Future<List<ImportCandidate>> importCandidates(ImportSource source, String query, {int limit = 200});
  Future<Map<String, dynamic>> exportBackup();
  Future<void> importBackup(Map<String, dynamic> data);
}

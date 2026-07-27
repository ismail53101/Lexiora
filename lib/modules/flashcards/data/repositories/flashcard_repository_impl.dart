import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/flashcards/data/datasources/flashcard_local_data_source.dart';
import 'package:lexiora/modules/flashcards/domain/entities/deck.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/domain/flashcard_dates.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/flashcard_repository.dart';
import 'package:lexiora/modules/flashcards/domain/scheduler.dart';
import 'package:uuid/uuid.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  FlashcardRepositoryImpl(this._local);

  final FlashcardLocalDataSource _local;
  static const Uuid _uuid = Uuid();

  // ── Decks ───────────────────────────────────────────────────────────────────

  @override
  Stream<List<DeckSummary>> watchDecks({bool includeArchived = false}) =>
      _local.watchDeckSummaries(includeArchived).map((List<QueryRow> rows) => rows
          .map((QueryRow r) => DeckSummary(
                deck: _toDeck(_local.deckRowFrom(r)),
                cardCount: r.read<int>('card_count'),
                dueCount: r.read<int>('due_count'),
              ))
          .toList(growable: false));

  @override
  Future<Deck?> deck(String id) async {
    final DeckRow? r = await _local.deck(id);
    return r == null ? null : _toDeck(r);
  }

  @override
  Future<void> saveDeck(Deck d) => _local.upsertDeck(DecksCompanion.insert(
        id: d.id,
        name: d.name,
        description: Value<String?>(d.description),
        subject: Value<String?>(d.subject),
        topic: Value<String?>(d.topic),
        color: Value<int?>(d.color),
        icon: Value<int?>(d.icon),
        archived: Value<bool>(d.archived),
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
      ));

  @override
  Future<void> setDeckArchived(String id, bool archived) => _local.updateDeck(
      id,
      DecksCompanion(
          archived: Value<bool>(archived),
          updatedAt: Value<DateTime>(DateTime.now())));

  @override
  Future<void> deleteDeck(String id) => _local.deleteDeck(id);

  // ── Cards ───────────────────────────────────────────────────────────────────

  @override
  Future<List<Flashcard>> cards(FlashcardFilter filter,
          {int limit = 50, int offset = 0}) async =>
      (await _local.searchCards(filter, limit: limit, offset: offset))
          .map(_toCard)
          .toList();

  @override
  Future<Flashcard?> card(String id) async {
    final FlashcardRow? r = await _local.card(id);
    return r == null ? null : _toCard(r);
  }

  @override
  Future<void> saveCard(Flashcard c) => _local.upsertCard(_companion(c));

  @override
  Future<void> deleteCard(String id) => _local.deleteCard(id);

  @override
  Future<void> setBookmarked(String id, bool value) => _local.updateCard(
      id,
      FlashcardsCompanion(
          bookmarked: Value<bool>(value),
          updatedAt: Value<DateTime>(DateTime.now())));

  @override
  Future<void> setFavorite(String id, bool value) => _local.updateCard(
      id,
      FlashcardsCompanion(
          favorite: Value<bool>(value),
          updatedAt: Value<DateTime>(DateTime.now())));

  @override
  Future<void> setDifficulty(String id, CardDifficulty difficulty) =>
      _local.updateCard(
          id,
          FlashcardsCompanion(
              difficulty: Value<int>(difficulty.index),
              updatedAt: Value<DateTime>(DateTime.now())));

  // ── Review ──────────────────────────────────────────────────────────────────

  @override
  Future<void> recordReview(String cardId, CardRating rating,
      {int durationMs = 0}) async {
    final FlashcardRow? row = await _local.card(cardId);
    if (row == null) return;
    final Flashcard card = _toCard(row);
    final DateTime now = DateTime.now();
    final SchedulerOutcome out = scheduleReview(card, rating, now);
    await _local.updateCard(
      cardId,
      FlashcardsCompanion(
        reviewState: Value<int>(out.reviewState.index),
        dueAt: Value<DateTime?>(out.dueAt),
        intervalDays: Value<int>(out.intervalDays),
        easeFactor: Value<double>(out.easeFactor),
        repetitions: Value<int>(out.repetitions),
        lapses: Value<int>(out.lapses),
        lastReviewedAt: Value<DateTime?>(now),
        updatedAt: Value<DateTime>(now),
      ),
    );
    await _local.insertReviewLog(ReviewLogsCompanion.insert(
      id: _uuid.v4(),
      cardId: cardId,
      deckId: card.deckId,
      rating: rating.index,
      day: todayKey(),
      reviewedAt: now,
      durationMs: Value<int>(durationMs),
    ));
  }

  @override
  Future<List<Flashcard>> buildStudySession(
          {String? deckId, required StudyMode mode, int limit = 200}) async =>
      (await _local.studySession(deckId: deckId, mode: mode, limit: limit))
          .map(_toCard)
          .toList();

  @override
  Stream<ReviewQueue> watchReviewQueue() =>
      _local.watchQueue().map((QueueAgg a) => ReviewQueue(
            newCount: a.newCount,
            learningCount: a.learningCount,
            reviewCount: a.reviewCount,
          ));

  // ── Stats / dashboard ───────────────────────────────────────────────────────

  @override
  Stream<FlashcardStats> watchStats() =>
      _local.watchStats().map((StatsAgg a) => FlashcardStats(
            totalDecks: a.totalDecks,
            totalCards: a.totalCards,
            todayReviews: a.todayReviews,
            completedReviews: a.completedReviews,
            correctReviews: a.correctReviews,
            difficultCards: a.difficultCards,
            favoriteCards: a.favoriteCards,
            studyMinutes: (a.studyMs / 60000).round(),
            weeklyReviews: a.weeklyReviews,
            monthlyReviews: a.monthlyReviews,
          ));

  @override
  Stream<List<Flashcard>> watchDifficultCards({int limit = 30}) => _local
      .watchDifficultCards(limit)
      .map((List<FlashcardRow> r) => r.map(_toCard).toList(growable: false));

  @override
  Stream<List<ReviewActivity>> watchRecentActivity({int limit = 20}) =>
      _local.watchRecentActivity(limit).map((List<QueryRow> rows) => rows
          .map((QueryRow r) => ReviewActivity(
                cardFront: r.read<String?>('front') ?? '(deleted card)',
                deckName: r.read<String?>('deck_name') ?? '(deleted deck)',
                rating: _rating(r.read<int>('rating')),
                reviewedAt: DateTime.fromMillisecondsSinceEpoch(
                    (r.read<int?>('reviewed_at') ?? 0) * 1000),
              ))
          .toList(growable: false));

  // ── Colours + suggestions ───────────────────────────────────────────────────

  @override
  Stream<Map<String, int>> watchSubjectColors() =>
      _local.watchSubjectRows().map((List<StudySubjectRow> rows) =>
          <String, int>{for (final StudySubjectRow r in rows) r.nameLower: r.color});

  @override
  Future<List<String>> subjectSuggestions() => _local.subjectValues();

  @override
  Future<List<String>> tagSuggestions() async {
    final List<String> raw = await _local.tagRawValues();
    final Set<String> tags = <String>{};
    for (final String v in raw) {
      for (final String t in v.split(',')) {
        final String tt = t.trim();
        if (tt.isNotEmpty) tags.add(tt);
      }
    }
    final List<String> list = tags.toList()
      ..sort((String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  // ── Import ────────────────────────────────────────────────────────────────────

  @override
  Future<List<ImportCandidate>> importCandidates(ImportSource source,
      {String query = '', int limit = 100}) {
    switch (source) {
      case ImportSource.dictionary:
        return _local.importFromDictionary(query, limit);
      case ImportSource.vocabulary:
        return _local.importFromVocabulary(query, limit);
      case ImportSource.studyHub:
        return _local.importFromStudyHub(query, limit);
    }
  }

  @override
  Future<int> importCards(String deckId, List<ImportCandidate> items) async {
    final DateTime now = DateTime.now();
    final List<FlashcardsCompanion> companions = items
        .map((ImportCandidate i) => _companion(Flashcard(
              id: _uuid.v4(),
              deckId: deckId,
              front: i.front,
              back: i.back,
              subject: i.subject,
              topic: i.topic,
              createdAt: now,
              updatedAt: now,
            )))
        .toList();
    if (companions.isNotEmpty) await _local.insertCards(companions);
    return companions.length;
  }

  // ── Backup ────────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> exportBackup() async => <String, dynamic>{
        'app': 'sapiora',
        'type': 'flashcards_backup',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'decks': (await _local.allDecks()).map((DeckRow r) => r.toJson()).toList(),
        'cards':
            (await _local.allCards()).map((FlashcardRow r) => r.toJson()).toList(),
        'logs':
            (await _local.allLogs()).map((ReviewLogRow r) => r.toJson()).toList(),
      };

  @override
  Future<void> importBackup(Map<String, dynamic> data) async {
    List<Map<String, dynamic>> rows(String key) =>
        ((data[key] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => (e as Map).cast<String, dynamic>())
            .toList();
    await _local.replaceAll(
      decks: rows('decks')
          .map((Map<String, dynamic> m) => DeckRow.fromJson(m).toCompanion(true))
          .toList(),
      cards: rows('cards')
          .map((Map<String, dynamic> m) =>
              FlashcardRow.fromJson(m).toCompanion(true))
          .toList(),
      logs: rows('logs')
          .map((Map<String, dynamic> m) =>
              ReviewLogRow.fromJson(m).toCompanion(true))
          .toList(),
    );
  }

  // ── Mapping ─────────────────────────────────────────────────────────────────

  FlashcardsCompanion _companion(Flashcard c) {
    final String search = <String?>[
      c.front,
      c.back,
      c.subject,
      c.topic,
      c.tags,
      c.notes,
    ].whereType<String>().join(' ').toLowerCase();
    return FlashcardsCompanion.insert(
      id: c.id,
      deckId: c.deckId,
      front: c.front,
      back: c.back,
      subject: Value<String?>(c.subject),
      topic: Value<String?>(c.topic),
      tags: Value<String?>(c.tags),
      notes: Value<String?>(c.notes),
      difficulty: Value<int>(c.difficulty.index),
      bookmarked: Value<bool>(c.bookmarked),
      favorite: Value<bool>(c.favorite),
      reviewState: Value<int>(c.reviewState.index),
      dueAt: Value<DateTime?>(c.dueAt),
      intervalDays: Value<int>(c.intervalDays),
      easeFactor: Value<double>(c.easeFactor),
      repetitions: Value<int>(c.repetitions),
      lapses: Value<int>(c.lapses),
      lastReviewedAt: Value<DateTime?>(c.lastReviewedAt),
      searchText: Value<String>(search),
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  Deck _toDeck(DeckRow r) => Deck(
        id: r.id,
        name: r.name,
        description: r.description,
        subject: r.subject,
        topic: r.topic,
        color: r.color,
        icon: r.icon,
        archived: r.archived,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  Flashcard _toCard(FlashcardRow r) => Flashcard(
        id: r.id,
        deckId: r.deckId,
        front: r.front,
        back: r.back,
        subject: r.subject,
        topic: r.topic,
        tags: r.tags,
        notes: r.notes,
        difficulty: CardDifficulty.fromIndex(r.difficulty),
        bookmarked: r.bookmarked,
        favorite: r.favorite,
        reviewState: ReviewState.fromIndex(r.reviewState),
        dueAt: r.dueAt,
        intervalDays: r.intervalDays,
        easeFactor: r.easeFactor,
        repetitions: r.repetitions,
        lapses: r.lapses,
        lastReviewedAt: r.lastReviewedAt,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  CardRating _rating(int i) => (i >= 0 && i < CardRating.values.length)
      ? CardRating.values[i]
      : CardRating.good;
}

import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/domain/flashcard_dates.dart';

typedef QueueAgg = ({int newCount, int learningCount, int reviewCount});
typedef StatsAgg = ({
  int totalDecks,
  int totalCards,
  int todayReviews,
  int completedReviews,
  int correctReviews,
  int difficultCards,
  int favoriteCards,
  int studyMs,
  int weeklyReviews,
  int monthlyReviews,
});

/// All Drift queries for Flashcards. Reads of other modules' tables
/// (study_subjects, dictionary, vocabulary, study_tasks) are strictly
/// read-only — no other module is modified.
class FlashcardLocalDataSource {
  FlashcardLocalDataSource(this._db);

  final AppDatabase _db;

  // ── Decks ───────────────────────────────────────────────────────────────────

  Stream<List<QueryRow>> watchDeckSummaries(bool includeArchived) {
    final int now = nowUnixSeconds();
    final String archivedClause = includeArchived ? '' : 'WHERE d.archived = 0';
    return _db
        .customSelect(
          'SELECT d.*, '
          '(SELECT COUNT(*) FROM flashcards f WHERE f.deck_id = d.id) AS card_count, '
          '(SELECT COUNT(*) FROM flashcards f WHERE f.deck_id = d.id '
          '  AND (f.review_state = 0 OR f.due_at IS NULL OR f.due_at <= ?)) AS due_count '
          'FROM decks d $archivedClause ORDER BY d.name COLLATE NOCASE',
          variables: <Variable<Object>>[Variable.withInt(now)],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.decks,
            _db.flashcards,
          },
        )
        .watch();
  }

  /// Maps a `decks.*` custom-query row to a typed [DeckRow].
  DeckRow deckRowFrom(QueryRow r) => _db.decks.map(r.data);

  Future<DeckRow?> deck(String id) =>
      (_db.select(_db.decks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertDeck(DecksCompanion d) =>
      _db.into(_db.decks).insertOnConflictUpdate(d);

  Future<void> updateDeck(String id, DecksCompanion d) =>
      (_db.update(_db.decks)..where((t) => t.id.equals(id))).write(d);

  Future<void> deleteDeck(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.flashcards)..where((t) => t.deckId.equals(id))).go();
      await (_db.delete(_db.reviewLogs)..where((t) => t.deckId.equals(id))).go();
      await (_db.delete(_db.decks)..where((t) => t.id.equals(id))).go();
    });
  }

  // ── Cards ───────────────────────────────────────────────────────────────────

  Future<FlashcardRow?> card(String id) =>
      (_db.select(_db.flashcards)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsertCard(FlashcardsCompanion c) =>
      _db.into(_db.flashcards).insertOnConflictUpdate(c);

  Future<void> insertCards(List<FlashcardsCompanion> cards) =>
      _db.batch((Batch b) => b.insertAll(_db.flashcards, cards));

  Future<void> deleteCard(String id) =>
      (_db.delete(_db.flashcards)..where((t) => t.id.equals(id))).go();

  Future<void> updateCard(String id, FlashcardsCompanion c) =>
      (_db.update(_db.flashcards)..where((t) => t.id.equals(id))).write(c);

  /// Paginated, filtered card search. Text matches front/back/subject/topic/
  /// tags/notes; all filters combine.
  Future<List<FlashcardRow>> searchCards(
    FlashcardFilter f, {
    int limit = 50,
    int offset = 0,
  }) async {
    final StringBuffer sql = StringBuffer('SELECT * FROM flashcards WHERE 1 = 1');
    final List<Variable<Object>> vars = <Variable<Object>>[];
    final String q = f.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      sql.write(' AND LOWER(front || \' \' || back || \' \' '
          "|| COALESCE(subject,'') || ' ' || COALESCE(topic,'') || ' ' "
          "|| COALESCE(tags,'') || ' ' || COALESCE(notes,'')) LIKE ?");
      vars.add(Variable.withString('%$q%'));
    }
    if (f.deckId != null) {
      sql.write(' AND deck_id = ?');
      vars.add(Variable.withString(f.deckId!));
    }
    if (f.subject != null && f.subject!.isNotEmpty) {
      sql.write(' AND LOWER(COALESCE(subject,\'\')) = ?');
      vars.add(Variable.withString(f.subject!.toLowerCase()));
    }
    if (f.topic != null && f.topic!.isNotEmpty) {
      sql.write(' AND LOWER(COALESCE(topic,\'\')) = ?');
      vars.add(Variable.withString(f.topic!.toLowerCase()));
    }
    if (f.tag != null && f.tag!.isNotEmpty) {
      sql.write(' AND LOWER(COALESCE(tags,\'\')) LIKE ?');
      vars.add(Variable.withString('%${f.tag!.toLowerCase()}%'));
    }
    if (f.onlyBookmarked) sql.write(' AND bookmarked = 1');
    if (f.onlyFavorite) sql.write(' AND favorite = 1');
    if (f.difficulty != null) {
      sql.write(' AND difficulty = ?');
      vars.add(Variable.withInt(f.difficulty!.index));
    }
    switch (f.status) {
      case CardStatusFilter.all:
        break;
      case CardStatusFilter.completed:
        sql.write(' AND review_state != 0');
      case CardStatusFilter.pending:
        sql.write(' AND (review_state = 0 OR due_at IS NULL OR due_at <= ?)');
        vars.add(Variable.withInt(nowUnixSeconds()));
    }
    sql.write(f.sort == CardSort.alphabetical
        ? ' ORDER BY front COLLATE NOCASE'
        : ' ORDER BY created_at DESC');
    sql.write(' LIMIT ? OFFSET ?');
    vars..add(Variable.withInt(limit))..add(Variable.withInt(offset));

    final List<QueryRow> rows = await _db
        .customSelect(sql.toString(),
            variables: vars,
            readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.flashcards})
        .get();
    return rows.map((QueryRow r) => _db.flashcards.map(r.data)).toList();
  }

  /// Cards for a study session (mode + optional deck).
  Future<List<FlashcardRow>> studySession({
    String? deckId,
    required StudyMode mode,
    int limit = 200,
  }) async {
    final StringBuffer sql = StringBuffer('SELECT * FROM flashcards WHERE 1 = 1');
    final List<Variable<Object>> vars = <Variable<Object>>[];
    if (deckId != null) {
      sql.write(' AND deck_id = ?');
      vars.add(Variable.withString(deckId));
    }
    switch (mode) {
      case StudyMode.due:
        sql.write(' AND (review_state = 0 OR due_at IS NULL OR due_at <= ?)');
        vars.add(Variable.withInt(nowUnixSeconds()));
        sql.write(' ORDER BY review_state, due_at');
      case StudyMode.all:
        sql.write(' ORDER BY created_at');
      case StudyMode.bookmarked:
        sql.write(' AND bookmarked = 1 ORDER BY created_at');
      case StudyMode.difficult:
        sql.write(' AND difficulty = 3 ORDER BY created_at');
      case StudyMode.newOnly:
        sql.write(' AND review_state = 0 ORDER BY created_at');
      case StudyMode.shuffle:
        sql.write(' ORDER BY RANDOM()');
    }
    sql.write(' LIMIT ?');
    vars.add(Variable.withInt(limit));
    final List<QueryRow> rows = await _db
        .customSelect(sql.toString(),
            variables: vars,
            readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.flashcards})
        .get();
    return rows.map((QueryRow r) => _db.flashcards.map(r.data)).toList();
  }

  Future<void> insertReviewLog(ReviewLogsCompanion log) =>
      _db.into(_db.reviewLogs).insert(log);

  // ── Queue / stats ───────────────────────────────────────────────────────────

  Stream<QueueAgg> watchQueue() {
    final int now = nowUnixSeconds();
    return _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM flashcards WHERE review_state = 0) AS n, '
          '(SELECT COUNT(*) FROM flashcards WHERE review_state = 1 '
          '  AND (due_at IS NULL OR due_at <= ?)) AS l, '
          '(SELECT COUNT(*) FROM flashcards WHERE review_state = 2 '
          '  AND (due_at IS NULL OR due_at <= ?)) AS r',
          variables: <Variable<Object>>[
            Variable.withInt(now),
            Variable.withInt(now),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.flashcards},
        )
        .watchSingle()
        .map((QueryRow row) => (
              newCount: row.read<int>('n'),
              learningCount: row.read<int>('l'),
              reviewCount: row.read<int>('r'),
            ));
  }

  Stream<StatsAgg> watchStats() {
    final String today = todayKey();
    final String week = weekStartKey();
    final String month = monthStartKey();
    return _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM decks WHERE archived = 0) AS decks, '
          '(SELECT COUNT(*) FROM flashcards) AS cards, '
          '(SELECT COUNT(*) FROM review_logs WHERE day = ?) AS today_reviews, '
          '(SELECT COUNT(*) FROM review_logs) AS completed_reviews, '
          '(SELECT COUNT(*) FROM review_logs WHERE rating >= 2) AS correct_reviews, '
          '(SELECT COUNT(*) FROM flashcards WHERE difficulty = 3) AS difficult, '
          '(SELECT COUNT(*) FROM flashcards WHERE favorite = 1) AS favorite, '
          '(SELECT COALESCE(SUM(duration_ms),0) FROM review_logs) AS study_ms, '
          '(SELECT COUNT(*) FROM review_logs WHERE day >= ?) AS weekly, '
          '(SELECT COUNT(*) FROM review_logs WHERE day >= ?) AS monthly',
          variables: <Variable<Object>>[
            Variable.withString(today),
            Variable.withString(week),
            Variable.withString(month),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.decks,
            _db.flashcards,
            _db.reviewLogs,
          },
        )
        .watchSingle()
        .map((QueryRow r) => (
              totalDecks: r.read<int>('decks'),
              totalCards: r.read<int>('cards'),
              todayReviews: r.read<int>('today_reviews'),
              completedReviews: r.read<int>('completed_reviews'),
              correctReviews: r.read<int>('correct_reviews'),
              difficultCards: r.read<int>('difficult'),
              favoriteCards: r.read<int>('favorite'),
              studyMs: r.read<int>('study_ms'),
              weeklyReviews: r.read<int>('weekly'),
              monthlyReviews: r.read<int>('monthly'),
            ));
  }

  Stream<List<FlashcardRow>> watchDifficultCards(int limit) =>
      (_db.select(_db.flashcards)
            ..where((t) => t.difficulty.equals(_hardDifficulty))
            ..orderBy(<OrderClauseGenerator<$FlashcardsTable>>[
              (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
            ])
            ..limit(limit))
          .watch();

  static const int _hardDifficulty = 3;

  Stream<List<QueryRow>> watchRecentActivity(int limit) => _db
      .customSelect(
        'SELECT l.rating AS rating, l.reviewed_at AS reviewed_at, '
        'f.front AS front, d.name AS deck_name '
        'FROM review_logs l '
        'LEFT JOIN flashcards f ON f.id = l.card_id '
        'LEFT JOIN decks d ON d.id = l.deck_id '
        'ORDER BY l.reviewed_at DESC LIMIT ?',
        variables: <Variable<Object>>[Variable.withInt(limit)],
        readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
          _db.reviewLogs,
          _db.flashcards,
          _db.decks,
        },
      )
      .watch();

  // ── Subject colours (reused, read-only) + suggestions ───────────────────────

  Stream<List<StudySubjectRow>> watchSubjectRows() =>
      _db.select(_db.studySubjects).watch();

  Future<List<String>> subjectValues() =>
      distinctCardValues(_db.flashcards.subject);
  Future<List<String>> tagRawValues() =>
      distinctCardValues(_db.flashcards.tags);

  Future<List<String>> distinctCardValues(GeneratedColumn<String> col) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT DISTINCT ${col.name} AS v FROM flashcards '
          "WHERE ${col.name} IS NOT NULL AND ${col.name} != '' "
          'ORDER BY ${col.name} COLLATE NOCASE',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.flashcards},
        )
        .get();
    return rows.map((QueryRow r) => r.read<String>('v')).toList();
  }

  // ── Import sources (read-only from other modules) ───────────────────────────

  Future<List<ImportCandidate>> importFromDictionary(String query, int limit) async {
    final String q = query.trim().toLowerCase();
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT word, meaning FROM dictionary_entries '
          '${q.isEmpty ? '' : 'WHERE LOWER(word) LIKE ?'} '
          'GROUP BY LOWER(word) ORDER BY word COLLATE NOCASE LIMIT ?',
          variables: <Variable<Object>>[
            if (q.isNotEmpty) Variable.withString('$q%'),
            Variable.withInt(limit),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.dictionaryEntries,
          },
        )
        .get();
    return rows
        .map((QueryRow r) => ImportCandidate(
              front: r.read<String>('word'),
              back: r.read<String>('meaning'),
            ))
        .toList();
  }

  Future<List<ImportCandidate>> importFromVocabulary(String query, int limit) async {
    final String q = query.trim().toLowerCase();
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT word, english_meaning, urdu_meaning FROM vocabulary_words '
          '${q.isEmpty ? '' : 'WHERE word_lower LIKE ?'} '
          'ORDER BY word_lower LIMIT ?',
          variables: <Variable<Object>>[
            if (q.isNotEmpty) Variable.withString('$q%'),
            Variable.withInt(limit),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.vocabularyWords,
          },
        )
        .get();
    return rows
        .map((QueryRow r) => ImportCandidate(
              front: r.read<String>('word'),
              back: '${r.read<String>('english_meaning')} — '
                  '${r.read<String>('urdu_meaning')}',
            ))
        .toList();
  }

  Future<List<ImportCandidate>> importFromStudyHub(String query, int limit) async {
    final String q = query.trim().toLowerCase();
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT DISTINCT COALESCE(subject, title) AS subject, '
          'COALESCE(topic, \'\') AS topic FROM study_tasks '
          "WHERE kind = 'session' AND COALESCE(subject, title) != '' "
          '${q.isEmpty ? '' : "AND (LOWER(COALESCE(subject,title)) LIKE ? OR LOWER(COALESCE(topic,'')) LIKE ?)"} '
          'ORDER BY subject COLLATE NOCASE LIMIT ?',
          variables: <Variable<Object>>[
            if (q.isNotEmpty) Variable.withString('%$q%'),
            if (q.isNotEmpty) Variable.withString('%$q%'),
            Variable.withInt(limit),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.studyTasks},
        )
        .get();
    return rows.map((QueryRow r) {
      final String subject = r.read<String>('subject');
      final String topic = r.read<String>('topic');
      return ImportCandidate(
        front: topic.isNotEmpty ? topic : subject,
        back: subject,
        subject: subject,
        topic: topic.isEmpty ? null : topic,
      );
    }).toList();
  }

  // ── Backup ───────────────────────────────────────────────────────────────────

  Future<List<DeckRow>> allDecks() => _db.select(_db.decks).get();
  Future<List<FlashcardRow>> allCards() => _db.select(_db.flashcards).get();
  Future<List<ReviewLogRow>> allLogs() => _db.select(_db.reviewLogs).get();

  Future<void> replaceAll({
    required List<DecksCompanion> decks,
    required List<FlashcardsCompanion> cards,
    required List<ReviewLogsCompanion> logs,
  }) async {
    await _db.transaction(() async {
      await _db.delete(_db.reviewLogs).go();
      await _db.delete(_db.flashcards).go();
      await _db.delete(_db.decks).go();
      await _db.batch((Batch b) {
        b.insertAll(_db.decks, decks);
        b.insertAll(_db.flashcards, cards);
        b.insertAll(_db.reviewLogs, logs);
      });
    });
  }
}

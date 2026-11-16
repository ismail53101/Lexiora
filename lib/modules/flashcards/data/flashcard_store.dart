import 'dart:async';

import 'package:lexiora/modules/flashcards/data/backup_codec.dart';
import 'package:lexiora/modules/flashcards/data/fc_sql.dart';
import 'package:lexiora/modules/flashcards/data/flashcard_schema.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/fc_time.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_query.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_stats_models.dart';

/// Cards ready to study, already limited by each deck's daily caps.
class StudyQueueData {
  const StudyQueueData({
    required this.learning,
    required this.review,
    required this.newCards,
    required this.settings,
  });

  final List<FcCard> learning;
  final List<FcCard> review;
  final List<FcCard> newCards;
  final Map<String, DeckSettings> settings;
}

/// Every SQL statement of the flashcards engine. Works on the existing
/// `decks` / `flashcards` / `review_logs` tables plus the sidecar tables in
/// [FcSchema]. Reads of other modules' tables are strictly read-only.
class FlashcardStore {
  FlashcardStore(this._db);

  final FcSql _db;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Re-runs [query] whenever any flashcards data changes, and every
  /// [refreshEvery] so time-based counts (cards coming due) stay current.
  Stream<T> watch<T>(
    Future<T> Function() query, {
    Duration refreshEvery = const Duration(minutes: 1),
  }) {
    late final StreamController<T> c;
    StreamSubscription<void>? sub;
    Timer? timer;
    Future<void> run() async {
      try {
        final T v = await query();
        if (!c.isClosed) c.add(v);
      } catch (e, st) {
        if (!c.isClosed) c.addError(e, st);
      }
    }

    c = StreamController<T>(
      onListen: () {
        sub = _changes.stream.listen((_) => run());
        timer = Timer.periodic(refreshEvery, (_) => run());
        run();
      },
      onCancel: () {
        timer?.cancel();
        return sub?.cancel();
      },
    );
    return c.stream;
  }

  Future<void> dispose() => _changes.close();

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<List<Row>> _q(String sql, [List<Object?> args = const <Object?>[]]) =>
      _db.select(sql, args);

  Future<void> _x(String sql, [List<Object?> args = const <Object?>[]]) =>
      _db.execute(sql, args);

  static int _i(Row r, String k) => (r[k] as num?)?.toInt() ?? 0;
  static int? _iN(Row r, String k) => (r[k] as num?)?.toInt();
  static double? _dN(Row r, String k) => (r[k] as num?)?.toDouble();
  static String? _sN(Row r, String k) => r[k] as String?;
  static bool _b(Row r, String k) => _i(r, k) != 0;

  // ── decks ──────────────────────────────────────────────────────────────────

  FcDeck _deck(Row r) => FcDeck(
        id: _sN(r, 'id')!,
        name: _sN(r, 'name') ?? '',
        description: _sN(r, 'description'),
        subject: _sN(r, 'subject'),
        topic: _sN(r, 'topic'),
        color: _iN(r, 'color'),
        icon: _iN(r, 'icon'),
        archived: _b(r, 'archived'),
        createdAt: fromUnix(_i(r, 'created_at')),
        updatedAt: fromUnix(_i(r, 'updated_at')),
      );

  Future<List<FcDeck>> decks({bool includeArchived = false}) async {
    final List<Row> rows = await _q(
      'SELECT * FROM decks ${includeArchived ? '' : 'WHERE archived = 0'} '
      'ORDER BY name COLLATE NOCASE',
    );
    return rows.map(_deck).toList();
  }

  Future<FcDeck?> deck(String id) async {
    final List<Row> rows = await _q('SELECT * FROM decks WHERE id = ?', <Object?>[id]);
    return rows.isEmpty ? null : _deck(rows.first);
  }

  Future<void> saveDeck(FcDeck d) async {
    await _x(
      'INSERT OR REPLACE INTO decks '
      '(id, name, description, subject, topic, color, icon, archived, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        d.id, d.name, d.description, d.subject, d.topic, d.color, d.icon,
        d.archived ? 1 : 0, toUnix(d.createdAt), toUnix(d.updatedAt),
      ],
    );
    _notify();
  }

  Future<void> deleteDeck(String id) async {
    await _db.transaction(() async {
      await _x('DELETE FROM review_logs WHERE deck_id = ?', <Object?>[id]);
      await _x('DELETE FROM fc_card_state WHERE card_id IN '
          '(SELECT id FROM flashcards WHERE deck_id = ?)', <Object?>[id]);
      await _x('DELETE FROM flashcards WHERE deck_id = ?', <Object?>[id]);
      await _x('DELETE FROM fc_deck_settings WHERE deck_id = ?', <Object?>[id]);
      await _x('DELETE FROM decks WHERE id = ?', <Object?>[id]);
    });
    _notify();
  }

  Future<void> setArchived(String id, bool archived) async {
    await _x('UPDATE decks SET archived = ?, updated_at = ? WHERE id = ?',
        <Object?>[archived ? 1 : 0, toUnix(DateTime.now()), id]);
    _notify();
  }

  // ── deck settings ──────────────────────────────────────────────────────────

  DeckSettings _settings(Row r) => DeckSettings(
        newPerDay: _i(r, 'new_per_day'),
        reviewsPerDay: _i(r, 'reviews_per_day'),
        desiredRetention: _dN(r, 'desired_retention') ?? 0.9,
        shuffleNew: _b(r, 'shuffle_new'),
      );

  Future<Map<String, DeckSettings>> allSettings() async {
    final List<Row> rows = await _q('SELECT * FROM fc_deck_settings');
    return <String, DeckSettings>{
      for (final Row r in rows) _sN(r, 'deck_id')!: _settings(r),
    };
  }

  Future<DeckSettings> settingsFor(String deckId) async =>
      (await allSettings())[deckId] ?? DeckSettings.defaults;

  Future<void> saveSettings(String deckId, DeckSettings s) async {
    await _x(
      'INSERT OR REPLACE INTO fc_deck_settings '
      '(deck_id, new_per_day, reviews_per_day, desired_retention, shuffle_new) '
      'VALUES (?, ?, ?, ?, ?)',
      <Object?>[deckId, s.newPerDay, s.reviewsPerDay, s.desiredRetention, s.shuffleNew ? 1 : 0],
    );
    _notify();
  }

  // ── cards ──────────────────────────────────────────────────────────────────

  static const String _cardSelect = '''
SELECT f.id AS id, f.deck_id AS deck_id, f.front AS front, f.back AS back,
       f.subject AS subject, f.topic AS topic, f.tags AS tags, f.notes AS notes,
       f.bookmarked AS bookmarked, f.created_at AS created_at,
       f.updated_at AS updated_at,
       s.card_type AS card_type, s.cloze_index AS cloze_index,
       s.state AS state, s.step AS step, s.stability AS stability,
       s.difficulty AS difficulty, s.due_at AS due_at,
       s.last_review_at AS last_review_at, s.reps AS reps,
       s.lapses AS lapses, s.suspended AS suspended,
       s.buried_until AS buried_until
FROM flashcards f JOIN fc_card_state s ON s.card_id = f.id''';

  FcCard _card(Row r) {
    final int? last = _iN(r, 'last_review_at');
    final int buried = _i(r, 'buried_until');
    return FcCard(
      id: _sN(r, 'id')!,
      deckId: _sN(r, 'deck_id')!,
      front: _sN(r, 'front') ?? '',
      back: _sN(r, 'back') ?? '',
      type: FcCardType.fromValue(_iN(r, 'card_type')),
      clozeIndex: _iN(r, 'cloze_index'),
      subject: _sN(r, 'subject'),
      topic: _sN(r, 'topic'),
      tags: (_sN(r, 'tags') ?? '')
          .split(',')
          .map((String t) => t.trim())
          .where((String t) => t.isNotEmpty)
          .toList(),
      notes: _sN(r, 'notes'),
      bookmarked: _b(r, 'bookmarked'),
      suspended: _b(r, 'suspended'),
      buriedUntil: buried > 0 ? fromUnix(buried) : null,
      reps: _i(r, 'reps'),
      lapses: _i(r, 'lapses'),
      createdAt: fromUnix(_i(r, 'created_at')),
      updatedAt: fromUnix(_i(r, 'updated_at')),
      fsrs: FsrsCard(
        state: FsrsState.fromValue(_i(r, 'state')),
        step: _iN(r, 'step'),
        stability: _dN(r, 'stability'),
        difficulty: _dN(r, 'difficulty'),
        due: fromUnix(_i(r, 'due_at')),
        lastReview: last == null ? null : fromUnix(last),
      ),
    );
  }

  Future<FcCard?> card(String id) async {
    final List<Row> rows =
        await _q('$_cardSelect WHERE f.id = ?', <Object?>[id]);
    return rows.isEmpty ? null : _card(rows.first);
  }

  static String _searchText(FcCard c) => <String?>[
        c.front, c.back, c.subject, c.topic, c.tags.join(' '), c.notes,
      ].whereType<String>().join(' ').toLowerCase();

  Future<void> _insertCard(FcCard c) async {
    await _x(
      'INSERT OR REPLACE INTO flashcards '
      '(id, deck_id, front, back, subject, topic, tags, notes, difficulty, '
      'bookmarked, favorite, review_state, due_at, interval_days, ease_factor, '
      'repetitions, lapses, last_reviewed_at, search_text, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, 0, ?, ?, 0, 2.5, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        c.id, c.deckId, c.front, c.back, c.subject, c.topic,
        c.tags.isEmpty ? null : c.tags.join(','), c.notes,
        c.bookmarked ? 1 : 0, _legacyState(c.fsrs.state), toUnix(c.fsrs.due),
        c.reps, c.lapses,
        c.fsrs.lastReview == null ? null : toUnix(c.fsrs.lastReview!),
        _searchText(c), toUnix(c.createdAt), toUnix(c.updatedAt),
      ],
    );
    await _writeState(c);
  }

  Future<void> insertCards(List<FcCard> cards) async {
    if (cards.isEmpty) return;
    await _db.transaction(() async {
      for (final FcCard c in cards) {
        await _insertCard(c);
      }
    });
    _notify();
  }

  /// Edits content (front/back/tags/…); also keeps the search text in sync.
  Future<void> updateCardContent(FcCard c) async {
    await _db.transaction(() async {
      await _x(
        'UPDATE flashcards SET deck_id = ?, front = ?, back = ?, subject = ?, '
        'topic = ?, tags = ?, notes = ?, bookmarked = ?, search_text = ?, '
        'updated_at = ? WHERE id = ?',
        <Object?>[
          c.deckId, c.front, c.back, c.subject, c.topic,
          c.tags.isEmpty ? null : c.tags.join(','), c.notes,
          c.bookmarked ? 1 : 0, _searchText(c), toUnix(c.updatedAt), c.id,
        ],
      );
      await _x('UPDATE fc_card_state SET card_type = ?, cloze_index = ? WHERE card_id = ?',
          <Object?>[c.type.value, c.clozeIndex, c.id]);
    });
    _notify();
  }

  static int _legacyState(FsrsState s) => switch (s) {
        FsrsState.newCard => 0,
        FsrsState.learning || FsrsState.relearning => 1,
        FsrsState.review => 2,
      };

  Future<void> _writeState(FcCard c) async {
    await _x(
      'INSERT OR REPLACE INTO fc_card_state '
      '(card_id, card_type, cloze_index, state, step, stability, difficulty, '
      'due_at, last_review_at, reps, lapses, suspended, buried_until) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        c.id, c.type.value, c.clozeIndex, c.fsrs.state.value, c.fsrs.step,
        c.fsrs.stability, c.fsrs.difficulty, toUnix(c.fsrs.due),
        c.fsrs.lastReview == null ? null : toUnix(c.fsrs.lastReview!),
        c.reps, c.lapses, c.suspended ? 1 : 0,
        c.buriedUntil == null ? 0 : toUnix(c.buriedUntil!),
      ],
    );
  }

  /// Persists scheduling state. Also mirrors the basics into the legacy
  /// columns so an older app build still shows sensible values.
  Future<void> saveSchedule(FcCard c) async {
    await _db.transaction(() => _saveScheduleRows(c));
    _notify();
  }

  Future<void> _saveScheduleRows(FcCard c) async {
    await _writeState(c);
    await _x(
      'UPDATE flashcards SET review_state = ?, due_at = ?, interval_days = ?, '
      'repetitions = ?, lapses = ?, last_reviewed_at = ?, updated_at = ? '
      'WHERE id = ?',
      <Object?>[
        _legacyState(c.fsrs.state), toUnix(c.fsrs.due),
        (c.fsrs.stability ?? 0).round(), c.reps, c.lapses,
        c.fsrs.lastReview == null ? null : toUnix(c.fsrs.lastReview!),
        toUnix(c.updatedAt), c.id,
      ],
    );
  }

  /// Saves the card's new schedule and its review-log row atomically.
  Future<void> recordReview({
    required FcCard card,
    required String logId,
    required FsrsRating rating,
    required DateTime at,
    required int durationMs,
  }) async {
    await _db.transaction(() async {
      await _saveScheduleRows(card);
      await _x(
        'INSERT INTO review_logs (id, card_id, deck_id, rating, day, reviewed_at, duration_ms) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        <Object?>[logId, card.id, card.deckId, rating.value - 1, studyDayKey(at), toUnix(at), durationMs],
      );
    });
    _notify();
  }

  /// Puts [before] back and removes the log row [logId] (undo).
  Future<void> undoReview({required FcCard before, required String logId}) async {
    await _db.transaction(() async {
      await _saveScheduleRows(before);
      await _x('DELETE FROM review_logs WHERE id = ?', <Object?>[logId]);
    });
    _notify();
  }

  Future<void> setFlag(String id, {bool? bookmarked, bool? suspended, DateTime? buriedUntil, bool clearBury = false}) async {
    await _db.transaction(() async {
      if (bookmarked != null) {
        await _x('UPDATE flashcards SET bookmarked = ? WHERE id = ?',
            <Object?>[bookmarked ? 1 : 0, id]);
      }
      if (suspended != null) {
        await _x('UPDATE fc_card_state SET suspended = ? WHERE card_id = ?',
            <Object?>[suspended ? 1 : 0, id]);
      }
      if (buriedUntil != null || clearBury) {
        await _x('UPDATE fc_card_state SET buried_until = ? WHERE card_id = ?',
            <Object?>[clearBury ? 0 : toUnix(buriedUntil!), id]);
      }
    });
    _notify();
  }

  Future<void> deleteCards(List<String> ids) async {
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      for (final String id in ids) {
        await _x('DELETE FROM review_logs WHERE card_id = ?', <Object?>[id]);
        await _x('DELETE FROM fc_card_state WHERE card_id = ?', <Object?>[id]);
        await _x('DELETE FROM flashcards WHERE id = ?', <Object?>[id]);
      }
    });
    _notify();
  }

  Future<void> moveCards(List<String> ids, String deckId) async {
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      for (final String id in ids) {
        await _x('UPDATE flashcards SET deck_id = ?, updated_at = ? WHERE id = ?',
            <Object?>[deckId, toUnix(DateTime.now()), id]);
        await _x('UPDATE review_logs SET deck_id = ? WHERE card_id = ?',
            <Object?>[deckId, id]);
      }
    });
    _notify();
  }

  /// Browse/search cards.
  Future<List<FcCard>> browse(FcCardQuery q, DateTime now) async {
    final List<String> where = <String>[];
    final List<Object?> args = <Object?>[];
    if (q.deckId != null) {
      where.add('f.deck_id = ?');
      args.add(q.deckId);
    }
    final String text = q.text.trim().toLowerCase();
    if (text.isNotEmpty) {
      where.add("f.search_text LIKE ? ESCAPE '\\'");
      args.add('%${text.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%');
    }
    if (q.tag != null && q.tag!.isNotEmpty) {
      where.add("(',' || REPLACE(LOWER(COALESCE(f.tags, '')), ', ', ',') || ',') LIKE ?");
      args.add('%,${q.tag!.toLowerCase()},%');
    }
    switch (q.status) {
      case FcStatusFilter.all:
        break;
      case FcStatusFilter.newCards:
        where.add('s.state = 0');
      case FcStatusFilter.learning:
        where.add('s.state IN (1, 3)');
      case FcStatusFilter.review:
        where.add('s.state = 2');
      case FcStatusFilter.suspended:
        where.add('s.suspended = 1');
      case FcStatusFilter.starred:
        where.add('f.bookmarked = 1');
      case FcStatusFilter.leeches:
        where.add('s.lapses >= ?');
        args.add(FcCard.leechThreshold);
    }
    final String order = switch (q.sort) {
      FcSort.recent => 'f.created_at DESC, f.id',
      FcSort.alphabetical => 'f.front COLLATE NOCASE',
      FcSort.due => 's.state = 0, s.due_at',
    };
    args
      ..add(q.limit)
      ..add(q.offset);
    final List<Row> rows = await _q(
      '$_cardSelect ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} '
      'ORDER BY $order LIMIT ? OFFSET ?',
      args,
    );
    return rows.map(_card).toList();
  }

  Future<int> countCards(String deckId) async {
    final List<Row> r =
        await _q('SELECT COUNT(*) AS n FROM flashcards WHERE deck_id = ?', <Object?>[deckId]);
    return _i(r.first, 'n');
  }

  // ── study queue ────────────────────────────────────────────────────────────

  Future<Map<String, int>> _newDoneToday(String day) async {
    final List<Row> rows = await _q(
      'SELECT deck_id, COUNT(*) AS n FROM '
      '(SELECT card_id, deck_id, MIN(day) AS first_day FROM review_logs GROUP BY card_id) '
      'WHERE first_day = ? GROUP BY deck_id',
      <Object?>[day],
    );
    return <String, int>{for (final Row r in rows) _sN(r, 'deck_id')!: _i(r, 'n')};
  }

  Future<Map<String, int>> _reviewsDoneToday(String day) async {
    final List<Row> rows = await _q(
      'SELECT l.deck_id AS deck_id, COUNT(*) AS n FROM review_logs l '
      'WHERE l.day = ? AND EXISTS (SELECT 1 FROM review_logs p '
      'WHERE p.card_id = l.card_id AND p.day < ?) GROUP BY l.deck_id',
      <Object?>[day, day],
    );
    return <String, int>{for (final Row r in rows) _sN(r, 'deck_id')!: _i(r, 'n')};
  }

  /// What is due in [deckId] (or every active deck when null), honouring each
  /// deck's daily limits.
  Future<StudyQueueData> queue({
    String? deckId,
    required DateTime now,
    Duration learnAhead = const Duration(minutes: 20),
  }) async {
    final String day = studyDayKey(now);
    final List<FcDeck> scope = deckId != null
        ? <FcDeck>[?await deck(deckId)]
        : await decks();
    final Map<String, DeckSettings> all = await allSettings();
    final Map<String, int> newDone = await _newDoneToday(day);
    final Map<String, int> revDone = await _reviewsDoneToday(day);
    final int nowS = toUnix(now);
    final int aheadS = toUnix(now.add(learnAhead));

    final List<FcCard> learning = <FcCard>[];
    final List<FcCard> review = <FcCard>[];
    final List<FcCard> fresh = <FcCard>[];
    final Map<String, DeckSettings> used = <String, DeckSettings>{};

    for (final FcDeck d in scope) {
      final DeckSettings st = all[d.id] ?? DeckSettings.defaults;
      used[d.id] = st;
      const String ok = 's.suspended = 0 AND s.buried_until <= ?';
      learning.addAll((await _q(
        '$_cardSelect WHERE f.deck_id = ? AND s.state IN (1, 3) AND $ok '
        'AND s.due_at <= ? ORDER BY s.due_at',
        <Object?>[d.id, nowS, aheadS],
      )).map(_card));

      final int revLeft = (st.reviewsPerDay - (revDone[d.id] ?? 0)).clamp(0, 1 << 30);
      if (revLeft > 0) {
        review.addAll((await _q(
          '$_cardSelect WHERE f.deck_id = ? AND s.state = 2 AND $ok '
          'AND s.due_at <= ? ORDER BY (s.due_at / 86400), RANDOM() LIMIT ?',
          <Object?>[d.id, nowS, nowS, revLeft],
        )).map(_card));
      }
      final int newLeft = (st.newPerDay - (newDone[d.id] ?? 0)).clamp(0, 1 << 30);
      if (newLeft > 0) {
        fresh.addAll((await _q(
          '$_cardSelect WHERE f.deck_id = ? AND s.state = 0 AND $ok '
          'ORDER BY ${st.shuffleNew ? 'RANDOM()' : 'f.created_at, f.rowid'} LIMIT ?',
          <Object?>[d.id, nowS, newLeft],
        )).map(_card));
      }
    }
    return StudyQueueData(
      learning: learning,
      review: review,
      newCards: fresh,
      settings: used,
    );
  }

  /// Cards for a practice (non-scheduling) session.
  Future<List<FcCard>> practiceCards({
    String? deckId,
    required StudyMode mode,
    int limit = 500,
  }) async {
    final List<String> where = <String>['s.suspended = 0'];
    final List<Object?> args = <Object?>[];
    if (deckId != null) {
      where.add('f.deck_id = ?');
      args.add(deckId);
    } else {
      where.add('f.deck_id IN (SELECT id FROM decks WHERE archived = 0)');
    }
    if (mode == StudyMode.starred) where.add('f.bookmarked = 1');
    if (mode == StudyMode.leeches) {
      where
        ..removeAt(0)
        ..insert(0, '1 = 1')
        ..add('s.lapses >= ?');
      args.add(FcCard.leechThreshold);
    }
    args.add(limit);
    final List<Row> rows = await _q(
      '$_cardSelect WHERE ${where.join(' AND ')} ORDER BY RANDOM() LIMIT ?',
      args,
    );
    return rows.map(_card).toList();
  }

  /// Counts of what a normal session would contain right now, per deck.
  Future<Map<String, StudyCounts>> studyCountsByDeck(DateTime now) async {
    final String day = studyDayKey(now);
    final Map<String, DeckSettings> all = await allSettings();
    final Map<String, int> newDone = await _newDoneToday(day);
    final Map<String, int> revDone = await _reviewsDoneToday(day);
    final int nowS = toUnix(now);
    final int aheadS = toUnix(now.add(const Duration(minutes: 20)));
    final List<Row> rows = await _q(
      'SELECT f.deck_id AS deck_id, '
      'SUM(CASE WHEN s.state = 0 THEN 1 ELSE 0 END) AS n_new, '
      'SUM(CASE WHEN s.state IN (1, 3) AND s.due_at <= ? THEN 1 ELSE 0 END) AS n_learn, '
      'SUM(CASE WHEN s.state = 2 AND s.due_at <= ? THEN 1 ELSE 0 END) AS n_review '
      'FROM flashcards f JOIN fc_card_state s ON s.card_id = f.id '
      'WHERE s.suspended = 0 AND s.buried_until <= ? GROUP BY f.deck_id',
      <Object?>[aheadS, nowS, nowS],
    );
    final Map<String, StudyCounts> out = <String, StudyCounts>{};
    for (final Row r in rows) {
      final String id = _sN(r, 'deck_id')!;
      final DeckSettings st = all[id] ?? DeckSettings.defaults;
      final int newCap = (st.newPerDay - (newDone[id] ?? 0)).clamp(0, 1 << 30);
      final int revCap = (st.reviewsPerDay - (revDone[id] ?? 0)).clamp(0, 1 << 30);
      out[id] = StudyCounts(
        newCount: _i(r, 'n_new') < newCap ? _i(r, 'n_new') : newCap,
        learningCount: _i(r, 'n_learn'),
        reviewCount: _i(r, 'n_review') < revCap ? _i(r, 'n_review') : revCap,
      );
    }
    return out;
  }

  Future<List<FcDeckSummary>> deckSummaries(DateTime now, {bool includeArchived = false}) async {
    final List<FcDeck> list = await decks(includeArchived: includeArchived);
    final Map<String, StudyCounts> counts = await studyCountsByDeck(now);
    final List<Row> totals = await _q(
      'SELECT f.deck_id AS deck_id, COUNT(*) AS total, SUM(s.suspended) AS susp '
      'FROM flashcards f JOIN fc_card_state s ON s.card_id = f.id GROUP BY f.deck_id',
    );
    final Map<String, Row> byDeck = <String, Row>{
      for (final Row r in totals) _sN(r, 'deck_id')!: r,
    };
    return <FcDeckSummary>[
      for (final FcDeck d in list)
        FcDeckSummary(
          deck: d,
          total: byDeck[d.id] == null ? 0 : _i(byDeck[d.id]!, 'total'),
          suspendedCount: byDeck[d.id] == null ? 0 : _i(byDeck[d.id]!, 'susp'),
          newCount: counts[d.id]?.newCount ?? 0,
          learningCount: counts[d.id]?.learningCount ?? 0,
          reviewCount: counts[d.id]?.reviewCount ?? 0,
        ),
    ];
  }

  // ── review log ─────────────────────────────────────────────────────────────

  Future<void> insertLog({
    required String id,
    required String cardId,
    required String deckId,
    required FsrsRating rating,
    required DateTime at,
    required int durationMs,
  }) async {
    await _x(
      'INSERT INTO review_logs (id, card_id, deck_id, rating, day, reviewed_at, duration_ms) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      <Object?>[id, cardId, deckId, rating.value - 1, studyDayKey(at), toUnix(at), durationMs],
    );
    _notify();
  }

  Future<void> deleteLog(String id) async {
    await _x('DELETE FROM review_logs WHERE id = ?', <Object?>[id]);
    _notify();
  }

  // ── statistics ─────────────────────────────────────────────────────────────

  Future<List<DayCount>> dailyCounts(String sinceDay) async {
    final List<Row> rows = await _q(
      'SELECT day, COUNT(*) AS total, '
      'SUM(CASE WHEN rating >= 2 THEN 1 ELSE 0 END) AS good '
      'FROM review_logs WHERE day >= ? GROUP BY day ORDER BY day',
      <Object?>[sinceDay],
    );
    return <DayCount>[
      for (final Row r in rows) DayCount(_sN(r, 'day')!, _i(r, 'total'), _i(r, 'good')),
    ];
  }

  Future<Set<String>> studiedDays() async {
    final List<Row> rows = await _q('SELECT DISTINCT day FROM review_logs');
    return <String>{for (final Row r in rows) _sN(r, 'day')!};
  }

  Future<StateBreakdown> stateBreakdown() async {
    final List<Row> r = await _q(
      'SELECT '
      'SUM(CASE WHEN suspended = 0 AND state = 0 THEN 1 ELSE 0 END) AS n_new, '
      'SUM(CASE WHEN suspended = 0 AND state IN (1, 3) THEN 1 ELSE 0 END) AS n_learn, '
      'SUM(CASE WHEN suspended = 0 AND state = 2 AND COALESCE(stability, 0) < 21 THEN 1 ELSE 0 END) AS n_young, '
      'SUM(CASE WHEN suspended = 0 AND state = 2 AND COALESCE(stability, 0) >= 21 THEN 1 ELSE 0 END) AS n_mature, '
      'SUM(suspended) AS n_susp FROM fc_card_state',
    );
    final Row x = r.first;
    return StateBreakdown(
      newCards: _i(x, 'n_new'),
      learning: _i(x, 'n_learn'),
      young: _i(x, 'n_young'),
      mature: _i(x, 'n_mature'),
      suspended: _i(x, 'n_susp'),
    );
  }

  Future<List<DateTime>> reviewDueDates(DateTime until) async {
    final List<Row> rows = await _q(
      'SELECT due_at FROM fc_card_state WHERE state = 2 AND suspended = 0 AND due_at <= ?',
      <Object?>[toUnix(until)],
    );
    return <DateTime>[for (final Row r in rows) fromUnix(_i(r, 'due_at'))];
  }

  /// (total, passed) over reviews of already-seen cards since [sinceDay].
  Future<({int total, int passed})> retention(String sinceDay) async {
    final List<Row> r = await _q(
      'SELECT COUNT(*) AS total, '
      'SUM(CASE WHEN l.rating >= 1 THEN 1 ELSE 0 END) AS passed '
      'FROM review_logs l WHERE l.day >= ? AND EXISTS ('
      'SELECT 1 FROM review_logs p WHERE p.card_id = l.card_id '
      'AND p.reviewed_at < l.reviewed_at)',
      <Object?>[sinceDay],
    );
    return (total: _i(r.first, 'total'), passed: _i(r.first, 'passed'));
  }

  Future<FcTotals> totals() async {
    final List<Row> r = await _q(
      'SELECT (SELECT COUNT(*) FROM decks) AS decks, '
      '(SELECT COUNT(*) FROM flashcards) AS cards, '
      'COUNT(*) AS reviews, COALESCE(SUM(duration_ms), 0) AS ms FROM review_logs',
    );
    return FcTotals(
      decks: _i(r.first, 'decks'),
      cards: _i(r.first, 'cards'),
      reviews: _i(r.first, 'reviews'),
      studyMs: _i(r.first, 'ms'),
    );
  }

  Future<List<FcActivity>> recentActivity(int limit) async {
    final List<Row> rows = await _q(
      'SELECT l.rating AS rating, l.reviewed_at AS reviewed_at, f.front AS front, '
      'd.name AS deck_name FROM review_logs l '
      'LEFT JOIN flashcards f ON f.id = l.card_id '
      'LEFT JOIN decks d ON d.id = l.deck_id '
      'ORDER BY l.reviewed_at DESC LIMIT ?',
      <Object?>[limit],
    );
    return <FcActivity>[
      for (final Row r in rows)
        FcActivity(
          front: _sN(r, 'front') ?? '(deleted card)',
          deckName: _sN(r, 'deck_name') ?? '',
          rating: FsrsRating.fromValue(_i(r, 'rating') + 1),
          reviewedAt: fromUnix(_i(r, 'reviewed_at')),
        ),
    ];
  }

  // ── suggestions & subject colours ──────────────────────────────────────────

  Future<List<String>> subjectSuggestions() async {
    final List<Row> rows = await _q(
      "SELECT DISTINCT subject AS v FROM flashcards WHERE subject IS NOT NULL AND subject != '' "
      'ORDER BY subject COLLATE NOCASE',
    );
    return <String>[for (final Row r in rows) _sN(r, 'v')!];
  }

  Future<List<String>> tagSuggestions() async {
    final List<Row> rows = await _q(
      "SELECT tags FROM flashcards WHERE tags IS NOT NULL AND tags != ''",
    );
    final Set<String> out = <String>{};
    for (final Row r in rows) {
      for (final String t in (_sN(r, 'tags') ?? '').split(',')) {
        final String v = t.trim();
        if (v.isNotEmpty) out.add(v);
      }
    }
    return out.toList()..sort((String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Lower-cased subject name → ARGB colour, from the Study Planner (read-only).
  Future<Map<String, int>> subjectColors() async {
    try {
      final List<Row> rows =
          await _q('SELECT name, color FROM study_subjects WHERE archived = 0');
      return <String, int>{
        for (final Row r in rows) (_sN(r, 'name') ?? '').toLowerCase(): _i(r, 'color'),
      };
    } catch (_) {
      return const <String, int>{};
    }
  }

  // ── import from other modules (read-only) ──────────────────────────────────

  Future<List<ImportCandidate>> importFromDictionary(String query, int limit) async {
    final String q = query.trim().toLowerCase();
    final List<Row> rows = await _q(
      'SELECT word, meaning FROM dictionary_entries '
      '${q.isEmpty ? '' : 'WHERE LOWER(word) LIKE ?'} '
      'GROUP BY LOWER(word) ORDER BY word COLLATE NOCASE LIMIT ?',
      <Object?>[if (q.isNotEmpty) '$q%', limit],
    );
    return <ImportCandidate>[
      for (final Row r in rows)
        ImportCandidate(front: _sN(r, 'word') ?? '', back: _sN(r, 'meaning') ?? ''),
    ];
  }

  Future<List<ImportCandidate>> importFromVocabulary(String query, int limit) async {
    final String q = query.trim().toLowerCase();
    final List<Row> rows = await _q(
      'SELECT word, english_meaning, urdu_meaning FROM vocabulary_words '
      '${q.isEmpty ? '' : 'WHERE word_lower LIKE ?'} ORDER BY word_lower LIMIT ?',
      <Object?>[if (q.isNotEmpty) '$q%', limit],
    );
    return <ImportCandidate>[
      for (final Row r in rows)
        ImportCandidate(
          front: _sN(r, 'word') ?? '',
          back: '${_sN(r, 'english_meaning') ?? ''} — ${_sN(r, 'urdu_meaning') ?? ''}',
        ),
    ];
  }

  Future<List<ImportCandidate>> importFromStudyHub(String query, int limit) async {
    final String q = query.trim().toLowerCase();
    final List<Row> rows = await _q(
      "SELECT DISTINCT COALESCE(subject, title) AS subject, COALESCE(topic, '') AS topic "
      "FROM study_tasks WHERE kind = 'session' AND COALESCE(subject, title) != '' "
      "${q.isEmpty ? '' : "AND (LOWER(COALESCE(subject,title)) LIKE ? OR LOWER(COALESCE(topic,'')) LIKE ?)"} "
      'ORDER BY subject COLLATE NOCASE LIMIT ?',
      <Object?>[if (q.isNotEmpty) '%$q%', if (q.isNotEmpty) '%$q%', limit],
    );
    return <ImportCandidate>[
      for (final Row r in rows)
        () {
          final String subject = _sN(r, 'subject') ?? '';
          final String topic = _sN(r, 'topic') ?? '';
          return ImportCandidate(
            front: topic.isNotEmpty ? topic : subject,
            back: subject,
            subject: subject,
            topic: topic.isEmpty ? null : topic,
          );
        }(),
    ];
  }

  // ── backup / restore ───────────────────────────────────────────────────────

  Future<List<Map<String, Object?>>> _dump(String table, List<String> cols) async {
    final List<Row> rows = await _q('SELECT ${cols.join(', ')} FROM $table');
    return <Map<String, Object?>>[
      for (final Row r in rows) <String, Object?>{for (final String c in cols) c: r[c]},
    ];
  }

  Future<BackupData> dumpAll() async => BackupData(
        version: backupVersion,
        decks: await _dump('decks', FcSchema.deckCols),
        cards: await _dump('flashcards', FcSchema.cardCols),
        logs: await _dump('review_logs', FcSchema.logCols),
        states: await _dump(FcSchema.cardState, FcSchema.stateCols),
        settings: await _dump(FcSchema.deckSettings, FcSchema.settingsCols),
      );

  /// Replaces ALL flashcards data with [d] (one transaction).
  Future<void> restoreAll(BackupData d) async {
    await _db.transaction(() async {
      await _x('DELETE FROM review_logs');
      await _x('DELETE FROM fc_card_state');
      await _x('DELETE FROM fc_deck_settings');
      await _x('DELETE FROM flashcards');
      await _x('DELETE FROM decks');
      Future<void> put(String table, List<String> cols, List<Map<String, Object?>> rows) async {
        final String sql = 'INSERT OR REPLACE INTO $table (${cols.join(', ')}) '
            'VALUES (${List<String>.filled(cols.length, '?').join(', ')})';
        for (final Map<String, Object?> r in rows) {
          await _x(sql, <Object?>[for (final String c in cols) r[c]]);
        }
      }

      await put('decks', FcSchema.deckCols, d.decks);
      await put('flashcards', FcSchema.cardCols, d.cards);
      await put('review_logs', FcSchema.logCols, d.logs);
      await put(FcSchema.cardState, FcSchema.stateCols, d.states);
      await put(FcSchema.deckSettings, FcSchema.settingsCols, d.settings);
    });
    // Old (v1) backups carry no FSRS state: derive it for those cards.
    await FcSchema.ensure(_db);
    _notify();
  }
}

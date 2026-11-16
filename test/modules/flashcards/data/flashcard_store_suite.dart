import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/flashcards/data/backup_codec.dart';
import 'package:lexiora/modules/flashcards/data/fc_sql.dart';
import 'package:lexiora/modules/flashcards/data/flashcard_schema.dart';
import 'package:lexiora/modules/flashcards/data/flashcard_store.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/fc_time.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_query.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_stats_models.dart';

/// Shared by the Drift in-memory test and the dev-only SQLite harness.
/// [newSql] must return a brand-new empty database that already contains the
/// app's legacy tables (decks, flashcards, review_logs, …).
void defineStoreTests(
  Future<FcSql> Function() newSql, {
  bool seedImportTables = false,
}) {
  final DateTime t0 = DateTime(2026, 3, 10, 12);
  final String today = studyDayKey(t0);

  Future<(FcSql, FlashcardStore)> fresh() async {
    final FcSql sql = await newSql();
    await FcSchema.ensure(sql);
    return (sql, FlashcardStore(sql));
  }

  FcDeck deck(String id, {String? name}) => FcDeck(
        id: id,
        name: name ?? 'Deck $id',
        createdAt: t0,
        updatedAt: t0,
      );

  FcCard card(
    String id,
    String deckId, {
    String? front,
    String back = 'back',
    FcCardType type = FcCardType.basic,
    int? clozeIndex,
    List<String> tags = const <String>[],
    FsrsCard? fsrs,
    int createdMin = 0,
    bool suspended = false,
    bool bookmarked = false,
    int lapses = 0,
  }) =>
      FcCard(
        id: id,
        deckId: deckId,
        front: front ?? 'front $id',
        back: back,
        type: type,
        clozeIndex: clozeIndex,
        tags: tags,
        suspended: suspended,
        bookmarked: bookmarked,
        lapses: lapses,
        fsrs: fsrs ?? FsrsCard.fresh(t0),
        createdAt: t0.add(Duration(minutes: createdMin)),
        updatedAt: t0.add(Duration(minutes: createdMin)),
      );

  FsrsCard reviewDue(Duration fromNow, {double s = 5}) => FsrsCard(
        state: FsrsState.review,
        stability: s,
        difficulty: 5,
        due: t0.add(fromNow),
        lastReview: t0.subtract(const Duration(days: 5)),
      );

  Future<void> legacyDeck(FcSql s, String id) => s.execute(
        'INSERT INTO decks (id, name, created_at, updated_at) VALUES (?, ?, ?, ?)',
        <Object?>[id, 'Legacy $id', toUnix(t0), toUnix(t0)],
      );

  Future<void> legacyCard(
    FcSql s,
    String id, {
    int state = 0,
    int? due,
    int interval = 0,
    double ease = 2.5,
    int reps = 0,
    int lapses = 0,
    int? last,
  }) =>
      s.execute(
        'INSERT INTO flashcards (id, deck_id, front, back, review_state, due_at, '
        'interval_days, ease_factor, repetitions, lapses, last_reviewed_at, '
        'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          id, 'ld', 'Q $id', 'A $id', state, due, interval, ease, reps, lapses,
          last, toUnix(t0), toUnix(t0),
        ],
      );

  group('FcSchema', () {
    test('backfills legacy cards into FSRS state and is idempotent', () async {
      final FcSql sql = await newSql();
      await FcSchema.ensure(sql);
      await legacyDeck(sql, 'ld');
      await legacyCard(sql, 'c0');
      await legacyCard(sql, 'c1', state: 1, due: toUnix(t0));
      await legacyCard(sql, 'c2',
          state: 2,
          due: toUnix(t0.subtract(const Duration(days: 1))),
          interval: 10,
          reps: 4,
          lapses: 1,
          last: toUnix(t0.subtract(const Duration(days: 11))));
      await FcSchema.ensure(sql);
      await FcSchema.ensure(sql);
      final FlashcardStore store = FlashcardStore(sql);

      final FcCard c0 = (await store.card('c0'))!;
      expect(c0.state, FsrsState.newCard);
      final FcCard c1 = (await store.card('c1'))!;
      expect(c1.state, FsrsState.learning);
      expect(c1.fsrs.step, 0);
      final FcCard c2 = (await store.card('c2'))!;
      expect(c2.state, FsrsState.review);
      expect(c2.fsrs.stability, closeTo(10, 1e-9));
      expect(c2.fsrs.difficulty, closeTo(5, 1e-9));
      expect(c2.reps, 4);
      expect(c2.lapses, 1);
      expect(c2.fsrs.due, t0.subtract(const Duration(days: 1)));
      final List<Row> n = await sql.select('SELECT COUNT(*) AS n FROM fc_card_state');
      expect(n.first['n'], 3);
    });
  });

  group('cards', () {
    test('insert → read round trip keeps every field', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      final FcCard c = card(
        'a', 'd',
        front: 'The {{c1::heart}} pumps {{c2::blood}}',
        back: '',
        type: FcCardType.cloze,
        clozeIndex: 2,
        tags: <String>['bio', 'organs'],
        fsrs: reviewDue(const Duration(days: 3), s: 7.5),
        bookmarked: true,
      ).copyWith(reps: 9, lapses: 2, notes: () => 'note');
      await store.insertCards(<FcCard>[c]);
      final FcCard r = (await store.card('a'))!;
      expect(r.front, c.front);
      expect(r.type, FcCardType.cloze);
      expect(r.clozeIndex, 2);
      expect(r.tags, <String>['bio', 'organs']);
      expect(r.notes, 'note');
      expect(r.bookmarked, true);
      expect(r.reps, 9);
      expect(r.lapses, 2);
      expect(r.fsrs.state, FsrsState.review);
      expect(r.fsrs.stability, closeTo(7.5, 1e-9));
      expect(r.fsrs.due, c.fsrs.due);
    });

    test('updateCardContent changes text and search, keeps schedule', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      await store.insertCards(<FcCard>[
        card('a', 'd', front: 'old', fsrs: reviewDue(const Duration(days: 2)))
      ]);
      final FcCard a = (await store.card('a'))!;
      await store.updateCardContent(a.copyWith(front: 'Mitochondria', updatedAt: t0));
      final FcCard r = (await store.card('a'))!;
      expect(r.front, 'Mitochondria');
      expect(r.state, FsrsState.review);
      final List<FcCard> hit = await store.browse(const FcCardQuery(text: 'mitoch'), t0);
      expect(hit, hasLength(1));
    });

    test('saveSchedule persists FSRS state and mirrors legacy columns', () async {
      final (FcSql sql, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      await store.insertCards(<FcCard>[card('a', 'd')]);
      final FcCard a = (await store.card('a'))!;
      final DateTime due = t0.add(const Duration(days: 4));
      await store.saveSchedule(a.copyWith(
        fsrs: FsrsCard(
          state: FsrsState.review,
          stability: 4.2,
          difficulty: 6.1,
          due: due,
          lastReview: t0,
        ),
        reps: 1,
        updatedAt: t0,
      ));
      final FcCard r = (await store.card('a'))!;
      expect(r.fsrs.stability, closeTo(4.2, 1e-9));
      expect(r.fsrs.difficulty, closeTo(6.1, 1e-9));
      expect(r.fsrs.due, due);
      final List<Row> legacy = await sql.select(
          'SELECT review_state, interval_days, repetitions, due_at FROM flashcards WHERE id = ?',
          <Object?>['a']);
      expect(legacy.first['review_state'], 2);
      expect(legacy.first['interval_days'], 4);
      expect(legacy.first['repetitions'], 1);
      expect(legacy.first['due_at'], toUnix(due));
    });

    test('browse: deck, text (incl. % literal), tag, status, sort', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d1'));
      await store.saveDeck(deck('d2'));
      await store.insertCards(<FcCard>[
        card('1', 'd1', front: 'Zebra', tags: <String>['bio'], createdMin: 1),
        card('2', 'd1', front: 'apple 100% sure', tags: <String>['bio', 'fruit'], createdMin: 2, bookmarked: true),
        card('3', 'd1', front: 'Mango', createdMin: 3, suspended: true),
        card('4', 'd2', front: 'Other deck', createdMin: 4),
        card('5', 'd1', front: 'Leech', createdMin: 5, lapses: 9),
      ]);
      Future<List<String>> ids(FcCardQuery q) async =>
          (await store.browse(q, t0)).map((FcCard c) => c.id).toList();

      expect(await ids(const FcCardQuery(deckId: 'd1')), <String>['5', '3', '2', '1']);
      expect(await ids(const FcCardQuery(text: '100%')), <String>['2']);
      expect(await ids(const FcCardQuery(text: '_')), isEmpty);
      expect(await ids(const FcCardQuery(deckId: 'd1', tag: 'bio')), <String>['2', '1']);
      expect(await ids(const FcCardQuery(tag: 'fruit')), <String>['2']);
      expect(await ids(const FcCardQuery(status: FcStatusFilter.suspended)), <String>['3']);
      expect(await ids(const FcCardQuery(status: FcStatusFilter.starred)), <String>['2']);
      expect(await ids(const FcCardQuery(status: FcStatusFilter.leeches)), <String>['5']);
      expect(await ids(const FcCardQuery(status: FcStatusFilter.newCards, deckId: 'd2')), <String>['4']);
      expect(
        await ids(const FcCardQuery(deckId: 'd1', sort: FcSort.alphabetical)),
        <String>['2', '5', '3', '1'],
      );
      expect(await ids(const FcCardQuery(deckId: 'd1', limit: 2, offset: 1)), <String>['3', '2']);
    });

    test('flags, move and delete', () async {
      final (FcSql sql, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d1'));
      await store.saveDeck(deck('d2'));
      await store.insertCards(<FcCard>[card('a', 'd1'), card('b', 'd1')]);
      await store.setFlag('a', bookmarked: true, suspended: true);
      await store.setFlag('b', buriedUntil: t0.add(const Duration(hours: 5)));
      final FcCard a = (await store.card('a'))!;
      final FcCard b = (await store.card('b'))!;
      expect(a.bookmarked && a.suspended, true);
      expect(b.isBuried(t0), true);
      await store.setFlag('b', clearBury: true);
      expect((await store.card('b'))!.isBuried(t0), false);

      await store.insertLog(
          id: 'l1', cardId: 'a', deckId: 'd1', rating: FsrsRating.good, at: t0, durationMs: 1000);
      await store.moveCards(<String>['a'], 'd2');
      expect((await store.card('a'))!.deckId, 'd2');
      final List<Row> log = await sql.select('SELECT deck_id FROM review_logs WHERE id = ?', <Object?>['l1']);
      expect(log.first['deck_id'], 'd2');

      await store.deleteCards(<String>['a']);
      expect(await store.card('a'), isNull);
      expect(await sql.select('SELECT id FROM review_logs'), isEmpty);
      expect(await sql.select('SELECT card_id FROM fc_card_state WHERE card_id = ?', <Object?>['a']), isEmpty);
    });

    test('deleting a deck removes its cards, state, logs and settings', () async {
      final (FcSql sql, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d1'));
      await store.saveDeck(deck('keep'));
      await store.insertCards(<FcCard>[card('a', 'd1'), card('k', 'keep')]);
      await store.saveSettings('d1', const DeckSettings(newPerDay: 3));
      await store.insertLog(
          id: 'l', cardId: 'a', deckId: 'd1', rating: FsrsRating.good, at: t0, durationMs: 0);
      await store.deleteDeck('d1');
      expect(await store.deck('d1'), isNull);
      expect(await sql.select('SELECT id FROM flashcards'), hasLength(1));
      expect(await sql.select('SELECT card_id FROM fc_card_state'), hasLength(1));
      expect(await sql.select('SELECT * FROM fc_deck_settings'), isEmpty);
      expect(await sql.select('SELECT id FROM review_logs'), isEmpty);
    });
  });

  group('study queue', () {
    test('respects new/day, suspended and buried cards', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      await store.saveSettings('d', const DeckSettings(newPerDay: 2));
      await store.insertCards(<FcCard>[
        for (int i = 1; i <= 5; i++) card('n$i', 'd', createdMin: i),
      ]);
      Future<List<String>> newIds() async =>
          (await store.queue(deckId: 'd', now: t0)).newCards.map((FcCard c) => c.id).toList();
      expect(await newIds(), <String>['n1', 'n2']);
      await store.setFlag('n1', suspended: true);
      expect(await newIds(), <String>['n2', 'n3']);
      await store.setFlag('n2', buriedUntil: t0.add(const Duration(hours: 1)));
      expect(await newIds(), <String>['n3', 'n4']);
    });

    test('daily new limit counts cards first studied today', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      await store.saveSettings('d', const DeckSettings(newPerDay: 2));
      await store.insertCards(<FcCard>[
        for (int i = 1; i <= 3; i++) card('n$i', 'd', createdMin: i),
      ]);
      // n1 is answered today: it is logged and leaves the "new" state.
      await store.insertLog(
          id: 'l1', cardId: 'n1', deckId: 'd', rating: FsrsRating.good, at: t0, durationMs: 0);
      final FcCard n1 = (await store.card('n1'))!;
      await store.saveSchedule(n1.copyWith(
        fsrs: FsrsCard(
          state: FsrsState.learning, step: 1, stability: 1, difficulty: 5,
          due: t0.add(const Duration(days: 1)), lastReview: t0,
        ),
      ));
      StudyQueueData q = await store.queue(deckId: 'd', now: t0);
      // Limit is 2 new/day and one was introduced today: only one more.
      expect(q.newCards.map((FcCard c) => c.id).toList(), <String>['n2']);
      // A second new card is answered: the daily allowance is used up.
      await store.insertLog(
          id: 'l2', cardId: 'n2', deckId: 'd', rating: FsrsRating.good, at: t0, durationMs: 0);
      final FcCard n2 = (await store.card('n2'))!;
      await store.saveSchedule(n2.copyWith(
        fsrs: FsrsCard(
          state: FsrsState.learning, step: 1, stability: 1, difficulty: 5,
          due: t0.add(const Duration(days: 1)), lastReview: t0,
        ),
      ));
      q = await store.queue(deckId: 'd', now: t0);
      expect(q.newCards, isEmpty);
    });

    test('review cards: only due ones, limited by reviews/day', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      await store.insertCards(<FcCard>[
        card('r1', 'd', fsrs: reviewDue(const Duration(days: -2))),
        card('r2', 'd', fsrs: reviewDue(const Duration(days: -1))),
        card('r3', 'd', fsrs: reviewDue(const Duration(hours: -1))),
        card('future', 'd', fsrs: reviewDue(const Duration(days: 3))),
      ]);
      StudyQueueData q = await store.queue(deckId: 'd', now: t0);
      expect(q.review.map((FcCard c) => c.id).toSet(), <String>{'r1', 'r2', 'r3'});
      await store.saveSettings('d', const DeckSettings(reviewsPerDay: 2));
      q = await store.queue(deckId: 'd', now: t0);
      expect(q.review, hasLength(2));
    });

    test('learning cards: due or due within 20 minutes', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      FsrsCard learning(Duration d) => FsrsCard(
            state: FsrsState.learning, step: 0, stability: 1, difficulty: 5,
            due: t0.add(d), lastReview: t0,
          );
      await store.insertCards(<FcCard>[
        card('soon', 'd', fsrs: learning(const Duration(minutes: 10))),
        card('late', 'd', fsrs: learning(const Duration(minutes: 30))),
        card('now', 'd', fsrs: learning(const Duration(minutes: -1))),
      ]);
      final StudyQueueData q = await store.queue(deckId: 'd', now: t0);
      expect(q.learning.map((FcCard c) => c.id).toList(), <String>['now', 'soon']);
    });

    test('queue without a deck covers all non-archived decks', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('a'));
      await store.saveDeck(deck('b'));
      await store.insertCards(<FcCard>[card('x', 'a'), card('y', 'b')]);
      final StudyQueueData q = await store.queue(now: t0);
      expect(q.newCards, hasLength(2));
      await store.setArchived('b', true);
      expect((await store.queue(now: t0)).newCards, hasLength(1));
    });

    test('practice cards: starred / leeches / all, never suspended (except leeches)', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      await store.insertCards(<FcCard>[
        card('a', 'd', bookmarked: true),
        card('b', 'd'),
        card('c', 'd', suspended: true),
        card('l', 'd', lapses: 8, suspended: true),
      ]);
      Future<Set<String>> ids(StudyMode m) async =>
          (await store.practiceCards(deckId: 'd', mode: m)).map((FcCard c) => c.id).toSet();
      expect(await ids(StudyMode.cram), <String>{'a', 'b'});
      expect(await ids(StudyMode.starred), <String>{'a'});
      expect(await ids(StudyMode.leeches), <String>{'l'});
    });
  });

  group('counts & stats', () {
    test('deck summaries count new/learning/review and suspended', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      await store.insertCards(<FcCard>[
        card('n1', 'd'),
        card('n2', 'd'),
        card('s', 'd', suspended: true),
        card('r', 'd', fsrs: reviewDue(const Duration(days: -1))),
        card('f', 'd', fsrs: reviewDue(const Duration(days: 9))),
        card('l', 'd', fsrs: FsrsCard(
          state: FsrsState.relearning, step: 0, stability: 1, difficulty: 5,
          due: t0.add(const Duration(minutes: 5)), lastReview: t0,
        )),
      ]);
      final FcDeckSummary s = (await store.deckSummaries(t0)).single;
      expect(s.total, 6);
      expect(s.newCount, 2);
      expect(s.learningCount, 1);
      expect(s.reviewCount, 1);
      expect(s.suspendedCount, 1);
      expect(s.dueTotal, 4);
    });

    test('daily counts, studied days, retention, totals, activity', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      await store.insertCards(<FcCard>[card('A', 'd'), card('B', 'd')]);
      final DateTime yesterday = t0.subtract(const Duration(days: 1));
      Future<void> log(String id, String c, FsrsRating r, DateTime at, [int ms = 1000]) =>
          store.insertLog(id: id, cardId: c, deckId: 'd', rating: r, at: at, durationMs: ms);
      await log('1', 'A', FsrsRating.good, yesterday);
      await log('2', 'A', FsrsRating.again, t0);
      await log('3', 'B', FsrsRating.good, t0.add(const Duration(minutes: 1)));
      await log('4', 'B', FsrsRating.easy, t0.add(const Duration(minutes: 2)));

      final List<DayCount> days = await store.dailyCounts(studyDayKey(yesterday));
      expect(days.map((DayCount d) => d.day).toList(), <String>[studyDayKey(yesterday), today]);
      expect(days.first.total, 1);
      expect(days.last.total, 3);
      expect(days.last.good, 2);
      expect(await store.studiedDays(), <String>{studyDayKey(yesterday), today});

      // Reviews of already-seen cards today: A(again), B(easy). Passed: 1.
      final ({int total, int passed}) r = await store.retention(today);
      expect(r.total, 2);
      expect(r.passed, 1);

      final FcTotals t = await store.totals();
      expect((t.decks, t.cards, t.reviews, t.studyMs), (1, 2, 4, 4000));
      final List<FcActivity> act = await store.recentActivity(2);
      expect(act, hasLength(2));
      expect(act.first.rating, FsrsRating.easy);
      expect(act.first.deckName, 'Deck d');
    });

    test('state breakdown and review forecast dates', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      await store.insertCards(<FcCard>[
        card('n', 'd'),
        card('young', 'd', fsrs: reviewDue(const Duration(days: 2), s: 5)),
        card('mature', 'd', fsrs: reviewDue(const Duration(days: 40), s: 60)),
        card('s', 'd', suspended: true),
      ]);
      final StateBreakdown b = await store.stateBreakdown();
      expect((b.newCards, b.learning, b.young, b.mature, b.suspended), (1, 0, 1, 1, 1));
      final List<DateTime> due = await store.reviewDueDates(t0.add(const Duration(days: 30)));
      expect(due, hasLength(1));
    });
  });

  group('settings', () {
    test('defaults, save and load', () async {
      final (FcSql _, FlashcardStore store) = await fresh();
      await store.saveDeck(deck('d'));
      expect((await store.settingsFor('d')).newPerDay, 20);
      await store.saveSettings(
          'd',
          const DeckSettings(newPerDay: 7, reviewsPerDay: 99, desiredRetention: 0.85, shuffleNew: true));
      final DeckSettings s = await store.settingsFor('d');
      expect((s.newPerDay, s.reviewsPerDay, s.desiredRetention, s.shuffleNew), (7, 99, 0.85, true));
    });
  });

  group('backup', () {
    test('v2 dump → JSON → restore into a fresh database is lossless', () async {
      final (FcSql _, FlashcardStore a) = await fresh();
      await a.saveDeck(deck('d'));
      await a.saveSettings('d', const DeckSettings(newPerDay: 5));
      await a.insertCards(<FcCard>[
        card('x', 'd', tags: <String>['t1'], fsrs: reviewDue(const Duration(days: 2), s: 3.3)),
        card('y', 'd', front: '{{c1::z}}', type: FcCardType.cloze),
      ]);
      await a.insertLog(id: 'l', cardId: 'x', deckId: 'd', rating: FsrsRating.hard, at: t0, durationMs: 42);

      final Map<String, dynamic> json =
          jsonDecode(jsonEncode(encodeBackup(await a.dumpAll(), t0))) as Map<String, dynamic>;
      final BackupData parsed = decodeBackup(json);
      expect(parsed.version, 2);

      final (FcSql _, FlashcardStore b) = await fresh();
      await b.restoreAll(parsed);
      final BackupData again = await b.dumpAll();
      final BackupData orig = await a.dumpAll();
      expect(jsonEncode(again.decks), jsonEncode(orig.decks));
      expect(jsonEncode(again.logs), jsonEncode(orig.logs));
      expect(jsonEncode(again.settings), jsonEncode(orig.settings));
      expect(again.states.length, 2);
      final FcCard x = (await b.card('x'))!;
      expect(x.fsrs.stability, closeTo(3.3, 1e-9));
      expect((await b.card('y'))!.type, FcCardType.cloze);
    });

    test('v1 (old Drift JSON) backups restore and get FSRS state', () async {
      final int ms = t0.millisecondsSinceEpoch;
      final Map<String, dynamic> v1 = <String, dynamic>{
        'app': 'sapiora',
        'type': 'flashcards_backup',
        'version': 1,
        'decks': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'd', 'name': 'Old deck', 'description': null, 'subject': null,
            'topic': null, 'color': null, 'icon': null, 'archived': false,
            'createdAt': ms, 'updatedAt': ms,
          },
        ],
        'cards': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'c', 'deckId': 'd', 'front': 'Q', 'back': 'A', 'subject': null,
            'topic': null, 'tags': 'x,y', 'notes': null, 'difficulty': 0,
            'bookmarked': true, 'favorite': false, 'reviewState': 2,
            'dueAt': ms + 86400000 * 3, 'intervalDays': 7, 'easeFactor': 2.5,
            'repetitions': 3, 'lapses': 1, 'lastReviewedAt': ms - 86400000 * 4,
            'searchText': 'q a', 'createdAt': ms, 'updatedAt': ms,
          },
        ],
        'logs': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'l', 'cardId': 'c', 'deckId': 'd', 'rating': 2,
            'day': today, 'reviewedAt': ms, 'durationMs': 800,
          },
        ],
      };
      final BackupData parsed = decodeBackup(v1);
      expect(parsed.version, 1);
      expect(parsed.states, isEmpty);
      final (FcSql _, FlashcardStore s) = await fresh();
      await s.restoreAll(parsed);
      final FcCard c = (await s.card('c'))!;
      expect(c.state, FsrsState.review);
      expect(c.fsrs.stability, closeTo(7, 1e-9));
      expect(c.bookmarked, true);
      expect(c.tags, <String>['x', 'y']);
      expect(c.fsrs.due, DateTime.fromMillisecondsSinceEpoch(ms + 86400000 * 3));
      expect((await s.totals()).reviews, 1);
    });

    test('rejects files that are not flashcard backups', () {
      expect(() => decodeBackup(<String, dynamic>{'type': 'other'}),
          throwsA(isA<FormatException>()));
    });
  });

  group('cross-module reads (read-only)', () {
    test('import candidates and subject colours', () async {
      final (FcSql sql, FlashcardStore store) = await fresh();
      if (seedImportTables) {
        await sql.execute("INSERT INTO dictionary_entries (id, word, meaning) VALUES ('1', 'Apple', 'a fruit')");
        await sql.execute("INSERT INTO vocabulary_words (id, word, word_lower, english_meaning, urdu_meaning) VALUES ('1', 'Abate', 'abate', 'lessen', 'kam')");
        await sql.execute("INSERT INTO study_tasks (id, kind, title, subject, topic) VALUES ('1', 'session', 'T', 'Physics', 'Optics')");
        await sql.execute("INSERT INTO study_subjects (id, name, name_lower, color, archived) VALUES ('1', 'Physics', 'physics', 4278190335, 0)");
      }
      final List<ImportCandidate> dict = await store.importFromDictionary('', 10);
      final List<ImportCandidate> vocab = await store.importFromVocabulary('a', 10);
      final List<ImportCandidate> hub = await store.importFromStudyHub('', 10);
      final Map<String, int> colors = await store.subjectColors();
      if (seedImportTables) {
        expect(dict.single.front, 'Apple');
        expect(vocab.single.back, 'lessen — kam');
        expect((hub.single.front, hub.single.subject), ('Optics', 'Physics'));
        expect(colors['physics'], 4278190335);
      } else {
        expect(dict, isA<List<ImportCandidate>>());
        expect(colors, isA<Map<String, int>>());
      }
    });
  });
}

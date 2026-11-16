import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/flashcards/data/fc_repository_impl.dart';
import 'package:lexiora/modules/flashcards/data/fc_sql.dart';
import 'package:lexiora/modules/flashcards/data/flashcard_schema.dart';
import 'package:lexiora/modules/flashcards/data/flashcard_store.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/csv_codec.dart';
import 'package:lexiora/modules/flashcards/domain/logic/study_session.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_query.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_stats_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/fc_repository.dart';

/// Repository-level behaviour on a real database. See [defineStoreTests].
void defineRepositoryTests(Future<FcSql> Function() newSql) {
  DateTime now = DateTime(2026, 3, 10, 12);

  Future<(FcRepositoryImpl, FlashcardStore)> fresh() async {
    now = DateTime(2026, 3, 10, 12);
    final FcSql sql = await newSql();
    await FcSchema.ensure(sql);
    final FlashcardStore store = FlashcardStore(sql);
    return (FcRepositoryImpl(store, clock: () => now), store);
  }

  CardDraft basic(String f, String b) => CardDraft(front: f, back: b);

  group('addCards', () {
    test('basic, reversed twin, typed, and skipped rows', () async {
      final (FcRepositoryImpl repo, FlashcardStore store) = await fresh();
      final FcDeck d = await repo.createDeck(name: '  Words  ');
      expect(d.name, 'Words');
      final AddCardsResult r = await repo.addCards(
        d.id,
        <CardDraft>[
          basic('a', 'A'),
          const CardDraft(front: 'typed q', back: 'answer', type: FcCardType.typed),
          basic('', 'no front'),
          basic('no back', ''),
        ],
        reversed: true,
        subject: ' Bio ',
      );
      // a + a-reversed + typed (typed has no twin)
      expect(r.created, 3);
      expect(r.skipped, 2);
      final List<FcCard> all = await store.browse(const FcCardQuery(deckId: null), now);
      expect(all, hasLength(3));
      expect(all.every((FcCard c) => c.isNew && c.subject == 'Bio'), true);
      expect(all.where((FcCard c) => c.front == 'A' && c.back == 'a'), hasLength(1));
    });

    test('cloze: one card per deletion number, or a single card', () async {
      final (FcRepositoryImpl repo, FlashcardStore store) = await fresh();
      final FcDeck d = await repo.createDeck(name: 'C');
      const String text = 'The {{c1::heart}} pumps {{c2::blood}}';
      AddCardsResult r = await repo.addCards(
          d.id, <CardDraft>[const CardDraft(front: text, back: '', type: FcCardType.cloze)]);
      expect(r.created, 2);
      final List<FcCard> cards = await store.browse(FcCardQuery(deckId: d.id), now);
      expect(cards.map((FcCard c) => c.clozeIndex).toSet(), <int?>{1, 2});

      r = await repo.addCards(
          d.id,
          <CardDraft>[const CardDraft(front: text, back: '', type: FcCardType.cloze)],
          clozePerDeletion: false);
      expect(r.created, 1);
      final List<FcCard> single = await store.browse(FcCardQuery(deckId: d.id, limit: 100), now);
      expect(single.where((FcCard c) => c.clozeIndex == null), hasLength(1));

      r = await repo.addCards(
          d.id, <CardDraft>[const CardDraft(front: 'no markers', back: '', type: FcCardType.cloze)]);
      expect((r.created, r.skipped), (0, 1));
    });
  });

  group('studying', () {
    test('answer is persisted with a log row and can be undone', () async {
      final (FcRepositoryImpl repo, FlashcardStore store) = await fresh();
      final FcDeck d = await repo.createDeck(name: 'D');
      await repo.addCards(d.id, <CardDraft>[basic('q1', 'a1'), basic('q2', 'a2')]);
      final StudySession s = await repo.startSession(deckId: d.id);
      expect(s.counts.newCount, 2);
      expect(s.practice, false);

      final FcCard first = s.current!;
      final AnswerOutcome o = s.answer(FsrsRating.good, now);
      final String logId = await repo.recordAnswer(o, durationMs: 1234);

      final FcCard saved = (await repo.card(first.id))!;
      expect(saved.state, FsrsState.learning);
      expect(saved.reps, 1);
      expect((await store.totals()).reviews, 1);
      expect((await store.totals()).studyMs, 1234);

      final undone = s.undo(now)!;
      await repo.undoAnswer(undone.before, logId);
      final FcCard back = (await repo.card(first.id))!;
      expect(back.isNew, true);
      expect(back.reps, 0);
      expect((await store.totals()).reviews, 0);
    });

    test('a due review card is rescheduled to a later study day', () async {
      final (FcRepositoryImpl repo, FlashcardStore store) = await fresh();
      final FcDeck d = await repo.createDeck(name: 'D');
      await store.insertCards(<FcCard>[
        FcCard(
          id: 'r', deckId: d.id, front: 'q', back: 'a', createdAt: now, updatedAt: now, reps: 2,
          fsrs: FsrsCard(
            state: FsrsState.review, stability: 8, difficulty: 5,
            due: now.subtract(const Duration(days: 1)),
            lastReview: now.subtract(const Duration(days: 9)),
          ),
        ),
      ]);
      final StudySession s = await repo.startSession(deckId: d.id);
      expect(s.current!.id, 'r');
      await repo.recordAnswer(s.answer(FsrsRating.good, now), durationMs: 0);
      final FcCard r = (await repo.card('r'))!;
      expect(r.fsrs.due.isAfter(now), true);
      expect(r.fsrs.due.hour, 4);
      // not due any more
      expect((await repo.startSession(deckId: d.id)).isFinished, true);
    });

    test('8th lapse suspends the card and it leaves the queue', () async {
      final (FcRepositoryImpl repo, FlashcardStore store) = await fresh();
      final FcDeck d = await repo.createDeck(name: 'D');
      await store.insertCards(<FcCard>[
        FcCard(
          id: 'l', deckId: d.id, front: 'q', back: 'a', createdAt: now, updatedAt: now,
          reps: 20, lapses: 7,
          fsrs: FsrsCard(
            state: FsrsState.review, stability: 3, difficulty: 8,
            due: now.subtract(const Duration(days: 1)),
            lastReview: now.subtract(const Duration(days: 4)),
          ),
        ),
      ]);
      final StudySession s = await repo.startSession(deckId: d.id);
      final AnswerOutcome o = s.answer(FsrsRating.again, now);
      expect(o.becameLeech, true);
      await repo.recordAnswer(o, durationMs: 0);
      final FcCard l = (await repo.card('l'))!;
      expect(l.suspended, true);
      expect(l.isLeech, true);
      expect((await repo.startSession(deckId: d.id)).isFinished, true);
      // …but it can be practised.
      final StudySession p = await repo.startSession(deckId: d.id, mode: StudyMode.leeches);
      expect(p.current!.id, 'l');
    });

    test('buryUntilTomorrow hides a card until the next study day', () async {
      final (FcRepositoryImpl repo, FlashcardStore _) = await fresh();
      final FcDeck d = await repo.createDeck(name: 'D');
      await repo.addCards(d.id, <CardDraft>[basic('q', 'a')]);
      final String id = (await repo.browse(FcCardQuery(deckId: d.id))).single.id;
      await repo.buryUntilTomorrow(id);
      expect((await repo.startSession(deckId: d.id)).isFinished, true);
      now = DateTime(2026, 3, 11, 5); // after 04:00 next day
      expect((await repo.startSession(deckId: d.id)).isFinished, false);
    });

    test('practice mode includes cards that are not due and flags the session', () async {
      final (FcRepositoryImpl repo, FlashcardStore store) = await fresh();
      final FcDeck d = await repo.createDeck(name: 'D');
      await store.insertCards(<FcCard>[
        FcCard(
          id: 'f', deckId: d.id, front: 'q', back: 'a', createdAt: now, updatedAt: now,
          fsrs: FsrsCard(
            state: FsrsState.review, stability: 30, difficulty: 5,
            due: now.add(const Duration(days: 20)), lastReview: now,
          ),
        ),
      ]);
      expect((await repo.startSession(deckId: d.id)).isFinished, true);
      final StudySession p = await repo.startSession(deckId: d.id, mode: StudyMode.cram);
      expect(p.practice, true);
      expect(p.current!.id, 'f');
    });

    test('per-deck new-card limit applies to sessions', () async {
      final (FcRepositoryImpl repo, FlashcardStore _) = await fresh();
      final FcDeck d = await repo.createDeck(name: 'D');
      await repo.addCards(d.id, <CardDraft>[for (int i = 0; i < 6; i++) basic('q$i', 'a$i')]);
      await repo.saveDeckSettings(d.id, const DeckSettings(newPerDay: 3));
      expect((await repo.startSession(deckId: d.id)).counts.newCount, 3);
    });
  });

  group('settings & decks', () {
    test('settings are clamped to sane values', () async {
      final (FcRepositoryImpl repo, FlashcardStore _) = await fresh();
      final FcDeck d = await repo.createDeck(name: 'D');
      await repo.saveDeckSettings(
          d.id, const DeckSettings(newPerDay: -5, reviewsPerDay: 99999, desiredRetention: 0.5));
      final DeckSettings s = await repo.deckSettings(d.id);
      expect(s.newPerDay, 0);
      expect(s.reviewsPerDay, 9999);
      expect(s.desiredRetention, 0.7);
    });

    test('archive hides a deck from the default list', () async {
      final (FcRepositoryImpl repo, FlashcardStore _) = await fresh();
      final FcDeck a = await repo.createDeck(name: 'A');
      await repo.createDeck(name: 'B');
      await repo.setDeckArchived(a.id, true);
      expect((await repo.watchDecks().first).map((FcDeckSummary s) => s.deck.name).toList(), <String>['B']);
      expect((await repo.watchDecks(includeArchived: true).first), hasLength(2));
    });

    test('updateDeck and deleteDeck', () async {
      final (FcRepositoryImpl repo, FlashcardStore _) = await fresh();
      final FcDeck a = await repo.createDeck(name: 'A', description: '  ');
      expect(a.description, isNull);
      await repo.updateDeck(a.copyWith(name: 'Renamed'));
      expect((await repo.deck(a.id))!.name, 'Renamed');
      await repo.deleteDeck(a.id);
      expect(await repo.deck(a.id), isNull);
    });
  });

  group('dashboard & stats', () {
    test('dashboard counts and streak after a review', () async {
      final (FcRepositoryImpl repo, FlashcardStore _) = await fresh();
      final FcDeck d = await repo.createDeck(name: 'D');
      await repo.addCards(d.id, <CardDraft>[basic('q1', 'a1'), basic('q2', 'a2'), basic('q3', 'a3')]);
      FcDashboard dash = await repo.watchDashboard().first;
      expect(dash.counts.newCount, 3);
      expect((dash.totalCards, dash.totalDecks, dash.streak, dash.reviewsToday), (3, 1, 0, 0));

      final StudySession s = await repo.startSession(deckId: d.id);
      await repo.recordAnswer(s.answer(FsrsRating.easy, now), durationMs: 500);
      dash = await repo.watchDashboard().first;
      expect(dash.streak, 1);
      expect(dash.reviewsToday, 1);
      expect(dash.counts.newCount, 2);
    });

    test('stats snapshot', () async {
      final (FcRepositoryImpl repo, FlashcardStore _) = await fresh();
      final FcDeck d = await repo.createDeck(name: 'D');
      await repo.addCards(d.id, <CardDraft>[basic('q1', 'a1')]);
      final StudySession s = await repo.startSession(deckId: d.id);
      await repo.recordAnswer(s.answer(FsrsRating.good, now), durationMs: 700);
      final FcStats st = await repo.watchStats().first;
      expect(st.streak, 1);
      expect(st.longestStreak, 1);
      expect(st.reviewsToday, 1);
      expect(st.heatmap, hasLength(20));
      expect(st.forecast, hasLength(30));
      expect(st.breakdown.learning, 1);
      expect(st.totals.reviews, 1);
      expect(st.last30.single.total, 1);
      expect((await repo.watchRecentActivity().first).single.rating, FsrsRating.good);
    });
  });

  group('backup', () {
    test('export → import into another database keeps cards and schedule', () async {
      final (FcRepositoryImpl a, FlashcardStore _) = await fresh();
      final FcDeck d = await a.createDeck(name: 'D');
      await a.addCards(d.id, <CardDraft>[basic('q', 'a')]);
      final StudySession s = await a.startSession(deckId: d.id);
      await a.recordAnswer(s.answer(FsrsRating.good, now), durationMs: 1);
      final Map<String, dynamic> data = await a.exportBackup();

      final (FcRepositoryImpl b, FlashcardStore _) = await fresh();
      await b.importBackup(data);
      final List<FcCard> cards = await b.browse(const FcCardQuery());
      expect(cards.single.front, 'q');
      expect(cards.single.state, FsrsState.learning);
      expect((await b.watchStats().first).totals.reviews, 1);
    });
  });
}

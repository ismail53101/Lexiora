import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/study_session.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';

void main() {
  final DateTime t0 = DateTime(2026, 3, 10, 12);
  final FsrsScheduler sched = FsrsScheduler(const FsrsConfig(enableFuzzing: false));

  FcCard newCard(String id) => FcCard(
        id: id, deckId: 'd', front: 'f$id', back: 'b$id',
        createdAt: t0, updatedAt: t0, fsrs: FsrsCard.fresh(t0),
      );

  FcCard reviewCard(String id, {double s = 10}) => FcCard(
        id: id, deckId: 'd', front: 'f$id', back: 'b$id',
        createdAt: t0, updatedAt: t0, reps: 3,
        fsrs: FsrsCard(
          state: FsrsState.review, stability: s, difficulty: 5,
          due: t0.subtract(const Duration(days: 1)),
          lastReview: t0.subtract(const Duration(days: 11)),
        ),
      );

  FcCard learningCard(String id, Duration due) => FcCard(
        id: id, deckId: 'd', front: 'f$id', back: 'b$id',
        createdAt: t0, updatedAt: t0, reps: 1,
        fsrs: FsrsCard(
          state: FsrsState.learning, step: 0, stability: 1, difficulty: 5,
          due: t0.add(due), lastReview: t0,
        ),
      );

  StudySession make({
    List<FcCard> news = const <FcCard>[],
    List<FcCard> reviews = const <FcCard>[],
    List<FcCard> learning = const <FcCard>[],
    bool practice = false,
  }) =>
      StudySession(
        schedulerFor: (String _) => sched,
        newCards: news,
        reviewCards: reviews,
        learningCards: learning,
        now: t0,
        practice: practice,
        fuzz: false,
        random: Random(1),
      );

  group('ordering', () {
    test('empty session is finished', () {
      final StudySession s = make();
      expect(s.isFinished, true);
      expect(s.current, isNull);
      expect(s.progress, 1);
    });

    test('due learning first, then review/new interleaved, then early learning', () {
      final StudySession s = make(
        news: <FcCard>[newCard('n1'), newCard('n2')],
        reviews: <FcCard>[reviewCard('r1'), reviewCard('r2'), reviewCard('r3'), reviewCard('r4')],
        learning: <FcCard>[
          learningCard('lDue', const Duration(minutes: -1)),
          learningCard('lSoon', const Duration(minutes: 15)),
          learningCard('lLater', const Duration(minutes: 40)),
        ],
      );
      final List<String> order = <String>[];
      while (!s.isFinished) {
        final FcCard c = s.current!;
        order.add(c.id);
        // Answering "Easy" graduates every card so nothing re-enters.
        s.answer(FsrsRating.easy, t0);
      }
      expect(order.first, 'lDue');
      // new cards are spread among the reviews (not all first, not all last)
      final int firstNew = order.indexOf('n1');
      final int lastNew = order.indexOf('n2');
      expect(firstNew, lessThan(lastNew));
      expect(lastNew - firstNew, greaterThan(1));
      // "soon" is shown (learn-ahead) at the end; "later" is not shown.
      expect(order.last, 'lSoon');
      expect(order.contains('lLater'), false);
      expect(order, hasLength(8));
    });
  });

  group('answering', () {
    test('Good on a new card puts it into learning and it comes back', () {
      final StudySession s = make(news: <FcCard>[newCard('n')]);
      expect(s.counts.newCount, 1);
      final AnswerOutcome o = s.answer(FsrsRating.good, t0);
      expect(o.before.isNew, true);
      expect(o.after.state, FsrsState.learning);
      expect(o.after.reps, 1);
      expect(o.after.fsrs.due, t0.add(const Duration(minutes: 10)));
      // learn-ahead: shown again within the session
      expect(s.current!.id, 'n');
      expect(s.counts.learningCount, 1);
      // Good again graduates it
      final AnswerOutcome o2 = s.answer(FsrsRating.good, t0.add(const Duration(minutes: 10)));
      expect(o2.after.state, FsrsState.review);
      expect(s.isFinished, true);
    });

    test('Review cards are snapped to the start of their due day', () {
      final StudySession s = make(reviews: <FcCard>[reviewCard('r')]);
      final AnswerOutcome o = s.answer(FsrsRating.good, t0);
      expect(o.after.state, FsrsState.review);
      expect(o.after.fsrs.due.hour, 4);
      expect(o.after.fsrs.due.minute, 0);
      expect(o.after.fsrs.due.isAfter(t0), true);
      expect(s.isFinished, true);
    });

    test('Again on a review card is a lapse and enters relearning', () {
      final StudySession s = make(reviews: <FcCard>[reviewCard('r')]);
      final AnswerOutcome o = s.answer(FsrsRating.again, t0);
      expect(o.after.state, FsrsState.relearning);
      expect(o.after.lapses, 1);
      expect(o.becameLeech, false);
      expect(s.current!.id, 'r');
    });

    test('8th lapse suspends the card as a leech', () {
      final FcCard c = reviewCard('r').copyWith(lapses: 7);
      final StudySession s = make(reviews: <FcCard>[c]);
      final AnswerOutcome o = s.answer(FsrsRating.again, t0);
      expect(o.becameLeech, true);
      expect(o.after.suspended, true);
      expect(o.after.lapses, 8);
      expect(s.isFinished, true);
    });

    test('Again on a learning card is not a lapse', () {
      final StudySession s = make(learning: <FcCard>[learningCard('l', Duration.zero)]);
      final AnswerOutcome o = s.answer(FsrsRating.again, t0);
      expect(o.after.lapses, 0);
      expect(o.after.state, FsrsState.learning);
    });

    test('interval preview has four ascending-ish labels', () {
      final StudySession s = make(reviews: <FcCard>[reviewCard('r')]);
      final Map<FsrsRating, Duration> p = s.intervals(t0);
      expect(p.keys.toSet(), FsrsRating.values.toSet());
      expect(p[FsrsRating.again]!, lessThan(p[FsrsRating.good]!));
      expect(p[FsrsRating.good]!, lessThan(p[FsrsRating.easy]!));
    });

    test('progress grows as cards are answered', () {
      final StudySession s = make(reviews: <FcCard>[reviewCard('a'), reviewCard('b')]);
      expect(s.progress, 0);
      s.answer(FsrsRating.good, t0);
      expect(s.progress, 0.5);
      s.answer(FsrsRating.good, t0);
      expect(s.progress, 1);
      expect(s.answered, 2);
    });
  });

  group('undo', () {
    test('restores the previous card and counters', () {
      final StudySession s = make(reviews: <FcCard>[reviewCard('a'), reviewCard('b')]);
      final FcCard first = s.current!;
      s.answer(FsrsRating.good, t0);
      expect(s.current!.id, 'b');
      expect(s.canUndo, true);
      final undone = s.undo(t0)!;
      expect(undone.before.id, first.id);
      expect(s.current!.id, first.id);
      expect(s.answered, 0);
      expect(s.canUndo, false);
      // 'b' is back in the queue
      s.answer(FsrsRating.good, t0);
      expect(s.current!.id, 'b');
    });

    test('undoing an answer that moved the card to learning removes it from learning', () {
      final StudySession s = make(news: <FcCard>[newCard('n')]);
      s.answer(FsrsRating.again, t0);
      expect(s.counts.learningCount, 1);
      s.undo(t0);
      expect(s.current!.isNew, true);
      expect(s.counts.learningCount, 0);
      expect(s.counts.newCount, 1);
    });

    test('nothing to undo at the start', () {
      expect(make(news: <FcCard>[newCard('n')]).undo(t0), isNull);
    });
  });

  group('practice mode', () {
    test('never schedules; Again re-queues, others retire', () {
      final StudySession s = make(
        reviews: <FcCard>[reviewCard('a'), reviewCard('b'), reviewCard('c')],
        practice: true,
      );
      expect(s.intervals(t0), isEmpty);
      final AnswerOutcome o = s.answer(FsrsRating.again, t0);
      expect(identical(o.before, o.after), true);
      final List<String> seen = <String>[];
      while (!s.isFinished) {
        seen.add(s.current!.id);
        s.answer(FsrsRating.good, t0);
      }
      expect(seen.toSet(), <String>{'a', 'b', 'c'});
      expect(seen, hasLength(3));
    });

    test('undo of a practice Again removes the re-queued copy', () {
      final StudySession s = make(reviews: <FcCard>[reviewCard('a'), reviewCard('b')], practice: true);
      s.answer(FsrsRating.again, t0);
      s.undo(t0);
      final List<String> seen = <String>[];
      while (!s.isFinished) {
        seen.add(s.current!.id);
        s.answer(FsrsRating.good, t0);
      }
      expect(seen, <String>['a', 'b']);
    });
  });

  group('mid-session edits', () {
    test('removeCurrent skips to the next card', () {
      final StudySession s = make(reviews: <FcCard>[reviewCard('a'), reviewCard('b')]);
      s.removeCurrent(t0);
      expect(s.current!.id, 'b');
      s.removeCurrent(t0);
      expect(s.isFinished, true);
    });

    test('replaceCurrent swaps the edited card in', () {
      final StudySession s = make(reviews: <FcCard>[reviewCard('a')]);
      s.replaceCurrent(s.current!.copyWith(front: 'edited'));
      expect(s.current!.front, 'edited');
    });
  });

  group('per-deck schedulers', () {
    test('higher desired retention gives shorter intervals', () {
      FcCard inDeck(String deck) => reviewCard('x').copyWith(deckId: deck);
      final StudySession s = StudySession(
        schedulerFor: (String deck) => FsrsScheduler(FsrsConfig(
          enableFuzzing: false,
          desiredRetention: deck == 'strict' ? 0.97 : 0.8,
        )),
        newCards: const <FcCard>[],
        reviewCards: <FcCard>[inDeck('strict'), inDeck('relaxed')],
        now: t0,
        fuzz: false,
      );
      final Duration strict = s.intervals(t0)[FsrsRating.good]!;
      s.answer(FsrsRating.good, t0);
      final Duration relaxed = s.intervals(t0)[FsrsRating.good]!;
      expect(strict, lessThan(relaxed));
    });
  });
}

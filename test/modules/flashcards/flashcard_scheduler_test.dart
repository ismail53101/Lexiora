import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/domain/scheduler.dart';

/// The scheduler is a deliberately SIMPLE, SM-2-compatible placeholder. These
/// tests pin its behaviour so a future real SM-2 swap is a conscious change.
void main() {
  final DateTime now = DateTime(2026, 7, 26, 12);

  Flashcard base({
    ReviewState state = ReviewState.review,
    int interval = 0,
    double ease = 2.5,
    int reps = 0,
    int lapses = 0,
  }) =>
      Flashcard(
        id: 'x',
        deckId: 'd',
        front: 'f',
        back: 'b',
        createdAt: now,
        updatedAt: now,
        reviewState: state,
        intervalDays: interval,
        easeFactor: ease,
        repetitions: reps,
        lapses: lapses,
      );

  test('Again on a review card: back to learning, +10min, lapse++, ease-0.2',
      () {
    final SchedulerOutcome o =
        scheduleReview(base(interval: 10, reps: 3), CardRating.again, now);
    expect(o.reviewState, ReviewState.learning);
    expect(o.intervalDays, 0);
    expect(o.repetitions, 0);
    expect(o.lapses, 1);
    expect(o.easeFactor, closeTo(2.3, 1e-9));
    expect(o.dueAt, now.add(const Duration(minutes: 10)));
  });

  test('Again on a non-review card does not add a lapse', () {
    final SchedulerOutcome o =
        scheduleReview(base(state: ReviewState.learning), CardRating.again, now);
    expect(o.lapses, 0);
  });

  test('ease never drops below the 1.3 floor', () {
    final SchedulerOutcome o =
        scheduleReview(base(ease: 1.4), CardRating.again, now);
    expect(o.easeFactor, 1.3);
  });

  test('Hard: review state, interval grows ~1.2x (min 1), ease-0.15', () {
    expect(scheduleReview(base(), CardRating.hard, now).intervalDays, 1);
    final SchedulerOutcome o =
        scheduleReview(base(interval: 10), CardRating.hard, now);
    expect(o.reviewState, ReviewState.review);
    expect(o.intervalDays, 12);
    expect(o.easeFactor, closeTo(2.35, 1e-9));
    expect(o.repetitions, 1);
  });

  test('Good: first interval 1, then interval*ease', () {
    expect(scheduleReview(base(), CardRating.good, now).intervalDays, 1);
    final SchedulerOutcome o =
        scheduleReview(base(interval: 10), CardRating.good, now);
    expect(o.intervalDays, 25);
    expect(o.easeFactor, 2.5, reason: 'Good leaves ease unchanged');
    expect(o.repetitions, 1);
  });

  test('Easy: first interval 3, ease+0.15, then interval*ease*1.3', () {
    final SchedulerOutcome first = scheduleReview(base(), CardRating.easy, now);
    expect(first.intervalDays, 3);
    expect(first.easeFactor, closeTo(2.65, 1e-9));

    final SchedulerOutcome o =
        scheduleReview(base(interval: 10), CardRating.easy, now);
    expect(o.intervalDays, 34); // round(10 * 2.65 * 1.3)
  });
}

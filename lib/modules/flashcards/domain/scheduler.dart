import 'dart:math' as math;

import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';

/// The scheduling fields produced by a review.
class SchedulerOutcome {
  const SchedulerOutcome({
    required this.reviewState,
    required this.dueAt,
    required this.intervalDays,
    required this.easeFactor,
    required this.repetitions,
    required this.lapses,
  });

  final ReviewState reviewState;
  final DateTime dueAt;
  final int intervalDays;
  final double easeFactor;
  final int repetitions;
  final int lapses;
}

/// A deliberately SIMPLE placeholder scheduler — NOT the full SM-2 algorithm.
///
/// It writes to the same SM-2-compatible fields (ease factor, interval,
/// repetitions, lapses) so the real SM-2 can drop in later without any schema
/// or data changes. Pure and unit-testable.
SchedulerOutcome scheduleReview(
  Flashcard card,
  CardRating rating,
  DateTime now,
) {
  double ease = card.easeFactor;
  final int interval = card.intervalDays;
  int reps = card.repetitions;
  int lapses = card.lapses;

  switch (rating) {
    case CardRating.again:
      ease = math.max(1.3, ease - 0.2);
      reps = 0;
      if (card.reviewState == ReviewState.review) lapses += 1;
      return SchedulerOutcome(
        reviewState: ReviewState.learning,
        dueAt: now.add(const Duration(minutes: 10)),
        intervalDays: 0,
        easeFactor: ease,
        repetitions: reps,
        lapses: lapses,
      );
    case CardRating.hard:
      ease = math.max(1.3, ease - 0.15);
      final int next = interval <= 0 ? 1 : math.max(1, (interval * 1.2).round());
      return SchedulerOutcome(
        reviewState: ReviewState.review,
        dueAt: now.add(Duration(days: next)),
        intervalDays: next,
        easeFactor: ease,
        repetitions: reps + 1,
        lapses: lapses,
      );
    case CardRating.good:
      final int next = interval <= 0 ? 1 : math.max(1, (interval * ease).round());
      return SchedulerOutcome(
        reviewState: ReviewState.review,
        dueAt: now.add(Duration(days: next)),
        intervalDays: next,
        easeFactor: ease,
        repetitions: reps + 1,
        lapses: lapses,
      );
    case CardRating.easy:
      ease = ease + 0.15;
      final int next =
          interval <= 0 ? 3 : math.max(3, (interval * ease * 1.3).round());
      return SchedulerOutcome(
        reviewState: ReviewState.review,
        dueAt: now.add(Duration(days: next)),
        intervalDays: next,
        easeFactor: ease,
        repetitions: reps + 1,
        lapses: lapses,
      );
  }
}

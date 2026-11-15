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

/// SM-2-style scheduler used by every interactive practice mode.
///
/// New cards intentionally mirror the reference app's useful first-review
/// intervals: Again keeps the card in learning, Good starts a short review
/// interval, and Easy gives a substantially longer first interval. Existing
/// cards then grow according to ease and rating.
SchedulerOutcome scheduleReview(
  Flashcard card,
  CardRating rating,
  DateTime now,
) {
  double ease = card.easeFactor.clamp(1.3, 3.0).toDouble();
  int reps = card.repetitions;
  int lapses = card.lapses;
  final int interval = card.intervalDays;

  switch (rating) {
    case CardRating.again:
      ease = math.max(1.3, ease - 0.20);
      if (card.reviewState == ReviewState.review) lapses += 1;
      return SchedulerOutcome(
        reviewState: ReviewState.learning,
        dueAt: now.add(const Duration(minutes: 10)),
        intervalDays: 0,
        easeFactor: ease,
        repetitions: 0,
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
      ease = math.min(3.0, ease + 0.15);
      final int next = interval <= 0
          ? 3
          : math.max(3, (interval * ease * 1.3).round());
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

import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';

/// Converts the old placeholder (SM-2 style) scheduling columns into an
/// [FsrsCard], so nobody loses their progress when the engine is replaced.
///
/// * New cards stay new.
/// * Learning cards restart at the first learning step (they were minutes
///   from due anyway).
/// * Review cards keep their due date. FSRS "stability" is the interval at
///   which recall is 90 %, which is exactly what the old interval meant, so
///   stability = old interval. Difficulty is a heuristic from the old ease
///   factor: ease 2.5 (default) → 5 (average), 1.3 → 9 (hard), 3.7+ → 1.
FsrsCard legacyToFsrs({
  required int reviewState,
  required DateTime? dueAt,
  required int intervalDays,
  required double easeFactor,
  required DateTime? lastReviewedAt,
  required DateTime now,
}) {
  switch (reviewState) {
    case 0:
      return FsrsCard(due: now);
    case 1:
      return FsrsCard(
        state: FsrsState.learning,
        due: dueAt ?? now,
        lastReview: lastReviewedAt,
      );
    default:
      final int interval = intervalDays < 1 ? 1 : intervalDays;
      final double difficulty =
          (5.0 - (easeFactor - 2.5) * (4.0 / 1.2)).clamp(1.0, 10.0).toDouble();
      final DateTime due = dueAt ?? now;
      return FsrsCard(
        state: FsrsState.review,
        step: null,
        stability: interval.toDouble(),
        difficulty: difficulty,
        due: due,
        lastReview: lastReviewedAt ?? due.subtract(Duration(days: interval)),
      );
  }
}

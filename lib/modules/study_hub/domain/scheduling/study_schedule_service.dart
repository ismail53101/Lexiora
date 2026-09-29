import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';

/// A conflict between a manually positioned item and an earlier scheduled item.
class StudyScheduleConflict {
  const StudyScheduleConflict({required this.item, required this.previous});

  final StudyTask item;
  final StudyTask previous;
}

class StudyScheduleOverlapException implements Exception {
  const StudyScheduleOverlapException(this.conflict);

  final StudyScheduleConflict conflict;

  @override
  String toString() => 'Study schedule overlap: ${conflict.item.title} overlaps '
      'with ${conflict.previous.title}';
}

/// Pure scheduling rules for the Study Hub planner.
///
/// Times are integer minutes from midnight. Automatic rows move when an
/// earlier row changes; manual rows remain anchors. Breaks are ordinary timeline
/// rows and therefore participate in the same calculation.
class StudyScheduleService {
  const StudyScheduleService._();

  static const int defaultSessionMinutes = 60;
  static const int defaultBreakMinutes = 10;
  static const int minutesPerDay = 24 * 60;

  static int normalizeMinute(int value) => value % minutesPerDay;

  static int durationOf(StudyTask task) {
    final int? stored = task.durationMinutes;
    if (stored != null && stored > 0) return stored;
    final int? start = task.startMinute;
    final int? end = task.endMinute;
    if (start != null && end != null) {
      final int difference = end - start;
      if (difference > 0) return difference;
    }
    return task.isBreak ? defaultBreakMinutes : defaultSessionMinutes;
  }

  /// Returns the next available time after all scheduled rows for [day].
  static int nextAvailableMinute(Iterable<StudyTask> tasks, {String? excludeId}) {
    int cursor = 0;
    for (final StudyTask task in _ordered(tasks, excludeId: excludeId)) {
      final int? end = task.endMinute;
      if (end != null && end > cursor) cursor = end;
    }
    return cursor;
  }

  /// Recalculates all automatic rows while preserving manual start/end times.
  ///
  /// A session or break edited by the user can remain a manual anchor. Every
  /// later automatic row is placed at the end of the previous timeline item,
  /// which makes the persisted values and the rendered timeline agree.
  static List<StudyTask> recalculate(Iterable<StudyTask> input) {
    final List<StudyTask> rows = _ordered(input);
    final List<StudyTask> result = <StudyTask>[];
    int? cursorEnd;

    for (final StudyTask original in rows) {
      StudyTask current = original;
      if (current.autoScheduled) {
        final int start = cursorEnd ?? current.startMinute ?? 0;
        final int end = start + durationOf(current);
        current = current.copyWith(
          startMinute: start,
          endMinute: end,
          durationMinutes: durationOf(current),
        );
      }

      final int? end = current.endMinute;
      if (end != null) {
        cursorEnd = cursorEnd == null || end > cursorEnd ? end : cursorEnd;
      }
      result.add(current);
    }
    return result;
  }

  /// Finds manual rows that overlap the preceding timeline item.
  static List<StudyScheduleConflict> conflicts(Iterable<StudyTask> input) {
    final List<StudyTask> rows = _ordered(input);
    final List<StudyScheduleConflict> conflicts = <StudyScheduleConflict>[];
    StudyTask? previous;
    for (final StudyTask current in rows) {
      if (previous != null &&
          !current.autoScheduled &&
          previous.endMinute != null &&
          current.startMinute != null &&
          current.startMinute! < previous.endMinute!) {
        conflicts.add(StudyScheduleConflict(item: current, previous: previous));
      }
      if (current.endMinute != null) previous = current;
    }
    return conflicts;
  }

  static List<StudyTask> _ordered(
    Iterable<StudyTask> input, {
    String? excludeId,
  }) {
    final List<StudyTask> rows = input
        .where((StudyTask task) => excludeId == null || task.id != excludeId)
        .toList();
    rows.sort((StudyTask a, StudyTask b) {
      if (a.startMinute == null && b.startMinute != null) return 1;
      if (a.startMinute != null && b.startMinute == null) return -1;
      if (a.startMinute == null && b.startMinute == null) {
        return a.orderIndex.compareTo(b.orderIndex);
      }
      final int byStart = a.startMinute!.compareTo(b.startMinute!);
      if (byStart != 0) return byStart;
      final int byOrder = a.orderIndex.compareTo(b.orderIndex);
      if (byOrder != 0) return byOrder;
      return a.createdAt.compareTo(b.createdAt);
    });
    return rows;
  }
}

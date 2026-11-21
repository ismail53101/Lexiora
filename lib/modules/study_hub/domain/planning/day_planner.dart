/// "Plan my day": turns free time + what matters most into a list of focus
/// sessions and breaks. Plain arithmetic and rules — no AI, no I/O.
///
/// How it decides (so the result can always be explained):
///  1. Free time = your chosen window minus what is already planned.
///  2. Free time is cut into focus blocks with short breaks between them.
///  3. Every subject gets a weight from its exam date, how much syllabus is
///     left and how long since you last studied it ([subjectWeight]).
///  4. Blocks are shared out in proportion to the weights. The same subject
///     only runs twice in a row when it is behind by more than half a block.
///  5. Each block suggests the next unfinished syllabus topic of its subject.
library;

import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';

enum PlanItemKind { focus, rest }

/// A time range in minutes after midnight, `[start, end)`.
class MinuteRange {
  const MinuteRange(this.start, this.end);
  final int start;
  final int end;
  int get length => end - start;
}

/// A subject that may be planned, with its weight and next topics.
class PlanSubject {
  const PlanSubject({
    required this.name,
    required this.weight,
    this.topics = const <String>[],
    this.reason = '',
  });

  final String name;

  /// Relative importance; subjects with a weight <= 0 are ignored.
  final double weight;

  /// Unfinished syllabus topics, in order. One is suggested per block.
  final List<String> topics;

  /// Why this subject matters today, e.g. "Exam in 5 days".
  final String reason;
}

class PlanSettings {
  const PlanSettings({
    this.focusMinutes = 50,
    this.breakMinutes = 10,
    this.minBlockMinutes = 15,
  });

  final int focusMinutes;
  final int breakMinutes;

  /// Free gaps and leftovers shorter than this are not used.
  final int minBlockMinutes;
}

class PlannedItem {
  const PlannedItem({
    required this.kind,
    required this.start,
    required this.end,
    this.subject,
    this.topic,
    this.reason = '',
  });

  final PlanItemKind kind;
  final int start;
  final int end;
  final String? subject;
  final String? topic;
  final String reason;

  int get minutes => end - start;
  bool get isFocus => kind == PlanItemKind.focus;
}

class DayPlan {
  const DayPlan(this.items, this.freeMinutesLeft);

  final List<PlannedItem> items;

  /// Minutes of the window that were left unused (too short for a block).
  final int freeMinutesLeft;

  Iterable<PlannedItem> get blocks => items.where((PlannedItem i) => i.isFocus);
  int get focusMinutes => blocks.fold(0, (int s, PlannedItem i) => s + i.minutes);
  bool get isEmpty => items.isEmpty;

  /// Focus minutes per subject.
  Map<String, int> get minutesBySubject {
    final Map<String, int> out = <String, int>{};
    for (final PlannedItem i in blocks) {
      out[i.subject ?? ''] = (out[i.subject ?? ''] ?? 0) + i.minutes;
    }
    return out;
  }
}

/// How much a subject deserves today (higher = sooner / longer).
///
/// * base 1
/// * exam: up to +4, rising as the exam gets closer (nothing beyond 60 days)
/// * syllabus: up to +2, in proportion to the share of topics still to do
/// * neglect: up to +1.5 after two weeks without studying it; +1 if you have
///   never studied it
double subjectWeight({
  int? daysToExam,
  double? syllabusRemaining,
  int? daysSinceStudied,
}) {
  double w = 1;
  if (daysToExam != null && daysToExam >= 0) {
    final double urgency = 1 - daysToExam / 60.0;
    if (urgency > 0) w += 4 * urgency;
  }
  if (syllabusRemaining != null) {
    w += 2 * syllabusRemaining.clamp(0.0, 1.0);
  }
  if (daysSinceStudied == null) {
    w += 1;
  } else if (daysSinceStudied > 0) {
    w += 1.5 * (daysSinceStudied > 14 ? 14 : daysSinceStudied) / 14.0;
  }
  return w;
}

/// A short human explanation of [subjectWeight]'s inputs.
String explainSubject({
  int? daysToExam,
  int? topicsLeft,
  int? daysSinceStudied,
}) {
  final List<String> parts = <String>[];
  if (daysToExam != null && daysToExam >= 0 && daysToExam <= 60) {
    parts.add(daysToExam == 0
        ? 'Exam today'
        : daysToExam == 1
            ? 'Exam tomorrow'
            : 'Exam in $daysToExam days');
  }
  if (topicsLeft != null && topicsLeft > 0) {
    parts.add('$topicsLeft ${topicsLeft == 1 ? 'topic' : 'topics'} left');
  }
  if (daysSinceStudied == null) {
    parts.add('not studied yet');
  } else if (daysSinceStudied >= 3) {
    parts.add('not studied for $daysSinceStudied days');
  }
  return parts.join(' · ');
}

/// The parts of [window] that are not covered by [busy], longest-first
/// ordering is NOT applied: gaps are returned in time order.
List<MinuteRange> freeGaps(MinuteRange window, List<MinuteRange> busy) {
  final List<MinuteRange> clipped = <MinuteRange>[
    for (final MinuteRange b in busy)
      if (b.end > window.start && b.start < window.end && b.end > b.start)
        MinuteRange(
          b.start < window.start ? window.start : b.start,
          b.end > window.end ? window.end : b.end,
        ),
  ]..sort((MinuteRange a, MinuteRange b) => a.start.compareTo(b.start));

  final List<MinuteRange> gaps = <MinuteRange>[];
  int cursor = window.start;
  for (final MinuteRange b in clipped) {
    if (b.start > cursor) gaps.add(MinuteRange(cursor, b.start));
    if (b.end > cursor) cursor = b.end;
  }
  if (cursor < window.end) gaps.add(MinuteRange(cursor, window.end));
  return gaps;
}

/// Plans the day: see the library comment for the rules.
DayPlan planDay({
  required MinuteRange window,
  List<MinuteRange> busy = const <MinuteRange>[],
  required List<PlanSubject> subjects,
  PlanSettings settings = const PlanSettings(),
}) {
  assert(settings.focusMinutes > 0 && settings.breakMinutes >= 0);
  final List<MinuteRange> gaps = freeGaps(window, busy);
  final int windowFree = gaps.fold(0, (int s, MinuteRange g) => s + g.length);

  // 1. Cut every gap into focus blocks (and the breaks between them).
  final List<MinuteRange> slots = <MinuteRange>[];
  final List<MinuteRange> breaks = <MinuteRange>[];
  for (final MinuteRange gap in gaps) {
    int t = gap.start;
    while (gap.end - t >= settings.minBlockMinutes) {
      final int avail = gap.end - t;
      final int len = avail < settings.focusMinutes ? avail : settings.focusMinutes;
      slots.add(MinuteRange(t, t + len));
      t += len;
      if (gap.end - t >= settings.breakMinutes + settings.minBlockMinutes) {
        if (settings.breakMinutes > 0) {
          breaks.add(MinuteRange(t, t + settings.breakMinutes));
        }
        t += settings.breakMinutes;
      } else {
        break;
      }
    }
  }

  final List<PlanSubject> active =
      subjects.where((PlanSubject s) => s.weight > 0).toList();
  if (slots.isEmpty || active.isEmpty) return DayPlan(const <PlannedItem>[], windowFree);

  // 2. Share the blocks out in proportion to the weights.
  final int totalMinutes = slots.fold(0, (int s, MinuteRange r) => s + r.length);
  final double totalWeight = active.fold(0.0, (double s, PlanSubject p) => s + p.weight);
  final Map<String, double> target = <String, double>{
    for (final PlanSubject p in active) p.name: totalMinutes * p.weight / totalWeight,
  };
  final Map<String, double> given = <String, double>{for (final PlanSubject p in active) p.name: 0};
  final Map<String, int> topicIndex = <String, int>{for (final PlanSubject p in active) p.name: 0};

  final List<PlannedItem> focusItems = <PlannedItem>[];
  String? previous;

  // Larger deficit wins; ties go to the heavier subject, then the name.
  bool better(PlanSubject a, PlanSubject b) {
    final double da = target[a.name]! - given[a.name]!;
    final double db = target[b.name]! - given[b.name]!;
    if ((da - db).abs() > 1e-9) return da > db;
    if (a.weight != b.weight) return a.weight > b.weight;
    return a.name.compareTo(b.name) < 0;
  }

  for (final MinuteRange slot in slots) {
    PlanSubject? best;
    PlanSubject? bestOther;
    for (final PlanSubject p in active) {
      if (best == null || better(p, best)) best = p;
      if (p.name != previous && (bestOther == null || better(p, bestOther))) {
        bestOther = p;
      }
    }
    // Prefer a different subject from the last block, but let the same one
    // continue when it is behind by more than half a block.
    PlanSubject chosen = bestOther ?? best!;
    if (bestOther != null && best!.name == previous) {
      final double lead = (target[best.name]! - given[best.name]!) -
          (target[bestOther.name]! - given[bestOther.name]!);
      if (lead > slot.length * 0.5) chosen = best;
    }
    given[chosen.name] = given[chosen.name]! + slot.length;
    final int ti = topicIndex[chosen.name]!;
    String? topic;
    if (ti < chosen.topics.length) {
      topic = chosen.topics[ti];
      topicIndex[chosen.name] = ti + 1;
    }
    focusItems.add(PlannedItem(
      kind: PlanItemKind.focus,
      start: slot.start,
      end: slot.end,
      subject: chosen.name,
      topic: topic,
      reason: chosen.reason,
    ));
    previous = chosen.name;
  }

  // 3. Merge the breaks back in, in time order. A break is only kept when a
  // focus block follows it (it was only created in front of one).
  final List<PlannedItem> all = <PlannedItem>[
    ...focusItems,
    for (final MinuteRange b in breaks)
      PlannedItem(kind: PlanItemKind.rest, start: b.start, end: b.end),
  ]..sort((PlannedItem a, PlannedItem b) => a.start.compareTo(b.start));

  final int used = all.fold(0, (int s, PlannedItem i) => s + i.minutes);
  return DayPlan(all, windowFree - used);
}

/// Sessions that were planned but not done, to offer "move to tomorrow".
///
/// A session counts as missed when it is not completed and either its day is
/// before [today], or it is on [today] and its end time has already passed.
/// (Sessions without a time are only missed once their whole day is over.)
/// Breaks are never "missed".
List<StudyTask> findMissedSessions(
  Iterable<StudyTask> tasks, {
  required String today,
  required int nowMinute,
}) {
  final List<StudyTask> out = <StudyTask>[];
  for (final StudyTask t in tasks) {
    if (t.isBreak || t.completed) continue;
    if (t.day.compareTo(today) < 0) {
      out.add(t);
    } else if (t.day == today) {
      final int? end = t.endMinute;
      if (end != null && end <= nowMinute) out.add(t);
    }
  }
  return out..sort((StudyTask a, StudyTask b) {
    final int byDay = a.day.compareTo(b.day);
    return byDay != 0 ? byDay : (a.startMinute ?? 0).compareTo(b.startMinute ?? 0);
  });
}

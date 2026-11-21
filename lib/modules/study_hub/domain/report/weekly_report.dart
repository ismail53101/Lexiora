/// Weekly study report: how much you studied, on what, and how it compared
/// with your plan. Plain arithmetic and rules — no AI, no I/O.
library;

import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';

/// A timer log: time you actually tracked with the Pomodoro/manual timer.
class TimerLog {
  const TimerLog({
    required this.day,
    required this.minutes,
    this.subject,
    this.taskId,
    this.startMinuteOfDay,
  });

  final String day;
  final int minutes;
  final String? subject;

  /// The planned session this log belongs to, if any.
  final String? taskId;
  final int? startMinuteOfDay;
}

/// A planned study session (breaks excluded).
class TaskRow {
  const TaskRow({
    required this.id,
    required this.day,
    required this.subject,
    required this.plannedMinutes,
    required this.completed,
    this.startMinuteOfDay,
  });

  final String id;
  final String day;
  final String subject;
  final int plannedMinutes;
  final bool completed;
  final int? startMinuteOfDay;
}

/// Time studied, attributed to a day and subject.
class EffortRow {
  const EffortRow({
    required this.day,
    required this.subject,
    required this.minutes,
    this.startMinuteOfDay,
  });

  final String day;
  final String subject;
  final int minutes;
  final int? startMinuteOfDay;
}

const String otherSubject = 'Other';

/// Combines timer logs and completed sessions into one list without counting
/// anything twice: a completed session that has timer logs is represented by
/// those logs; a completed session without any is counted at its planned
/// length (so ticking a session "done" still counts as study time).
List<EffortRow> mergeEffort(List<TimerLog> logs, List<TaskRow> tasks) {
  final Map<String, TaskRow> byId = <String, TaskRow>{for (final TaskRow t in tasks) t.id: t};
  final Set<String> withLogs = <String>{
    for (final TimerLog l in logs)
      if (l.taskId != null && l.minutes > 0) l.taskId!,
  };
  final List<EffortRow> out = <EffortRow>[];
  for (final TimerLog l in logs) {
    if (l.minutes <= 0) continue;
    final String subject = _clean(l.subject) ?? _clean(byId[l.taskId]?.subject) ?? otherSubject;
    out.add(EffortRow(
      day: l.day,
      subject: subject,
      minutes: l.minutes,
      startMinuteOfDay: l.startMinuteOfDay ?? byId[l.taskId]?.startMinuteOfDay,
    ));
  }
  for (final TaskRow t in tasks) {
    if (!t.completed || withLogs.contains(t.id) || t.plannedMinutes <= 0) continue;
    out.add(EffortRow(
      day: t.day,
      subject: _clean(t.subject) ?? otherSubject,
      minutes: t.plannedMinutes,
      startMinuteOfDay: t.startMinuteOfDay,
    ));
  }
  return out;
}

String? _clean(String? s) {
  final String? t = s?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

enum DayPart {
  morning('Morning', '5 AM – 12 PM'),
  afternoon('Afternoon', '12 – 5 PM'),
  evening('Evening', '5 – 9 PM'),
  night('Night', '9 PM – 5 AM');

  const DayPart(this.label, this.range);
  final String label;
  final String range;

  static DayPart of(int minuteOfDay) {
    final int h = (minuteOfDay ~/ 60) % 24;
    if (h >= 5 && h < 12) return DayPart.morning;
    if (h >= 12 && h < 17) return DayPart.afternoon;
    if (h >= 17 && h < 21) return DayPart.evening;
    return DayPart.night;
  }
}

class DayStat {
  const DayStat({
    required this.day,
    required this.date,
    required this.minutes,
    required this.isToday,
    required this.isFuture,
  });

  final String day;
  final DateTime date;
  final int minutes;
  final bool isToday;
  final bool isFuture;
}

class SubjectShare {
  const SubjectShare(this.subject, this.minutes, this.percent);
  final String subject;
  final int minutes;

  /// Share of the week's study time, 0–100.
  final int percent;
}

enum InsightKind { trend, focus, exam, plan, habit, time }

class ReportInsight {
  const ReportInsight(this.kind, this.text, {this.positive});
  final InsightKind kind;
  final String text;

  /// True = good news, false = needs attention, null = neutral.
  final bool? positive;
}

String formatMinutes(int minutes) {
  final int m = minutes < 0 ? -minutes : minutes;
  if (m < 60) return '$m min';
  final int h = m ~/ 60;
  final int r = m % 60;
  return r == 0 ? '$h h' : '$h h $r min';
}

class WeeklyReport {
  const WeeklyReport({
    required this.weekStart,
    required this.days,
    required this.totalMinutes,
    required this.lastWeekMinutes,
    required this.subjects,
    required this.plannedSessions,
    required this.completedSessions,
    required this.plannedMinutes,
    required this.minutesByPart,
    required this.insights,
  });

  final DateTime weekStart;
  final List<DayStat> days;
  final int totalMinutes;
  final int lastWeekMinutes;
  final List<SubjectShare> subjects;
  final int plannedSessions;
  final int completedSessions;
  final int plannedMinutes;
  final Map<DayPart, int> minutesByPart;
  final List<ReportInsight> insights;

  DateTime get weekEnd => DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
  int get activeDays => days.where((DayStat d) => d.minutes > 0).length;
  int get deltaMinutes => totalMinutes - lastWeekMinutes;

  /// Change vs last week in percent; null when last week had nothing.
  int? get deltaPercent =>
      lastWeekMinutes == 0 ? null : (deltaMinutes * 100 / lastWeekMinutes).round();

  /// Completed / planned sessions in percent; null when nothing was planned.
  int? get completionPercent =>
      plannedSessions == 0 ? null : (completedSessions * 100 / plannedSessions).round();
  bool get isEmpty => totalMinutes == 0 && plannedSessions == 0;
  int get averagePerActiveDay => activeDays == 0 ? 0 : (totalMinutes / activeDays).round();

  /// The part of the day with the most study time, if there is enough data.
  DayPart? get bestPart {
    final int known = minutesByPart.values.fold(0, (int a, int b) => a + b);
    if (known < 30) return null;
    DayPart? best;
    for (final DayPart p in DayPart.values) {
      final int m = minutesByPart[p] ?? 0;
      if (m > 0 && (best == null || m > (minutesByPart[best] ?? 0))) best = p;
    }
    return best;
  }

  /// A plain-text summary for sharing (WhatsApp etc.).
  String toShareText() {
    final StringBuffer b = StringBuffer()
      ..writeln('My study week (${_d(weekStart)} – ${_d(weekEnd)})')
      ..writeln('Total: ${formatMinutes(totalMinutes)} · $activeDays/7 days');
    final int? dp = deltaPercent;
    if (dp != null && lastWeekMinutes > 0) {
      b.writeln('vs last week: ${deltaMinutes >= 0 ? '+' : '-'}${formatMinutes(deltaMinutes)} ($dp%)');
    }
    final int? cp = completionPercent;
    if (cp != null) b.writeln('Sessions: $completedSessions of $plannedSessions done ($cp%)');
    if (subjects.isNotEmpty) {
      b.writeln('By subject:');
      for (final SubjectShare s in subjects.take(6)) {
        b.writeln('• ${s.subject}: ${formatMinutes(s.minutes)} (${s.percent}%)');
      }
    }
    return b.toString().trimRight();
  }

  static const List<String> _mon = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static String _d(DateTime d) => '${d.day} ${_mon[d.month - 1]}';
}

/// The sessions that count towards "planned" in the report as of [today]:
/// everything on earlier days, plus today's sessions only once completed
/// (they may still be done tonight, so they are not "missed" yet), and
/// nothing from days that have not happened.
List<TaskRow> plannedForReport(List<TaskRow> tasks, String today) => <TaskRow>[
      for (final TaskRow t in tasks)
        if (t.day.compareTo(today) < 0 || (t.day == today && t.completed)) t,
    ];

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The Monday of the week that contains [d] (time of day removed).
DateTime mondayOf(DateTime d) {
  final DateTime day = DateTime(d.year, d.month, d.day);
  return DateTime(day.year, day.month, day.day - (day.weekday - 1));
}

/// Builds the report for the week starting [weekStart] (a Monday).
WeeklyReport buildWeeklyReport({
  required DateTime weekStart,
  required List<EffortRow> thisWeek,
  required List<EffortRow> lastWeek,
  required List<TaskRow> plannedThisWeek,
  List<ExamCountdown> exams = const <ExamCountdown>[],
  required DateTime now,
}) {
  final String today = _key(now);
  final Map<String, int> perDay = <String, int>{};
  final Map<String, int> perSubject = <String, int>{};
  final Map<String, String> displayName = <String, String>{};
  final Map<DayPart, int> parts = <DayPart, int>{};
  int total = 0;
  for (final EffortRow e in thisWeek) {
    perDay[e.day] = (perDay[e.day] ?? 0) + e.minutes;
    final String k = e.subject.toLowerCase();
    displayName.putIfAbsent(k, () => e.subject);
    perSubject[k] = (perSubject[k] ?? 0) + e.minutes;
    total += e.minutes;
    if (e.startMinuteOfDay != null) {
      final DayPart p = DayPart.of(e.startMinuteOfDay!);
      parts[p] = (parts[p] ?? 0) + e.minutes;
    }
  }
  final int lastTotal = lastWeek.fold(0, (int s, EffortRow e) => s + e.minutes);

  final List<DayStat> days = <DayStat>[
    for (int i = 0; i < 7; i++)
      () {
        final DateTime date = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
        final String k = _key(date);
        return DayStat(
          day: k,
          date: date,
          minutes: perDay[k] ?? 0,
          isToday: k == today,
          isFuture: k.compareTo(today) > 0,
        );
      }(),
  ];

  final List<SubjectShare> subjects = <SubjectShare>[
    for (final MapEntry<String, int> e in perSubject.entries)
      SubjectShare(displayName[e.key]!, e.value, total == 0 ? 0 : (e.value * 100 / total).round()),
  ]..sort((SubjectShare a, SubjectShare b) {
      final int byMin = b.minutes.compareTo(a.minutes);
      return byMin != 0 ? byMin : a.subject.compareTo(b.subject);
    });

  final int planned = plannedThisWeek.length;
  final int done = plannedThisWeek.where((TaskRow t) => t.completed).length;
  final int plannedMinutes = plannedThisWeek.fold(0, (int s, TaskRow t) => s + t.plannedMinutes);

  final WeeklyReport base = WeeklyReport(
    weekStart: weekStart,
    days: days,
    totalMinutes: total,
    lastWeekMinutes: lastTotal,
    subjects: subjects,
    plannedSessions: planned,
    completedSessions: done,
    plannedMinutes: plannedMinutes,
    minutesByPart: parts,
    insights: const <ReportInsight>[],
  );
  return WeeklyReport(
    weekStart: weekStart,
    days: days,
    totalMinutes: total,
    lastWeekMinutes: lastTotal,
    subjects: subjects,
    plannedSessions: planned,
    completedSessions: done,
    plannedMinutes: plannedMinutes,
    minutesByPart: parts,
    insights: _insights(base, perSubject, exams, now),
  );
}

List<ReportInsight> _insights(
  WeeklyReport r,
  Map<String, int> perSubject,
  List<ExamCountdown> exams,
  DateTime now,
) {
  final List<ReportInsight> out = <ReportInsight>[];

  // 1. Exams whose subject got (almost) no time this week.
  final bool weekHasStarted = !r.weekStart.isAfter(now);
  if (weekHasStarted) {
    for (final ExamCountdown c in exams) {
      if (!c.isUpcoming || c.daysLeft > 14) continue;
      final int minutes = perSubject[c.exam.subject.trim().toLowerCase()] ?? 0;
      if (minutes < 30) {
        final String when = c.daysLeft == 0
            ? 'today'
            : c.daysLeft == 1
                ? 'tomorrow'
                : 'in ${c.daysLeft} days';
        out.add(ReportInsight(
          InsightKind.exam,
          '${c.exam.subject} exam is $when, but you studied it only '
          '${minutes == 0 ? 'zero minutes' : formatMinutes(minutes)} this week.',
          positive: false,
        ));
      }
    }
  }

  // 2. Plan vs done.
  final int? cp = r.completionPercent;
  if (cp != null && r.plannedSessions >= 3) {
    if (cp >= 80) {
      out.add(ReportInsight(InsightKind.plan,
          'Great follow-through: ${r.completedSessions} of ${r.plannedSessions} planned sessions done.',
          positive: true));
    } else if (cp < 50) {
      out.add(ReportInsight(InsightKind.plan,
          'You finished ${r.completedSessions} of ${r.plannedSessions} planned sessions. '
          'Shorter blocks or "Plan my day" can make the plan easier to keep.',
          positive: false));
    }
  }

  // 3. Trend vs last week.
  final int? dp = r.deltaPercent;
  if (dp != null && r.totalMinutes > 0) {
    if (dp >= 10) {
      out.add(ReportInsight(InsightKind.trend,
          'Up $dp% on last week (${formatMinutes(r.deltaMinutes)} more).',
          positive: true));
    } else if (dp <= -10) {
      out.add(ReportInsight(InsightKind.trend,
          'Down ${-dp}% on last week (${formatMinutes(r.deltaMinutes)} less).',
          positive: false));
    } else {
      out.add(const ReportInsight(InsightKind.trend, 'About the same as last week.'));
    }
  }

  // 4. Where the time went.
  if (r.subjects.length >= 2 && r.subjects.first.percent >= 50) {
    out.add(ReportInsight(InsightKind.focus,
        '${r.subjects.first.percent}% of your time went to ${r.subjects.first.subject}.'));
  }

  // 5. Habit.
  if (r.activeDays >= 5) {
    out.add(ReportInsight(InsightKind.habit,
        'You studied on ${r.activeDays} of 7 days — a solid habit.',
        positive: true));
  }

  // 6. Best time of day.
  final DayPart? best = r.bestPart;
  if (best != null) {
    out.add(ReportInsight(InsightKind.time,
        'You study most in the ${best.label.toLowerCase()} (${best.range}).'));
  }

  return out.take(4).toList();
}

/// Exams and syllabus tracking for the Study Planner. Pure Dart: dates and
/// simple arithmetic only.
library;

/// An upcoming (or past) exam for one subject.
class StudyExam {
  const StudyExam({
    required this.id,
    required this.subject,
    required this.title,
    required this.day,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  final String id;
  final String subject;
  final String title;

  /// Exam date as `yyyy-MM-dd`.
  final String day;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The calendar date, or null when [day] is malformed.
  DateTime? get date {
    final List<String> p = day.split('-');
    if (p.length != 3) return null;
    final int? y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  StudyExam copyWith({
    String? subject,
    String? title,
    String? day,
    String? Function()? notes,
    DateTime? updatedAt,
  }) =>
      StudyExam(
        id: id,
        subject: subject ?? this.subject,
        title: title ?? this.title,
        day: day ?? this.day,
        notes: notes != null ? notes() : this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// One item of a subject's syllabus checklist.
class SyllabusTopic {
  const SyllabusTopic({
    required this.id,
    required this.subject,
    required this.title,
    required this.createdAt,
    this.done = false,
    this.sortOrder = 0,
    this.completedAt,
  });

  final String id;
  final String subject;
  final String title;
  final bool done;
  final int sortOrder;
  final DateTime? completedAt;
  final DateTime createdAt;
}

/// A subject's topics with progress.
class SubjectSyllabus {
  const SubjectSyllabus(this.subject, this.topics);

  final String subject;
  final List<SyllabusTopic> topics;

  int get total => topics.length;
  int get done => topics.where((SyllabusTopic t) => t.done).length;
  int get remaining => total - done;
  double get fraction => total == 0 ? 0 : done / total;
  int get percent => (fraction * 100).round();
}

/// How close an exam is.
enum ExamUrgency {
  passed,
  today,

  /// 1–3 days.
  critical,

  /// 4–7 days.
  soon,

  /// 8–30 days.
  near,
  far;

  static ExamUrgency forDaysLeft(int days) {
    if (days < 0) return ExamUrgency.passed;
    if (days == 0) return ExamUrgency.today;
    if (days <= 3) return ExamUrgency.critical;
    if (days <= 7) return ExamUrgency.soon;
    if (days <= 30) return ExamUrgency.near;
    return ExamUrgency.far;
  }
}

/// An exam together with what is left to do.
class ExamCountdown {
  const ExamCountdown({
    required this.exam,
    required this.daysLeft,
    required this.urgency,
    this.syllabus,
  });

  final StudyExam exam;

  /// Whole calendar days until the exam (negative once it has passed).
  final int daysLeft;
  final ExamUrgency urgency;
  final SubjectSyllabus? syllabus;

  bool get isUpcoming => daysLeft >= 0;

  /// Topics per day needed to finish the syllabus before the exam; null when
  /// there is no syllabus or the exam has passed.
  double? get topicsPerDay {
    final SubjectSyllabus? s = syllabus;
    if (s == null || s.total == 0 || !isUpcoming) return null;
    if (s.remaining == 0) return 0;
    return s.remaining / (daysLeft <= 0 ? 1 : daysLeft);
  }

  /// "3 days left", "Tomorrow", "Today", "Passed 2 days ago".
  String get label {
    if (daysLeft < -1) return 'Passed ${-daysLeft} days ago';
    if (daysLeft == -1) return 'Passed yesterday';
    if (daysLeft == 0) return 'Today';
    if (daysLeft == 1) return 'Tomorrow';
    return '$daysLeft days left';
  }

  /// A short pace hint such as "≈ 2 topics/day".
  String? get paceText {
    final double? p = topicsPerDay;
    if (p == null) return null;
    if (p == 0) return 'Syllabus complete';
    final String n = p >= 10 ? p.round().toString() : p.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return '≈ $n ${n == '1' ? 'topic' : 'topics'}/day to finish';
  }
}

int _daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// Whole days from [now]'s date to [examDay] (`yyyy-MM-dd`).
int daysUntil(DateTime now, String examDay) {
  final List<String> p = examDay.split('-');
  final DateTime? d = p.length == 3
      ? DateTime.tryParse('${p[0].padLeft(4, '0')}-${p[1].padLeft(2, '0')}-${p[2].padLeft(2, '0')}')
      : null;
  if (d == null) return 1 << 20;
  return _daysBetween(now, d);
}

/// Countdowns for [exams], soonest first; exams that have passed go last
/// (most recent first). Syllabus progress is matched by subject name,
/// ignoring case.
List<ExamCountdown> buildCountdowns(
  List<StudyExam> exams,
  Map<String, SubjectSyllabus> syllabusBySubjectLower,
  DateTime now,
) {
  final List<ExamCountdown> all = <ExamCountdown>[
    for (final StudyExam e in exams)
      ExamCountdown(
        exam: e,
        daysLeft: daysUntil(now, e.day),
        urgency: ExamUrgency.forDaysLeft(daysUntil(now, e.day)),
        syllabus: syllabusBySubjectLower[e.subject.trim().toLowerCase()],
      ),
  ];
  final List<ExamCountdown> upcoming =
      all.where((ExamCountdown c) => c.isUpcoming).toList()
        ..sort((ExamCountdown a, ExamCountdown b) => a.daysLeft.compareTo(b.daysLeft));
  final List<ExamCountdown> passed =
      all.where((ExamCountdown c) => !c.isUpcoming).toList()
        ..sort((ExamCountdown a, ExamCountdown b) => b.daysLeft.compareTo(a.daysLeft));
  return <ExamCountdown>[...upcoming, ...passed];
}

/// Splits pasted text (one topic per line, optional bullets/numbers) into
/// clean topic titles. Duplicates (ignoring case) are removed.
List<String> parseTopicLines(String text) {
  final Set<String> seen = <String>{};
  final List<String> out = <String>[];
  for (final String raw in text.split(RegExp(r'\r?\n'))) {
    final String t = raw
        .replaceFirst(RegExp(r'^\s*(?:[-*•·]+|\d+[.)])\s*'), '')
        .trim();
    if (t.isEmpty) continue;
    if (seen.add(t.toLowerCase())) out.add(t);
  }
  return out;
}

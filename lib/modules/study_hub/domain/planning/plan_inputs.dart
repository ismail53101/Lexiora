import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';
import 'package:lexiora/modules/study_hub/domain/planning/day_planner.dart';

/// A subject ready for the planner, plus whether it should be ticked by
/// default (relevant right now) in the "Plan my day" screen.
class PlanCandidate {
  const PlanCandidate({required this.subject, required this.suggested});
  final PlanSubject subject;
  final bool suggested;
}

int _daysBetweenKeys(String from, String to) {
  final DateTime? a = DateTime.tryParse(from);
  final DateTime? b = DateTime.tryParse(to);
  if (a == null || b == null) return 0;
  return DateTime.utc(b.year, b.month, b.day)
      .difference(DateTime.utc(a.year, a.month, a.day))
      .inDays;
}

/// Turns your subjects, exams, syllabus and study history into planner
/// input. Heaviest subject first.
///
/// A subject is "suggested" (ticked by default) when it has an exam within
/// 90 days, unfinished syllabus topics, or was studied in the last 14 days.
/// If nothing qualifies, every subject is suggested.
List<PlanCandidate> buildPlanCandidates({
  required Iterable<String> subjectNames,
  required List<ExamCountdown> countdowns,
  required List<SubjectSyllabus> syllabi,
  required Map<String, String> lastStudiedDay,
  required DateTime now,
}) {
  final String today =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final Map<String, SubjectSyllabus> syllabusByKey = <String, SubjectSyllabus>{
    for (final SubjectSyllabus s in syllabi) s.subject.trim().toLowerCase(): s,
  };

  final Set<String> seen = <String>{};
  final List<PlanCandidate> out = <PlanCandidate>[];
  for (final String raw in subjectNames) {
    final String name = raw.trim();
    final String key = name.toLowerCase();
    if (name.isEmpty || !seen.add(key)) continue;

    int? daysToExam;
    for (final ExamCountdown c in countdowns) {
      if (!c.isUpcoming || c.exam.subject.trim().toLowerCase() != key) continue;
      if (daysToExam == null || c.daysLeft < daysToExam) daysToExam = c.daysLeft;
    }
    final SubjectSyllabus? syl = syllabusByKey[key];
    final List<String> topics = <String>[
      if (syl != null)
        for (final SyllabusTopic t in syl.topics)
          if (!t.done) t.title,
    ];
    final String? last = lastStudiedDay[key];
    final int? sinceStudied = last == null ? null : _daysBetweenKeys(last, today);

    final double weight = subjectWeight(
      daysToExam: daysToExam,
      syllabusRemaining: (syl == null || syl.total == 0) ? null : syl.remaining / syl.total,
      daysSinceStudied: sinceStudied,
    );
    final bool relevant = (daysToExam != null && daysToExam <= 90) ||
        topics.isNotEmpty ||
        (sinceStudied != null && sinceStudied <= 14);
    out.add(PlanCandidate(
      subject: PlanSubject(
        name: name,
        weight: weight,
        topics: topics,
        reason: explainSubject(
          daysToExam: daysToExam,
          topicsLeft: topics.length,
          daysSinceStudied: sinceStudied,
        ),
      ),
      suggested: relevant,
    ));
  }

  out.sort((PlanCandidate a, PlanCandidate b) {
    final int byWeight = b.subject.weight.compareTo(a.subject.weight);
    return byWeight != 0 ? byWeight : a.subject.name.compareTo(b.subject.name);
  });
  if (out.isNotEmpty && !out.any((PlanCandidate c) => c.suggested)) {
    return <PlanCandidate>[
      for (final PlanCandidate c in out) PlanCandidate(subject: c.subject, suggested: true),
    ];
  }
  return out;
}

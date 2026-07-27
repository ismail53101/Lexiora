import 'package:lexiora/modules/study_hub/domain/entities/session_filter.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_goal.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_subject.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_template.dart';

/// Domain contract for the Study Hub. The presentation layer depends only on
/// this interface. All data is local; the implementation is structured so a
/// future Cloud Sync layer can be added without changing this contract.
abstract interface class StudyHubRepository {
  // ── Planner (sessions + breaks; used by Daily / Weekly / Monthly views) ──────
  Stream<List<StudyTask>> watchTasks(String day);

  /// Sessions/breaks across an inclusive day-key range (weekly & monthly views).
  Stream<List<StudyTask>> watchTasksInRange(String startDay, String endDay);

  Future<void> saveTask(StudyTask task); // insert or update (session or break)
  Future<void> deleteTask(String id);
  Future<void> setTaskCompleted(String id, {required bool completed});
  Future<void> setTaskStatus(String id, TaskStatus status);

  /// Distinct subjects / topics the user has entered before (for suggestions —
  /// nothing is hardcoded).
  Future<List<String>> subjectSuggestions();
  Future<List<String>> topicSuggestions();

  // ── Daily Goals ─────────────────────────────────────────────────────────────
  Stream<List<StudyGoal>> watchGoals(String day);
  Future<void> saveGoal(StudyGoal goal);
  Future<void> deleteGoal(String id);
  Future<void> incrementGoal(String id, int delta);

  // ── Sessions log (Pomodoro / manual timer) ──────────────────────────────────
  Future<void> addSession(StudySession session);
  Stream<int> watchStudyMinutes(String day);

  // ── Templates ───────────────────────────────────────────────────────────────
  Stream<List<StudyTemplate>> watchTemplates();
  Future<List<StudyTemplateItem>> templateItems(String templateId);
  Future<void> saveTemplateFromDay(String name, String day);
  Future<int> applyTemplateToDay(String templateId, String day);
  Future<void> deleteTemplate(String id);

  // ── Search & filter (v0.7.2) ────────────────────────────────────────────────
  /// Sessions matching [filter] (text over subject/topic/notes + status,
  /// priority, date scope, subject, topic). DB-backed, indexed, instant.
  Stream<List<StudyTask>> searchSessions(SessionFilter filter);

  // ── Subjects & colours (v0.7.2) ─────────────────────────────────────────────
  /// Colour-labelled subjects. [includeArchived] adds archived ones.
  Stream<List<StudySubject>> watchSubjects({bool includeArchived});

  /// Live map of subject nameLower → ARGB colour (used to tint the whole UI).
  Stream<Map<String, int>> watchSubjectColors();

  /// Every subject the user has (colour-labelled OR just used in a session),
  /// so "Manage Subjects" can colour uncoloured ones. Includes usage counts.
  Future<List<SubjectUsage>> allSubjectsWithUsage({bool includeArchived});

  Future<void> saveSubject(StudySubject subject); // add or update
  Future<void> setSubjectColor(String id, int color);
  Future<void> renameSubject(String id, String name);
  Future<void> setSubjectArchived(String id, bool archived);

  /// Removes the colour label only — study history is untouched.
  Future<void> deleteSubject(String id);

  // ── Recent / frequent (v0.7.2) ──────────────────────────────────────────────
  Future<List<String>> recentSubjects({int limit});
  Future<List<String>> frequentSubjects({int limit});
  Future<List<String>> recentTopics({int limit});

  // ── Backup & restore (v0.7.2; local now, cloud-ready) ───────────────────────
  Future<Map<String, dynamic>> exportBackup();
  Future<void> importBackup(Map<String, dynamic> data);

  // ── Streak & statistics ─────────────────────────────────────────────────────
  Stream<StudyStreak> watchStreak();
  Stream<StudyStats> watchStats(StudyRange range);
}

/// A subject plus how many sessions reference it (for Manage Subjects).
class SubjectUsage {
  const SubjectUsage({
    required this.name,
    required this.sessionCount,
    this.subject,
  });

  /// The colour-labelled subject, if one exists for this name.
  final StudySubject? subject;
  final String name;
  final int sessionCount;

  bool get hasColor => subject != null;
}

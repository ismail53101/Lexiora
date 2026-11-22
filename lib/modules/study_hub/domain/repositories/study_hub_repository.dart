import 'package:lexiora/modules/study_hub/domain/entities/session_filter.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_subject.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_template.dart';
import 'package:lexiora/modules/study_hub/domain/recurrence/repeat_series.dart';

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

  /// Splits [session] into Pomodoro-style focus blocks with [breakMinutes]
  /// breaks between them and saves everything in one atomic step.
  ///
  /// `session.durationMinutes` is the total FOCUS time. The blocks start at
  /// `session.startMinute` (manual) or right after the previous item of the
  /// day (when `session.autoScheduled`). Block ids derive from `session.id`,
  /// so saving again replaces the previous blocks instead of duplicating.
  /// Throws [StudyScheduleInvalidTimeException] / [StudyScheduleOverlapException]
  /// and saves nothing in that case. Returns every saved row in time order.
  Future<List<StudyTask>> saveSessionAsBlocks({
    required StudyTask session,
    required int focusMinutes,
    required int breakMinutes,
  });

  /// Saves the sessions and breaks of a generated day plan in one atomic step.
  /// Items keep their ids, so saving the same plan twice never duplicates.
  /// Throws [StudyScheduleInvalidTimeException] / [StudyScheduleOverlapException]
  /// and saves nothing in that case.
  Future<int> saveGeneratedPlan({
    required String day,
    required List<StudyTask> items,
  });

  /// The last day each subject was studied (lower-cased name → `yyyy-MM-dd`).
  Future<Map<String, String>> lastStudiedDays();

  /// Sessions from the last [lookbackDays] days (including [today]) that were
  /// not completed and whose time has passed.
  Future<List<StudyTask>> missedSessions({
    required String today,
    required int nowMinute,
    int lookbackDays = 7,
  });

  /// Moves [tasks] to [toDay] as automatic sessions placed after everything
  /// already planned there. Returns how many were moved.
  Future<int> moveSessionsToDay({
    required List<StudyTask> tasks,
    required String toDay,
  });

  /// Creates a weekly repeating session in one atomic step.
  ///
  /// [template] carries the subject/topic/notes/priority and the fixed time
  /// (`startMinute`/`endMinute`). One session (and, when [breakMinutes] > 0, one
  /// break) is created for every matching date from [startDay] to [untilDay].
  /// Dates where the time is already taken are skipped and reported, not
  /// treated as an error. Ids derive from [seriesId], so saving again with the
  /// same id never duplicates.
  Future<RepeatSaveResult> createRepeatingSessions({
    required String seriesId,
    required StudyTask template,
    required Set<int> weekdays,
    required String startDay,
    required String untilDay,
    int? breakMinutes,
  });

  /// All repeating series with their upcoming occurrences, from [today].
  Stream<List<RepeatSeries>> watchSeries({required String today});

  /// Adds [weeks] more weeks of occurrences after the series' last day (or
  /// from [today] when it has already finished).
  Future<RepeatSaveResult> extendSeries({
    required String seriesId,
    required int weeks,
    required String today,
  });

  /// Ends a series: deletes its sessions (and breaks) from [fromDay] onwards
  /// that are not completed. Earlier and completed ones stay. Returns how many
  /// sessions were removed.
  Future<int> endSeries({required String seriesId, required String fromDay});

  /// Saves a session AND the break attached to its end in one atomic step.
  ///
  /// [breakMinutes] null (or 0) means "no break": a previously linked break
  /// with [breakId] is removed. Throws [StudyScheduleInvalidTimeException] or
  /// [StudyScheduleOverlapException] — in which case NOTHING is saved.
  /// Saving again with the same ids updates the same rows (never duplicates).
  /// Returns the session as stored (with its final start/end).
  Future<StudyTask> saveSessionWithBreak({
    required StudyTask session,
    required String breakId,
    int? breakMinutes,
  });
  Future<void> setTaskCompleted(String id, {required bool completed});
  Future<void> setTaskStatus(String id, TaskStatus status);

  /// Distinct subjects / topics the user has entered before (for suggestions —
  /// nothing is hardcoded).
  Future<List<String>> subjectSuggestions();
  Future<List<String>> topicSuggestions();


  // ── Sessions log (Pomodoro / manual timer / planned task timer) ─────────────
  /// Persists only completed, positive-duration study sessions. Implementations
  /// must keep writes idempotent by session id.
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

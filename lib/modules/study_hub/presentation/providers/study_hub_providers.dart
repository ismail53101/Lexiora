import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/modules/study_hub/data/services/study_backup_service.dart';
import 'package:lexiora/modules/study_hub/data/services/study_export_service.dart';
import 'package:lexiora/modules/study_hub/domain/entities/session_filter.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_subject.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_template.dart';
import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';
import 'package:lexiora/modules/study_hub/domain/recurrence/repeat_series.dart';
import 'package:lexiora/modules/study_hub/domain/report/weekly_report.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/exam_repository.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/report_repository.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/study_hub_repository.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';

final Provider<StudyHubRepository> studyHubRepositoryProvider =
    Provider<StudyHubRepository>((Ref ref) => sl<StudyHubRepository>());

/// Today's day-key (computed once per app run).
final Provider<String> studyTodayProvider =
    Provider<String>((Ref ref) => todayKey());

final StreamProvider<List<StudyTask>> studyTasksProvider =
    StreamProvider<List<StudyTask>>((Ref ref) => ref
        .watch(studyHubRepositoryProvider)
        .watchTasks(ref.watch(studyTodayProvider)));

final StreamProvider<int> studyMinutesTodayProvider =
    StreamProvider<int>((Ref ref) => ref
        .watch(studyHubRepositoryProvider)
        .watchStudyMinutes(ref.watch(studyTodayProvider)));

/// Context carried from a planned task into the existing Pomodoro/manual timer.
/// It is not a second log: completed timers still write only to study_sessions.
class ActiveStudyContext {
  const ActiveStudyContext({this.taskId, this.subject, this.durationMinutes});
  final String? taskId;
  final String? subject;
  final int? durationMinutes;
  static const empty = ActiveStudyContext();
}

class ActiveStudyContextNotifier extends Notifier<ActiveStudyContext> {
  @override
  ActiveStudyContext build() => ActiveStudyContext.empty;
  void setTask(StudyTask task) {
    final int? duration = task.durationMinutes ??
        (task.startMinute != null && task.endMinute != null
            ? task.endMinute! - task.startMinute!
            : null);
    state = ActiveStudyContext(
      taskId: task.id,
      subject: task.displaySubject,
      durationMinutes: duration != null && duration > 0 ? duration : null,
    );
  }
  void clear() => state = ActiveStudyContext.empty;
}

final NotifierProvider<ActiveStudyContextNotifier, ActiveStudyContext>
    activeStudyContextProvider =
    NotifierProvider<ActiveStudyContextNotifier, ActiveStudyContext>(
        ActiveStudyContextNotifier.new);

final StreamProvider<StudyStreak> studyStreakProvider =
    StreamProvider<StudyStreak>(
        (Ref ref) => ref.watch(studyHubRepositoryProvider).watchStreak());

final studyStatsProvider =
    StreamProvider.family<StudyStats, StudyRange>((Ref ref, StudyRange range) =>
        ref.watch(studyHubRepositoryProvider).watchStats(range));

/// Study-time breakdown for the last seven days plus rolling weekly/monthly
/// totals. Every value comes from the same persisted study_sessions log used
/// by the timer, including partially completed sessions.
final StreamProvider<StudyStatistics> studyStatisticsProvider =
    StreamProvider<StudyStatistics>((Ref ref) {
  final StudyHubRepository repo = ref.watch(studyHubRepositoryProvider);
  final DateTime today = DateTime.now();
  final List<String> days = <String>[
    for (int offset = 6; offset >= 0; offset--)
      dayKey(today.subtract(Duration(days: offset))),
  ];
  return Stream<StudyStatistics>.multi(
    (MultiStreamController<StudyStatistics> out) {
      final List<int?> daily = List<int?>.filled(days.length, null);
      int? weekly;
      int? monthly;
      void emit() {
        if (weekly == null || monthly == null || daily.any((int? v) => v == null)) {
          return;
        }
        out.add(StudyStatistics(
          days: daily.cast<int>(),
          weeklyMinutes: weekly!,
          monthlyMinutes: monthly!,
        ));
      }
      final List<StreamSubscription<int>> dailySubs = <StreamSubscription<int>>[
        for (int i = 0; i < days.length; i++)
          repo.watchStudyMinutes(days[i]).listen((int value) {
            daily[i] = value;
            emit();
          }),
      ];
      final StreamSubscription<StudyStats> weeklySub =
          repo.watchStats(StudyRange.weekly).listen((StudyStats value) {
        weekly = value.studyMinutes;
        emit();
      });
      final StreamSubscription<StudyStats> monthlySub =
          repo.watchStats(StudyRange.monthly).listen((StudyStats value) {
        monthly = value.studyMinutes;
        emit();
      });
      out.onCancel = () async {
        await Future.wait(<Future<void>>[
          for (final StreamSubscription<int> sub in dailySubs) sub.cancel(),
          weeklySub.cancel(),
          monthlySub.cancel(),
        ]);
      };
    },
  );
});

/// Sessions/breaks for an arbitrary day (Weekly/Monthly planners).
final studyDayTasksProvider =
    StreamProvider.family<List<StudyTask>, String>((Ref ref, String day) =>
        ref.watch(studyHubRepositoryProvider).watchTasks(day));

/// Sessions/breaks across an inclusive day range (start|end joined by '|').
final studyRangeTasksProvider =
    StreamProvider.family<List<StudyTask>, String>((Ref ref, String range) {
  final List<String> parts = range.split('|');
  return ref
      .watch(studyHubRepositoryProvider)
      .watchTasksInRange(parts.first, parts.last);
});

final StreamProvider<List<StudyTemplate>> studyTemplatesProvider =
    StreamProvider<List<StudyTemplate>>(
        (Ref ref) => ref.watch(studyHubRepositoryProvider).watchTemplates());

final subjectSuggestionsProvider =
    FutureProvider.autoDispose<List<String>>((Ref ref) =>
        ref.watch(studyHubRepositoryProvider).subjectSuggestions());

final topicSuggestionsProvider =
    FutureProvider.autoDispose<List<String>>((Ref ref) =>
        ref.watch(studyHubRepositoryProvider).topicSuggestions());

// ── v0.7.2: colours, search, subjects, recent/frequent, services ────────────

/// Live map of subject nameLower → ARGB colour; tints the whole Study Hub UI.
final StreamProvider<Map<String, int>> subjectColorsProvider =
    StreamProvider<Map<String, int>>(
        (Ref ref) => ref.watch(studyHubRepositoryProvider).watchSubjectColors());

/// Colour-labelled subjects (family arg = includeArchived).
final subjectsProvider =
    StreamProvider.family<List<StudySubject>, bool>((Ref ref, bool archived) =>
        ref.watch(studyHubRepositoryProvider).watchSubjects(includeArchived: archived));

/// All subjects (colour-labelled or session-derived) with usage — Manage page.
final subjectUsageProvider =
    FutureProvider.autoDispose.family<List<SubjectUsage>, bool>(
        (Ref ref, bool archived) {
  ref.watch(subjectsProvider(true)); // refresh when colours change
  return ref
      .watch(studyHubRepositoryProvider)
      .allSubjectsWithUsage(includeArchived: archived);
});

/// The current session-search filter.
class SessionFilterNotifier extends Notifier<SessionFilter> {
  @override
  SessionFilter build() => const SessionFilter();
  void set(SessionFilter f) => state = f;
  void setQuery(String q) => state = state.copyWith(query: q);
  void reset() => state = const SessionFilter();
}

final NotifierProvider<SessionFilterNotifier, SessionFilter>
    sessionFilterProvider =
    NotifierProvider<SessionFilterNotifier, SessionFilter>(
        SessionFilterNotifier.new);

final StreamProvider<List<StudyTask>> searchResultsProvider =
    StreamProvider<List<StudyTask>>((Ref ref) => ref
        .watch(studyHubRepositoryProvider)
        .searchSessions(ref.watch(sessionFilterProvider)));

final recentSubjectsProvider = FutureProvider.autoDispose<List<String>>(
    (Ref ref) => ref.watch(studyHubRepositoryProvider).recentSubjects());
final frequentSubjectsProvider = FutureProvider.autoDispose<List<String>>(
    (Ref ref) => ref.watch(studyHubRepositoryProvider).frequentSubjects());
final recentTopicsProvider = FutureProvider.autoDispose<List<String>>(
    (Ref ref) => ref.watch(studyHubRepositoryProvider).recentTopics());

final Provider<StudyExportService> studyExportServiceProvider =
    Provider<StudyExportService>((Ref ref) => const StudyExportService());

final Provider<StudyBackupService> studyBackupServiceProvider =
    Provider<StudyBackupService>(
        (Ref ref) => StudyBackupService(ref.watch(studyExportServiceProvider)));

// ── Exams & syllabus ─────────────────────────────────────────────────────────

final Provider<ExamRepository> examRepositoryProvider =
    Provider<ExamRepository>((Ref ref) => sl<ExamRepository>());

/// Exams with days left and syllabus progress, soonest first.
final StreamProvider<List<ExamCountdown>> examCountdownsProvider =
    StreamProvider<List<ExamCountdown>>(
        (Ref ref) => ref.watch(examRepositoryProvider).watchCountdowns());

final StreamProvider<List<SubjectSyllabus>> syllabiProvider =
    StreamProvider<List<SubjectSyllabus>>(
        (Ref ref) => ref.watch(examRepositoryProvider).watchSyllabi());

// ── Plan my day & missed sessions ────────────────────────────────────────────

/// The last day each subject was studied (lower-cased name → `yyyy-MM-dd`).
final FutureProvider<Map<String, String>> lastStudiedDaysProvider =
    FutureProvider.autoDispose<Map<String, String>>(
        (Ref ref) => ref.watch(studyHubRepositoryProvider).lastStudiedDays());

/// Unfinished sessions from the last week whose time has passed. Refreshes
/// whenever today's tasks change.
final FutureProvider<List<StudyTask>> missedSessionsProvider =
    FutureProvider.autoDispose<List<StudyTask>>((Ref ref) {
  ref.watch(studyDayTasksProvider(todayKey()));
  final DateTime now = DateTime.now();
  return ref.watch(studyHubRepositoryProvider).missedSessions(
        today: dayKey(now),
        nowMinute: now.hour * 60 + now.minute,
      );
});

// ── Weekly report ────────────────────────────────────────────────────────────

final Provider<ReportRepository> reportRepositoryProvider =
    Provider<ReportRepository>((Ref ref) => sl<ReportRepository>());

String _keyOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The report for the week starting on the Monday [weekStartKey]
/// (`yyyy-MM-dd`). Refreshes when exams or today's tasks change.
final weeklyReportProvider =
    FutureProvider.autoDispose.family<WeeklyReport, String>((Ref ref, String weekStartKey) async {
  ref.watch(studyDayTasksProvider(todayKey()));
  final List<ExamCountdown> exams =
      ref.watch(examCountdownsProvider).asData?.value ?? const <ExamCountdown>[];
  final DateTime weekStart = DateTime.parse(weekStartKey);
  final DateTime prevStart = DateTime(weekStart.year, weekStart.month, weekStart.day - 7);
  final DateTime weekEnd = DateTime(weekStart.year, weekStart.month, weekStart.day + 6);

  final ReportSource src = await ref.watch(reportRepositoryProvider).load(
        startDay: _keyOf(prevStart),
        endDay: _keyOf(weekEnd),
      );
  bool inThisWeek(String day) => day.compareTo(weekStartKey) >= 0;

  final List<TaskRow> tasksThis = src.tasks.where((TaskRow t) => inThisWeek(t.day)).toList();
  final List<TaskRow> tasksLast = src.tasks.where((TaskRow t) => !inThisWeek(t.day)).toList();
  final List<TimerLog> logsThis = src.logs.where((TimerLog l) => inThisWeek(l.day)).toList();
  final List<TimerLog> logsLast = src.logs.where((TimerLog l) => !inThisWeek(l.day)).toList();

  final DateTime now = DateTime.now();
  return buildWeeklyReport(
    weekStart: weekStart,
    thisWeek: mergeEffort(logsThis, tasksThis),
    lastWeek: mergeEffort(logsLast, tasksLast),
    plannedThisWeek: plannedForReport(tasksThis, _keyOf(now)),
    exams: exams,
    now: now,
  );
});

// ── Repeating sessions ───────────────────────────────────────────────────────

/// Weekly repeating series with their upcoming sessions.
final StreamProvider<List<RepeatSeries>> repeatSeriesProvider =
    StreamProvider.autoDispose<List<RepeatSeries>>((Ref ref) =>
        ref.watch(studyHubRepositoryProvider).watchSeries(today: todayKey()));

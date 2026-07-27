import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/modules/study_hub/data/services/study_backup_service.dart';
import 'package:lexiora/modules/study_hub/data/services/study_export_service.dart';
import 'package:lexiora/modules/study_hub/domain/entities/session_filter.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_goal.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_subject.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_template.dart';
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

final StreamProvider<List<StudyGoal>> studyGoalsProvider =
    StreamProvider<List<StudyGoal>>((Ref ref) => ref
        .watch(studyHubRepositoryProvider)
        .watchGoals(ref.watch(studyTodayProvider)));

final StreamProvider<int> studyMinutesTodayProvider =
    StreamProvider<int>((Ref ref) => ref
        .watch(studyHubRepositoryProvider)
        .watchStudyMinutes(ref.watch(studyTodayProvider)));

final StreamProvider<StudyStreak> studyStreakProvider =
    StreamProvider<StudyStreak>(
        (Ref ref) => ref.watch(studyHubRepositoryProvider).watchStreak());

final studyStatsProvider =
    StreamProvider.family<StudyStats, StudyRange>((Ref ref, StudyRange range) =>
        ref.watch(studyHubRepositoryProvider).watchStats(range));

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

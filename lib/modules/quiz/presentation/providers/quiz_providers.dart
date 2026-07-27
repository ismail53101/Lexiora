import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/modules/quiz/data/providers/content_providers.dart';
import 'package:lexiora/modules/quiz/data/quiz_seeder.dart';
import 'package:lexiora/modules/quiz/data/services/quiz_export_service.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_bank.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_settings.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_subject.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_topic.dart';
import 'package:lexiora/modules/quiz/domain/repositories/question_provider.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_admin_repository.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_repository.dart';

final Provider<QuizRepository> quizRepositoryProvider =
    Provider<QuizRepository>((Ref ref) => sl<QuizRepository>());

final Provider<QuizAdminRepository> quizAdminRepositoryProvider =
    Provider<QuizAdminRepository>((Ref ref) => sl<QuizAdminRepository>());

final Provider<QuizSeeder> quizSeederProvider =
    Provider<QuizSeeder>((Ref ref) => sl<QuizSeeder>());

/// Kicks off (idempotent) demo seeding; best-effort so a failure never blocks UI.
final FutureProvider<void> quizSeedProvider = FutureProvider<void>((Ref ref) async {
  try {
    await ref.watch(quizSeederProvider).ensureSeeded();
  } on Object {
    // Demo simply won't be present this run.
  }
});

// ── Subject-first hierarchy (v0.9.1) ─────────────────────────────────────────

final quizSubjectsProvider =
    StreamProvider.family<List<QuizSubjectSummary>, bool>(
        (Ref ref, bool archived) {
  ref.watch(quizSeedProvider);
  return ref.watch(quizRepositoryProvider).watchSubjects(includeArchived: archived);
});

final quizTopicsProvider =
    StreamProvider.family<List<QuizTopicSummary>, String>(
        (Ref ref, String subjectId) =>
            ref.watch(quizRepositoryProvider).watchTopics(subjectId));

/// Admin variant — includes archived topics so they can be unarchived.
final quizAdminTopicsProvider =
    StreamProvider.family<List<QuizTopicSummary>, String>(
        (Ref ref, String subjectId) => ref
            .watch(quizRepositoryProvider)
            .watchTopics(subjectId, includeArchived: true));

/// Quizzes (banks) under a topic.
final quizTopicBanksProvider =
    StreamProvider.family<List<QuizBankSummary>, String>(
        (Ref ref, String topicId) =>
            ref.watch(quizRepositoryProvider).watchBanksIn(topicId: topicId));

/// Topic-less quizzes filed directly under a subject.
final quizSubjectLooseBanksProvider =
    StreamProvider.family<List<QuizBankSummary>, String>(
        (Ref ref, String subjectId) => ref
            .watch(quizRepositoryProvider)
            .watchBanksIn(subjectId: subjectId, topicless: true));

/// All quizzes (banks) under a subject (any topic) — used by the Admin CMS.
final quizSubjectBanksProvider =
    StreamProvider.family<List<QuizBankSummary>, String>(
        (Ref ref, String subjectId) => ref
            .watch(quizRepositoryProvider)
            .watchBanksIn(subjectId: subjectId, includeArchived: true));

final quizSubjectByIdProvider = FutureProvider.family<QuizSubject?, String>(
    (Ref ref, String id) => ref.watch(quizRepositoryProvider).subject(id));

final quizTopicByIdProvider = FutureProvider.family<QuizTopic?, String>(
    (Ref ref, String id) => ref.watch(quizRepositoryProvider).topic(id));

final Provider<QuizExportService> quizExportServiceProvider =
    Provider<QuizExportService>((Ref ref) => const QuizExportService());

/// Content providers (JSON loader architecture). The Cloud provider is a
/// not-configured stub in this version; both sit behind [QuestionProvider].
final Provider<QuestionProvider> localJsonProviderProvider =
    Provider<QuestionProvider>((Ref ref) => const LocalJsonQuestionProvider());
final Provider<QuestionProvider> cloudProviderProvider =
    Provider<QuestionProvider>((Ref ref) => const CloudQuestionProvider());

final quizBanksProvider =
    StreamProvider.family<List<QuizBankSummary>, bool>((Ref ref, bool archived) =>
        ref.watch(quizRepositoryProvider).watchBanks(includeArchived: archived));

final StreamProvider<List<QuizAttempt>> quizAttemptsProvider =
    StreamProvider<List<QuizAttempt>>(
        (Ref ref) => ref.watch(quizRepositoryProvider).watchAttempts());

final StreamProvider<QuizStats> quizStatsProvider = StreamProvider<QuizStats>(
    (Ref ref) => ref.watch(quizRepositoryProvider).watchStats());

final StreamProvider<int> quizWrongCountProvider = StreamProvider<int>(
    (Ref ref) => ref.watch(quizRepositoryProvider).watchWrongCount());

final StreamProvider<int> quizBookmarkCountProvider = StreamProvider<int>(
    (Ref ref) => ref.watch(quizRepositoryProvider).watchBookmarkCount());

final StreamProvider<Map<String, int>> qSubjectColorsProvider =
    StreamProvider<Map<String, int>>(
        (Ref ref) => ref.watch(quizRepositoryProvider).watchSubjectColors());

final qSubjectSuggestionsProvider = FutureProvider.autoDispose<List<String>>(
    (Ref ref) => ref.watch(quizRepositoryProvider).subjectSuggestions());

final qTagSuggestionsProvider = FutureProvider.autoDispose<List<String>>(
    (Ref ref) => ref.watch(quizRepositoryProvider).tagSuggestions());

/// Engine settings. Invalidate after saving to refresh readers.
final FutureProvider<QuizSettings> quizSettingsProvider =
    FutureProvider<QuizSettings>(
        (Ref ref) => ref.watch(quizRepositoryProvider).loadSettings());

/// The current question search/filter (search & filter page).
class QuizFilterNotifier extends Notifier<QuizFilter> {
  @override
  QuizFilter build() => const QuizFilter();
  void set(QuizFilter f) => state = f;
  void setQuery(String q) => state = state.copyWith(query: q);
  void reset() => state = const QuizFilter();
}

final NotifierProvider<QuizFilterNotifier, QuizFilter> quizFilterProvider =
    NotifierProvider<QuizFilterNotifier, QuizFilter>(QuizFilterNotifier.new);

/// Bumped after any bank/question/import/attempt mutation so paginated
/// (non-stream) lists reload.
class QRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state = state + 1;
}

final NotifierProvider<QRevision, int> qRevisionProvider =
    NotifierProvider<QRevision, int>(QRevision.new);

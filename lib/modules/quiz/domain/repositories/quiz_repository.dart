import 'package:lexiora/modules/quiz/domain/entities/quiz_bank.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_settings.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_stage_progress.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_subject.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_topic.dart';
import 'package:lexiora/modules/quiz/domain/quiz_grading.dart';

/// The Quiz Engine's domain contract. Local-first and content-agnostic: it only
/// ever consumes [QuizQuestion] objects, never knowing where they came from.
/// Structured so a future Cloud Sync can reuse [exportBackup]/[importBackup].
abstract interface class QuizRepository {
  // ── Subjects (v0.9.1, data-driven hierarchy) ────────────────────────────────
  Stream<List<QuizSubjectSummary>> watchSubjects({bool includeArchived});
  Future<QuizSubject?> subject(String id);
  Future<void> saveSubject(QuizSubject subject);
  Future<void> deleteSubject(String id); // cascades topics, banks, questions
  Future<void> reorderSubjects(List<String> orderedIds);

  // ── Topics ───────────────────────────────────────────────────────────────────
  Stream<List<QuizTopicSummary>> watchTopics(String subjectId,
      {bool includeArchived});
  Future<QuizTopic?> topic(String id);
  Future<void> saveTopic(QuizTopic topic);
  Future<void> deleteTopic(String id); // cascades its banks + questions
  Future<void> reorderTopics(String subjectId, List<String> orderedIds);

  // ── Banks ─────────────────────────────────────────────────────────────────
  Stream<List<QuizBankSummary>> watchBanks({bool includeArchived});
  Stream<List<QuizBankSummary>> watchBanksIn(
      {String? subjectId, String? topicId, bool topicless, bool includeArchived});
  Future<QuizBank?> bank(String id);
  Future<void> saveBank(QuizBank bank);
  Future<void> setBankArchived(String id, bool archived);
  Future<void> deleteBank(String id); // cascades its questions

  // ── Questions (paginated for 100k+) ─────────────────────────────────────────
  Future<List<QuizQuestion>> questions(QuizFilter filter,
      {int limit = 50, int offset = 0});
  Future<int> countQuestions(QuizFilter filter);
  Future<QuizQuestion?> question(String id);
  Future<void> saveQuestion(QuizQuestion question);
  Future<void> deleteQuestion(String id);
  Future<void> setBookmarked(String id, bool value);

  // ── Stage quizzes (v0.11.0) ────────────────────────────────────────────────
  Future<List<QuizQuestion>> stageQuestions(String subjectId, int stageIndex,
      {int perStage = 10, String? topicId});
  Future<int> stageQuestionCount(String subjectId, {String? topicId});
  Stream<List<QuizStageProgress>> watchStageProgress(String subjectId,
      {String? topicId});
  Future<void> saveStageResult({
    required String subjectId,
    required int stageIndex,
    required int correct,
    required int total,
    String? topicId,
  });

  // ── Play / attempts ─────────────────────────────────────────────────────────
  Future<List<QuizQuestion>> buildSession({
    String? bankId,
    QuizFilter? filter,
    int limit,
    bool shuffle,
  });
  Future<QuizAttempt> recordAttempt({
    required QuizMode mode,
    required List<QuestionOutcome> outcomes,
    String? bankId,
    String? title,
    int durationMs,
  });
  Stream<List<QuizAttempt>> watchAttempts({int limit});
  Future<List<AnsweredQuestion>> attemptReview(String attemptId);

  // ── Wrong-answer notebook ───────────────────────────────────────────────────
  Future<List<WrongAnswerEntry>> wrongAnswers(
      {String? subjectId, int limit, int offset});
  Future<void> deleteWrongAnswer(String questionId);
  Future<void> clearWrongAnswers();
  Stream<int> watchWrongCount();

  // ── Bookmarks & analytics ───────────────────────────────────────────────────
  Stream<int> watchBookmarkCount();
  Stream<QuizStats> watchStats();
  Future<List<SubjectAccuracy>> subjectAccuracies();

  // ── Colours (reused from Study Hub) + suggestions ───────────────────────────
  Stream<Map<String, int>> watchSubjectColors();
  Future<List<String>> subjectSuggestions();
  Future<List<String>> tagSuggestions();

  // ── Settings ─────────────────────────────────────────────────────────────────
  Future<QuizSettings> loadSettings();
  Future<void> saveSettings(QuizSettings settings);

  // ── Import (from any provider/source) ───────────────────────────────────────
  Future<int> importPayload(QuizImportPayload payload, ImportStrategy strategy,
      {String? subjectId, String? topicId});

  // ── Backup / restore ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> exportBackup();
  Future<void> importBackup(Map<String, dynamic> data);
}

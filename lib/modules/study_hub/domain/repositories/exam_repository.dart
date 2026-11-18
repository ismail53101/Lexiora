import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';

abstract interface class ExamRepository {
  // Exams
  Stream<List<StudyExam>> watchExams();

  /// Creates (id null) or updates an exam.
  Future<StudyExam> saveExam({
    String? id,
    required String subject,
    required String title,
    required String day,
    String? notes,
  });
  Future<void> deleteExam(String id);

  /// Exams with days left and syllabus progress, soonest first.
  Stream<List<ExamCountdown>> watchCountdowns();

  // Syllabus
  /// Every subject that has at least one topic.
  Stream<List<SubjectSyllabus>> watchSyllabi();

  /// Adds topics to [subject]'s checklist, skipping ones already there
  /// (ignoring case). Returns how many were actually added.
  Future<int> addTopics(String subject, List<String> titles);
  Future<void> setTopicDone(String id, bool done);
  Future<void> renameTopic(String id, String title);
  Future<void> deleteTopic(String id);

  /// Topics you have already planned sessions for in [subject] that are not
  /// on its syllabus yet (read-only view of the planner's sessions).
  Future<List<String>> topicsFromSessions(String subject);
}

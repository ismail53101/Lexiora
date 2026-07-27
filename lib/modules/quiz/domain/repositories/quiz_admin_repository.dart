import 'package:lexiora/modules/quiz/domain/entities/quiz_bank.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';

/// Hidden Admin architecture (no UI in this version).
///
/// A future in-app Admin CMS (or the desktop tooling) drives content authoring
/// through this interface: create/edit/delete banks, import/export JSON, and
/// publish updates. It is fully wired in the data layer so the eventual Admin UI
/// is a thin front-end — the engine and its storage never change.
abstract interface class QuizAdminRepository {
  Future<QuizBank> createBank({
    required String name,
    String? subject,
    String? topic,
    String? description,
    int? color,
    String? tags,
    String? version,
  });

  Future<void> updateBank(QuizBank bank);
  Future<void> deleteBank(String id);

  /// Imports raw JSON (validated) into a new/matched bank. Returns the count.
  Future<int> importJson(
    String jsonText, {
    ImportStrategy strategy,
    String? fallbackName,
  });

  /// Imports raw JSON and files the resulting bank + questions under the given
  /// subject/topic in the hierarchy. Returns the number of questions imported.
  Future<int> importJsonInto({
    required String jsonText,
    String? subjectId,
    String? topicId,
    ImportStrategy strategy,
    String? fallbackName,
  });

  /// Serialises a bank (and its questions) to the engine's JSON exchange format.
  Future<String> exportBankJson(String bankId);

  /// Duplicates a quiz (bank) and all its questions. Returns the new bank id.
  Future<String> duplicateQuiz(String bankId);

  /// Moves a quiz (and its questions) to another subject/topic.
  Future<void> moveQuiz(String bankId, {String? subjectId, String? topicId});

  /// Hook for a future publish/sync step (e.g. push to Cloud). No-op for now.
  Future<void> publishUpdates();
}

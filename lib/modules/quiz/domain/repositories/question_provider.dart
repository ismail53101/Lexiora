import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';

/// The generic content boundary of the Quiz Engine.
///
/// The engine consumes [QuizImportPayload]s and knows nothing about where they
/// come from. Concrete providers — Local JSON (assets), Admin CMS, Cloud API,
/// Manual import — implement this interface, so adding a new source never
/// touches the player, repository or UI. This is the seam that keeps
/// "questions are content, not code".
abstract interface class QuestionProvider {
  /// Which source this provider represents.
  QuizContentSource get source;

  /// Whether the provider can currently supply content (e.g. Cloud configured,
  /// assets present). Foundation stubs return false / empty gracefully.
  Future<bool> isAvailable();

  /// Lists the banks this provider can supply, without loading their questions.
  Future<List<QuizBankManifest>> listBanks();

  /// Loads a single bank (with its questions) by its provider-specific [ref].
  Future<QuizImportPayload> fetchBank(String ref);
}

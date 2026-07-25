import 'package:equatable/equatable.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';

/// A node in the Grammar tree used for navigation lists. Branch nodes
/// ([isLeaf] = false) drill into children; leaf nodes open a dedicated lesson.
///
/// For leaves, [status] and [isFavorite] reflect the user's live state; for
/// branches they are ignored.
class GrammarTopicSummary extends Equatable {
  const GrammarTopicSummary({
    required this.id,
    required this.title,
    required this.isLeaf,
    this.subtitle,
    this.status = GrammarProgressStatus.notStarted,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final bool isLeaf;
  final String? subtitle;
  final GrammarProgressStatus status;
  final bool isFavorite;

  bool get isCompleted => status == GrammarProgressStatus.completed;
  bool get isInProgress => status == GrammarProgressStatus.inProgress;

  @override
  List<Object?> get props =>
      <Object?>[id, title, isLeaf, subtitle, status, isFavorite];
}

import 'package:equatable/equatable.dart';

/// A vocabulary word list shown on the Vocabulary home (e.g. "General
/// Vocabulary", "Business Vocabulary"). [wordCount] is denormalized for display.
class VocabularyListSummary extends Equatable {
  const VocabularyListSummary({
    required this.id,
    required this.title,
    required this.wordCount,
    this.subtitle,
  });

  final String id;
  final String title;
  final String? subtitle;
  final int wordCount;

  @override
  List<Object?> get props => <Object?>[id, title, subtitle, wordCount];
}

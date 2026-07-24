import 'package:equatable/equatable.dart';

/// The current reading position and computed completion for a document.
class ReadingProgress extends Equatable {
  const ReadingProgress({
    required this.documentId,
    required this.lastPage,
    required this.totalPages,
    required this.percent,
    required this.updatedAt,
  });

  final String documentId;
  final int lastPage;
  final int totalPages;

  /// Completion fraction in the range 0..1.
  final double percent;
  final DateTime updatedAt;

  /// Whether the user has meaningfully started reading this document.
  bool get isStarted => percent > 0 || lastPage > 1;

  /// Whether the document has been read to the end.
  bool get isFinished => totalPages > 0 && lastPage >= totalPages;

  int get percentLabel => (percent * 100).round();

  @override
  List<Object?> get props =>
      [documentId, lastPage, totalPages, percent, updatedAt];
}

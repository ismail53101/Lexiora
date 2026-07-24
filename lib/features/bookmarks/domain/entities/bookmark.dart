import 'package:equatable/equatable.dart';

/// A page-level bookmark. When created from a text selection, the selected text
/// is stored in [label] so the bookmark list shows a meaningful preview.
class Bookmark extends Equatable {
  const Bookmark({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.createdAt,
    this.label,
  });

  final String id;
  final String documentId;
  final int pageNumber;
  final String? label;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, documentId, pageNumber, label, createdAt];
}

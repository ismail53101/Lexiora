import 'package:equatable/equatable.dart';
import 'package:lexiora/core/models/normalized_rect.dart';

/// Whether a note is attached to a whole page or to a specific text selection.
enum NoteAnchor { page, selection }

/// A user note attached to a page or a text selection within a document.
class Note extends Equatable {
  const Note({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.content,
    required this.anchor,
    required this.createdAt,
    required this.updatedAt,
    this.selectedText,
    this.rects = const <NormalizedRect>[],
  });

  final String id;
  final String documentId;
  final int pageNumber;
  final String content;
  final NoteAnchor anchor;

  /// The text the note is anchored to, when [anchor] is [NoteAnchor.selection].
  final String? selectedText;

  /// Normalized rects for a selection-anchored note; empty for page notes.
  final List<NormalizedRect> rects;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSelectionAnchored => anchor == NoteAnchor.selection;

  Note copyWith({String? content, DateTime? updatedAt}) => Note(
        id: id,
        documentId: documentId,
        pageNumber: pageNumber,
        content: content ?? this.content,
        anchor: anchor,
        selectedText: selectedText,
        rects: rects,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        documentId,
        pageNumber,
        content,
        anchor,
        selectedText,
        rects,
        createdAt,
        updatedAt,
      ];
}

import 'package:equatable/equatable.dart';
import 'package:lexiora/core/models/normalized_rect.dart';

/// Whether an annotation is drawn as a filled highlight or an underline.
enum AnnotationType { highlight, underline }

/// A text-anchored highlight or underline stored in Lexiora's own database.
///
/// [rects] are normalized to the page (0..1), so the annotation stays aligned
/// at any zoom level and is never written into the PDF itself.
class Highlight extends Equatable {
  const Highlight({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.type,
    required this.colorValue,
    required this.selectedText,
    required this.rects,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String documentId;
  final int pageNumber;
  final AnnotationType type;
  final int colorValue;
  final String selectedText;
  final List<NormalizedRect> rects;
  final DateTime createdAt;
  final DateTime updatedAt;

  Highlight copyWith({
    AnnotationType? type,
    int? colorValue,
    String? selectedText,
    List<NormalizedRect>? rects,
    DateTime? updatedAt,
  }) =>
      Highlight(
        id: id,
        documentId: documentId,
        pageNumber: pageNumber,
        type: type ?? this.type,
        colorValue: colorValue ?? this.colorValue,
        selectedText: selectedText ?? this.selectedText,
        rects: rects ?? this.rects,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        documentId,
        pageNumber,
        type,
        colorValue,
        selectedText,
        rects,
        createdAt,
        updatedAt,
      ];
}

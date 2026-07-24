import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:lexiora/core/models/normalized_rect.dart';

/// Direction the reader pages flow when scrolling.
enum ReaderScrollAxis { vertical, horizontal }

/// The reader's color/reading mode. [night] inverts page colors for low-light
/// reading; [sepia] applies a warm tint that is easier on the eyes.
enum ReaderColorMode { day, night, sepia }

/// How an overlay is drawn over the page text.
enum ReaderOverlayStyle { highlight, underline }

/// Selected text on a single page together with its normalized bounding rects.
@immutable
class PdfPageSelection {
  const PdfPageSelection({
    required this.pageNumber,
    required this.text,
    required this.rects,
  });

  final int pageNumber; // 1-based
  final String text;
  final List<NormalizedRect> rects;
}

/// A complete text selection, possibly spanning several pages.
@immutable
class PdfTextSelectionData {
  const PdfTextSelectionData({required this.text, required this.pages});

  final String text;
  final List<PdfPageSelection> pages;

  bool get isEmpty => pages.isEmpty || text.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// The page a single-page selection lives on (or the first page of a
  /// multi-page selection). Used when anchoring highlights and notes.
  int? get primaryPage => pages.isEmpty ? null : pages.first.pageNumber;
}

/// A set of rects the reader should paint over [pageNumber] — i.e. one visible
/// highlight or underline. The annotations feature maps its domain entities to
/// these so the reader has no knowledge of annotation storage.
@immutable
class ReaderOverlayRect {
  const ReaderOverlayRect({
    required this.id,
    required this.pageNumber,
    required this.rects,
    required this.colorValue,
    required this.style,
  });

  final String id;
  final int pageNumber;
  final List<NormalizedRect> rects;
  final int colorValue;
  final ReaderOverlayStyle style;
}

/// Context describing a tap on a word inside the reader. Feeds the (future)
/// tap-on-word popup extension point; see [WordAction].
@immutable
class PdfWordTapContext {
  const PdfWordTapContext({
    required this.pageNumber,
    required this.normalizedPosition,
    this.word,
  });

  final int pageNumber;

  /// Tap position in normalized (0..1) page coordinates.
  final Offset normalizedPosition;

  /// The resolved word, when the engine could determine one.
  final String? word;
}

/// Lightweight metadata read from a PDF without building any UI. Used during
/// import (page count / cover) and for offline search indexing.
@immutable
class PdfDocumentInfo {
  const PdfDocumentInfo({required this.pageCount});
  final int pageCount;
}

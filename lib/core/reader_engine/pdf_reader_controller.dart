import 'package:flutter/foundation.dart';

/// Immutable snapshot of the in-document search state.
@immutable
class PdfSearchState {
  const PdfSearchState({
    this.query = '',
    this.currentMatch = 0,
    this.totalMatches = 0,
    this.isSearching = false,
  });

  final String query;

  /// 1-based index of the active match; 0 when there is none.
  final int currentMatch;
  final int totalMatches;
  final bool isSearching;

  bool get hasMatches => totalMatches > 0;

  PdfSearchState copyWith({
    String? query,
    int? currentMatch,
    int? totalMatches,
    bool? isSearching,
  }) =>
      PdfSearchState(
        query: query ?? this.query,
        currentMatch: currentMatch ?? this.currentMatch,
        totalMatches: totalMatches ?? this.totalMatches,
        isSearching: isSearching ?? this.isSearching,
      );
}

/// Engine-agnostic controller for a live PDF viewer instance.
///
/// The reader UI talks to this interface only; the pdfrx implementation lives
/// behind it. Swapping the rendering engine means providing a different
/// [PdfReaderController] + [PdfEngine] — no reader UI changes required.
abstract class PdfReaderController {
  /// Whether the document has finished its first layout and is interactive.
  ValueListenable<bool> get isReady;

  /// Current page (1-based).
  ValueListenable<int> get currentPage;

  /// Current zoom factor (1.0 == fit).
  ValueListenable<double> get zoom;

  /// Total page count (0 until [isReady] is true).
  int get pageCount;

  Future<void> goToPage(int page);
  Future<void> nextPage();
  Future<void> previousPage();

  Future<void> zoomIn();
  Future<void> zoomOut();
  Future<void> resetZoom();

  /// Reactive in-document search state.
  ValueListenable<PdfSearchState> get searchState;
  Future<void> search(String query);
  Future<void> nextMatch();
  Future<void> previousMatch();
  void clearSearch();

  /// Text-selection helpers.
  Future<void> clearSelection();
  Future<void> copySelection();

  void dispose();
}

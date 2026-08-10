import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';
import 'package:lexiora/core/reader_engine/pdf_reader_controller.dart';
import 'package:pdfrx/pdfrx.dart';

/// pdfrx-backed implementation of the engine-agnostic [PdfReaderController].
///
/// IMPORTANT: [PdfTextSearcher] must only be constructed once the underlying
/// [PdfViewerController] is *ready* (attached to a live [PdfViewer] with a
/// loaded document). Its constructor calls `controller!.document…`, which
/// throws a null-check error if the controller isn't ready yet. Therefore the
/// searcher is created lazily in [handleReady] / on the first ready tick —
/// never eagerly in the constructor (doing so crashed the whole reader).
class PdfrxReaderController implements PdfReaderController {
  PdfrxReaderController() {
    pdf.addListener(_onPdfChanged);
  }

  /// The underlying pdfrx controller (used only by [PdfrxReaderView]).
  final PdfViewerController pdf = PdfViewerController();

  /// Created lazily once [pdf] is ready; null before that.
  PdfTextSearcher? _searcher;

  final ValueNotifier<bool> _isReady = ValueNotifier<bool>(false);
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(1);
  final ValueNotifier<double> _zoom = ValueNotifier<double>(1);
  final ValueNotifier<PdfSearchState> _searchState =
      ValueNotifier<PdfSearchState>(const PdfSearchState());
  String _query = '';

  /// The text searcher, available only after the viewer is ready.
  PdfTextSearcher? get searcherOrNull => _searcher;

  void _onPdfChanged() {
    if (!pdf.isReady) return;
    _searcher ??= _createSearcher();
    if (!_isReady.value) _isReady.value = true;
    _zoom.value = pdf.currentZoom;
    final int? page = pdf.pageNumber;
    if (page != null) _currentPage.value = page;
  }

  PdfTextSearcher _createSearcher() {
    final PdfTextSearcher searcher = PdfTextSearcher(pdf);
    searcher.addListener(_onSearchChanged);
    return searcher;
  }

  void _onSearchChanged() {
    final PdfTextSearcher? s = _searcher;
    if (s == null) return;
    final int? index = s.currentIndex;
    _searchState.value = PdfSearchState(
      query: _query,
      currentMatch: (index == null || s.matches.isEmpty) ? 0 : index + 1,
      totalMatches: s.matches.length,
      isSearching: s.isSearching,
    );
  }

  /// Called by the view once pdfrx reports the document is ready — the only
  /// safe point to construct the [PdfTextSearcher].
  void handleReady() {
    _searcher ??= _createSearcher();
    _isReady.value = true;
  }

  /// Called by the view when pdfrx reports a page change.
  void handlePageChanged(int? page) {
    if (page != null) _currentPage.value = page;
  }

  @override
  ValueListenable<bool> get isReady => _isReady;

  @override
  ValueListenable<int> get currentPage => _currentPage;

  @override
  ValueListenable<double> get zoom => _zoom;

  @override
  int get pageCount => pdf.isReady ? pdf.pageCount : 0;

  @override
  Future<void> goToPage(int page) async {
    if (!pdf.isReady) return;
    final int target = page.clamp(1, pdf.pageCount);
    await pdf.goToPage(pageNumber: target);
  }

  @override
  Future<void> nextPage() => goToPage(_currentPage.value + 1);

  @override
  Future<void> previousPage() => goToPage(_currentPage.value - 1);

  @override
  Future<void> zoomIn() async {
    if (!pdf.isReady) return;
    await pdf.setZoom(pdf.visibleRect.center, pdf.getNextZoom());
    _zoom.value = pdf.currentZoom;
  }

  @override
  Future<void> zoomOut() async {
    if (!pdf.isReady) return;
    await pdf.setZoom(pdf.visibleRect.center, pdf.getPreviousZoom());
    _zoom.value = pdf.currentZoom;
  }

  @override
  Future<void> resetZoom() async {
    if (!pdf.isReady) return;
    await pdf.setZoom(pdf.visibleRect.center, pdf.coverScale);
    _zoom.value = pdf.currentZoom;
  }

  /// Double-tap zoom toggle for the reader: zoom to a comfortable close-up
  /// centred on the tapped point, or back to the fit-to-screen scale when
  /// already zoomed in. Deliberately a modest step ("a little bit"), not a
  /// full zoom-in/zoom-out cycle.
  ///
  /// pdfrx's [PdfViewerController.setZoom] takes the zoom centre in *document*
  /// coordinates, not widget/screen pixels — passing a raw tap position was
  /// the cause of the "zoom jumps to the first page" bug (small screen
  /// coordinates are near the document origin, i.e. the top-left of page 1).
  /// We therefore convert the tap's global position to document coordinates
  /// (exactly like pdfrx does for pinch zoom) before zooming.
  Future<void> toggleDoubleTapZoom({
    required Offset globalPosition,
    required Offset localPosition,
    required Size viewSize,
  }) async {
    if (!pdf.isReady) return;
    final double base = pdf.coverScale;
    final double current = pdf.currentZoom;
    final bool zoomedIn = current > base * 1.2;
    final double target =
        zoomedIn ? base : math.min(base * 1.6, pdf.maxScale);

    // Zooming back OUT: keep the current viewport stable (its centre stays
    // put) — the same safe, proven path the toolbar zoom buttons use.
    if (zoomedIn) {
      await pdf.setZoom(pdf.visibleRect.center, target);
      _zoom.value = pdf.currentZoom;
      return;
    }

    final Offset? documentPoint = pdf.globalToDocument(globalPosition);
    if (documentPoint == null) {
      // Transform not yet available — fall back to viewport-centre zoom.
      await pdf.setZoom(pdf.visibleRect.center, target);
      _zoom.value = pdf.currentZoom;
      return;
    }

    // Zooming IN: keep the tapped content under the finger, mirroring pdfrx's
    // own pinch-zoom centring (document point + (view centre − tap) / zoom).
    final Offset center = documentPoint.translate(
      (viewSize.width / 2 - localPosition.dx) / target,
      (viewSize.height / 2 - localPosition.dy) / target,
    );
    await pdf.setZoom(center, target);
    _zoom.value = pdf.currentZoom;
  }

  @override
  ValueListenable<PdfSearchState> get searchState => _searchState;

  @override
  Future<void> search(String query) async {
    _query = query;
    final PdfTextSearcher? s = _searcher;
    if (s == null) return; // not ready yet
    if (query.trim().isEmpty) {
      s.resetTextSearch();
      _searchState.value = const PdfSearchState();
      return;
    }
    s.startTextSearch(query);
  }

  @override
  Future<void> nextMatch() async {
    await _searcher?.goToNextMatch();
  }

  @override
  Future<void> previousMatch() async {
    await _searcher?.goToPrevMatch();
  }

  @override
  void clearSearch() {
    _query = '';
    _searcher?.resetTextSearch();
    _searchState.value = const PdfSearchState();
  }

  @override
  Future<void> clearSelection() async {
    if (pdf.isReady) await pdf.textSelectionDelegate.clearTextSelection();
  }

  @override
  Future<void> copySelection() async {
    if (pdf.isReady) await pdf.textSelectionDelegate.copyTextSelection();
  }

  @override
  void dispose() {
    pdf.removeListener(_onPdfChanged);
    _searcher?.removeListener(_onSearchChanged);
    _searcher?.dispose();
    _isReady.dispose();
    _currentPage.dispose();
    _zoom.dispose();
    _searchState.dispose();
  }
}

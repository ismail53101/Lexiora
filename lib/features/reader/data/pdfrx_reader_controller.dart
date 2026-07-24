import 'package:flutter/foundation.dart';
import 'package:lexiora/core/reader_engine/pdf_reader_controller.dart';
import 'package:pdfrx/pdfrx.dart';

/// pdfrx-backed implementation of the engine-agnostic [PdfReaderController].
///
/// It wraps a [PdfViewerController] and a [PdfTextSearcher] and republishes
/// their state through simple [ValueListenable]s the reader UI can bind to,
/// keeping the UI free of any direct pdfrx dependency.
class PdfrxReaderController implements PdfReaderController {
  PdfrxReaderController() {
    pdf.addListener(_onPdfChanged);
    searcher.addListener(_onSearchChanged);
  }

  /// The underlying pdfrx controller (used only by [PdfrxReaderView]).
  final PdfViewerController pdf = PdfViewerController();

  /// The underlying pdfrx searcher (used for highlighting matches on canvas).
  late final PdfTextSearcher searcher = PdfTextSearcher(pdf);

  final ValueNotifier<bool> _isReady = ValueNotifier<bool>(false);
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(1);
  final ValueNotifier<double> _zoom = ValueNotifier<double>(1);
  final ValueNotifier<PdfSearchState> _searchState =
      ValueNotifier<PdfSearchState>(const PdfSearchState());
  String _query = '';

  void _onPdfChanged() {
    if (!pdf.isReady) return;
    _isReady.value = true;
    _zoom.value = pdf.currentZoom;
    final int? page = pdf.pageNumber;
    if (page != null) _currentPage.value = page;
  }

  void _onSearchChanged() {
    final int? index = searcher.currentIndex;
    _searchState.value = PdfSearchState(
      query: _query,
      currentMatch: (index == null || searcher.matches.isEmpty) ? 0 : index + 1,
      totalMatches: searcher.matches.length,
      isSearching: searcher.isSearching,
    );
  }

  /// Called by the view when pdfrx reports a page change.
  void handlePageChanged(int? page) {
    if (page != null) _currentPage.value = page;
  }

  /// Called by the view when the document finishes its first layout.
  void handleReady() => _isReady.value = true;

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

  @override
  ValueListenable<PdfSearchState> get searchState => _searchState;

  @override
  Future<void> search(String query) async {
    _query = query;
    if (query.trim().isEmpty) {
      searcher.resetTextSearch();
      _searchState.value = const PdfSearchState();
      return;
    }
    searcher.startTextSearch(query);
  }

  @override
  Future<void> nextMatch() async {
    await searcher.goToNextMatch();
  }

  @override
  Future<void> previousMatch() async {
    await searcher.goToPrevMatch();
  }

  @override
  void clearSearch() {
    _query = '';
    searcher.resetTextSearch();
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
    searcher.removeListener(_onSearchChanged);
    searcher.dispose();
    _isReady.dispose();
    _currentPage.dispose();
    _zoom.dispose();
    _searchState.dispose();
  }
}

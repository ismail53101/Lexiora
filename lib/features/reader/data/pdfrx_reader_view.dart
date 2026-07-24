import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lexiora/core/models/normalized_rect.dart';
import 'package:lexiora/core/reader_engine/pdf_engine.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/core/widgets/error_view.dart';
import 'package:lexiora/features/reader/data/pdfrx_reader_controller.dart';
import 'package:pdfrx/pdfrx.dart';

/// The concrete pdfrx viewer widget — the *only* widget in the app that imports
/// pdfrx directly.
///
/// It is stateful and keeps a single [PdfDocumentRefFile] for the document, so
/// rebuilds (highlight updates, page/selection/colour changes) never recreate
/// or reload the document — which was the root cause of the blank-reader bug.
/// It also surfaces pdfrx loading/error states in-place, so a failed load shows
/// an explained error with Retry instead of a blank screen.
class PdfrxReaderView extends StatefulWidget {
  const PdfrxReaderView({
    super.key,
    required this.controller,
    required this.config,
  });

  final PdfrxReaderController controller;
  final PdfViewConfig config;

  @override
  State<PdfrxReaderView> createState() => _PdfrxReaderViewState();
}

class _PdfrxReaderViewState extends State<PdfrxReaderView> {
  late PdfDocumentRefFile _docRef;

  static const ColorFilter _nightFilter = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  static const ColorFilter _sepiaFilter = ColorFilter.matrix(<double>[
    0.393, 0.769, 0.189, 0, 0, //
    0.349, 0.686, 0.168, 0, 0, //
    0.272, 0.534, 0.131, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  void initState() {
    super.initState();
    _docRef = PdfDocumentRefFile(widget.config.filePath);
    AppLogger.i('Reader opening file: ${widget.config.filePath}');
  }

  @override
  void didUpdateWidget(covariant PdfrxReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.filePath != widget.config.filePath) {
      _docRef = PdfDocumentRefFile(widget.config.filePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild once the document is ready so the searcher's match-highlight
    // paint callback (only available post-ready) gets wired in.
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller.isReady,
      builder: (BuildContext context, bool ready, _) {
        final Widget viewer = PdfViewer(
          _docRef,
          controller: widget.controller.pdf,
          initialPageNumber: widget.config.initialPage,
          params: _buildParams(),
        );
        return switch (widget.config.colorMode) {
          ReaderColorMode.day => viewer,
          ReaderColorMode.night =>
            ColorFiltered(colorFilter: _nightFilter, child: viewer),
          ReaderColorMode.sepia =>
            ColorFiltered(colorFilter: _sepiaFilter, child: viewer),
        };
      },
    );
  }

  PdfViewerParams _buildParams() {
    final PdfTextSearcher? searcher = widget.controller.searcherOrNull;
    return PdfViewerParams(
      backgroundColor: const Color(0xFFEDEDED),
      layoutPages: widget.config.scrollAxis == ReaderScrollAxis.horizontal
          ? _horizontalLayout
          : null,
      onViewerReady: (PdfDocument document, PdfViewerController c) {
        AppLogger.i('Reader ready — ${c.pageCount} pages');
        widget.controller.handleReady();
        widget.config.onDocumentLoaded?.call(c.pageCount);
      },
      onPageChanged: (int? page) {
        widget.controller.handlePageChanged(page);
        if (page != null) widget.config.onPageChanged?.call(page);
      },
      loadingBannerBuilder:
          (BuildContext context, int bytesDownloaded, int? totalBytes) =>
              const Center(child: CircularProgressIndicator()),
      errorBannerBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
        PdfDocumentRef documentRef,
      ) {
        AppLogger.e(
          'pdfrx failed to open document',
          error: error,
          stackTrace: stackTrace,
        );
        return ErrorView(
          title: 'Could not open this PDF',
          message: 'The document failed to load. It may be corrupted, '
              'password-protected, or in an unsupported format.',
          details: error.toString(),
          onRetry: () => setState(
            () => _docRef = PdfDocumentRefFile(widget.config.filePath),
          ),
        );
      },
      pagePaintCallbacks: <PdfViewerPagePaintCallback>[
        _paintOverlays,
        if (searcher != null) searcher.pageTextMatchPaintCallback,
      ],
      textSelectionParams: PdfTextSelectionParams(
        onTextSelectionChange: _onSelectionChange,
      ),
    );
  }

  /// Lays pages out left-to-right for horizontal reading.
  PdfPageLayout _horizontalLayout(List<PdfPage> pages, PdfViewerParams params) {
    final List<Rect> layouts = <Rect>[];
    double maxHeight = 0;
    for (final PdfPage p in pages) {
      maxHeight = math.max(maxHeight, p.height);
    }
    final double docHeight = maxHeight + params.margin * 2;
    double x = params.margin;
    for (final PdfPage p in pages) {
      layouts.add(Rect.fromLTWH(x, (docHeight - p.height) / 2, p.width, p.height));
      x += p.width + params.margin;
    }
    return PdfPageLayout(pageLayouts: layouts, documentSize: Size(x, docHeight));
  }

  /// Paints the persisted highlights/underlines for [page].
  void _paintOverlays(Canvas canvas, Rect pageRect, PdfPage page) {
    for (final ReaderOverlayRect overlay in widget.config.overlays) {
      if (overlay.pageNumber != page.pageNumber) continue;
      final Paint paint = Paint();
      for (final NormalizedRect r in overlay.rects) {
        final Rect rect = Rect.fromLTWH(
          pageRect.left + r.left * pageRect.width,
          pageRect.top + r.top * pageRect.height,
          r.width * pageRect.width,
          r.height * pageRect.height,
        );
        switch (overlay.style) {
          case ReaderOverlayStyle.highlight:
            paint
              ..style = PaintingStyle.fill
              ..color = Color(overlay.colorValue).withValues(alpha: 0.38);
            canvas.drawRRect(RRect.fromRectXY(rect, 2, 2), paint);
          case ReaderOverlayStyle.underline:
            paint
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Color(overlay.colorValue);
            canvas.drawLine(
              Offset(rect.left, rect.bottom),
              Offset(rect.right, rect.bottom),
              paint,
            );
        }
      }
    }
  }

  void _onSelectionChange(PdfTextSelection selection) {
    final ValueChanged<PdfTextSelectionData>? cb =
        widget.config.onSelectionChanged;
    if (cb == null) return;
    if (!selection.hasSelectedText) {
      cb(const PdfTextSelectionData(text: '', pages: <PdfPageSelection>[]));
      return;
    }
    _resolveSelection(selection).then(cb);
  }

  Future<PdfTextSelectionData> _resolveSelection(
    PdfTextSelection selection,
  ) async {
    final List<PdfPageTextRange> ranges =
        await selection.getSelectedTextRanges();
    final String text = await selection.getSelectedText();
    final List<PdfPage> pages = widget.controller.pdf.pages;
    final List<PdfPageSelection> result = <PdfPageSelection>[];

    for (final PdfPageTextRange range in ranges) {
      final int pageNo = range.pageNumber;
      if (pageNo < 1 || pageNo > pages.length) continue;
      final PdfPage page = pages[pageNo - 1];
      final double w = page.width;
      final double h = page.height;
      final List<NormalizedRect> rects = <NormalizedRect>[];
      for (final PdfTextFragmentBoundingRect fr
          in range.enumerateFragmentBoundingRects()) {
        final PdfRect b = fr.bounds;
        if (b.isEmpty) continue;
        rects.add(
          NormalizedRect(
            left: b.left / w,
            top: (h - b.top) / h,
            width: b.width / w,
            height: b.height / h,
          ),
        );
      }
      result.add(
        PdfPageSelection(pageNumber: pageNo, text: range.text, rects: rects),
      );
    }
    return PdfTextSelectionData(text: text, pages: result);
  }
}

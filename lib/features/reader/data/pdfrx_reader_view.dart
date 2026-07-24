import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lexiora/core/models/normalized_rect.dart';
import 'package:lexiora/core/reader_engine/pdf_engine.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';
import 'package:lexiora/features/reader/data/pdfrx_reader_controller.dart';
import 'package:pdfrx/pdfrx.dart';

/// The concrete pdfrx viewer widget. This is the *only* widget in the app that
/// imports pdfrx directly; everything else uses [PdfViewConfig] and
/// [PdfReaderController]. Swapping engines means replacing this file plus the
/// controller/engine — no feature code changes.
class PdfrxReaderView extends StatelessWidget {
  const PdfrxReaderView({
    super.key,
    required this.controller,
    required this.config,
  });

  final PdfrxReaderController controller;
  final PdfViewConfig config;

  // Full-matrix color inversion for night reading (avoids the BlendMode
  // artifacts some Android devices show with BlendMode.difference).
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
  Widget build(BuildContext context) {
    final Widget viewer = PdfViewer.file(
      config.filePath,
      controller: controller.pdf,
      initialPageNumber: config.initialPage,
      params: PdfViewerParams(
        backgroundColor: _backgroundFor(config.colorMode),
        layoutPages: config.scrollAxis == ReaderScrollAxis.horizontal
            ? _horizontalLayout
            : null,
        onViewerReady: (PdfDocument document, PdfViewerController c) {
          controller.handleReady();
          config.onDocumentLoaded?.call(c.pageCount);
        },
        onPageChanged: (int? page) {
          controller.handlePageChanged(page);
          if (page != null) config.onPageChanged?.call(page);
        },
        pagePaintCallbacks: <PdfViewerPagePaintCallback>[
          _paintOverlays,
          controller.searcher.pageTextMatchPaintCallback,
        ],
        textSelectionParams: PdfTextSelectionParams(
          onTextSelectionChange: _onSelectionChange,
        ),
      ),
    );

    return switch (config.colorMode) {
      ReaderColorMode.day => viewer,
      ReaderColorMode.night =>
        ColorFiltered(colorFilter: _nightFilter, child: viewer),
      ReaderColorMode.sepia =>
        ColorFiltered(colorFilter: _sepiaFilter, child: viewer),
    };
  }

  Color _backgroundFor(ReaderColorMode mode) => switch (mode) {
        ReaderColorMode.day => const Color(0xFFEDEDED),
        ReaderColorMode.night => const Color(0xFFEDEDED),
        ReaderColorMode.sepia => const Color(0xFFEDEDED),
      };

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
    return PdfPageLayout(
      pageLayouts: layouts,
      documentSize: Size(x, docHeight),
    );
  }

  /// Paints the persisted highlights/underlines for [page].
  void _paintOverlays(Canvas canvas, Rect pageRect, PdfPage page) {
    for (final ReaderOverlayRect overlay in config.overlays) {
      if (overlay.pageNumber != page.pageNumber) continue;
      final Paint paint = Paint()..color = Color(overlay.colorValue);
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
            canvas.drawRRect(
              RRect.fromRectXY(rect, 2, 2),
              paint,
            );
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

  /// Translates a pdfrx selection into our engine-agnostic
  /// [PdfTextSelectionData] with normalized rects, then forwards it.
  void _onSelectionChange(PdfTextSelection selection) {
    final ValueChanged<PdfTextSelectionData>? cb = config.onSelectionChanged;
    if (cb == null) return;
    if (!selection.hasSelectedText) {
      cb(const PdfTextSelectionData(text: '', pages: <PdfPageSelection>[]));
      return;
    }
    // Selection reads are async; resolve then publish.
    _resolveSelection(selection).then(cb);
  }

  Future<PdfTextSelectionData> _resolveSelection(
    PdfTextSelection selection,
  ) async {
    final List<PdfPageTextRange> ranges =
        await selection.getSelectedTextRanges();
    final String text = await selection.getSelectedText();
    final List<PdfPage> pages = controller.pdf.pages;
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

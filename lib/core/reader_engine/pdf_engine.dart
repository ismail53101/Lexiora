import 'package:flutter/widgets.dart';
import 'package:lexiora/core/reader_engine/pdf_reader_controller.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';

/// Declarative configuration for a viewer instance. Kept immutable so it can be
/// diffed cheaply; the reader rebuilds the viewer when it meaningfully changes.
@immutable
class PdfViewConfig {
  const PdfViewConfig({
    required this.filePath,
    this.initialPage = 1,
    this.scrollAxis = ReaderScrollAxis.vertical,
    this.colorMode = ReaderColorMode.day,
    this.overlays = const [],
    this.onPageChanged,
    this.onDocumentLoaded,
    this.onSelectionChanged,
    this.onWordTap,
  });

  final String filePath;
  final int initialPage;
  final ReaderScrollAxis scrollAxis;
  final ReaderColorMode colorMode;

  /// Highlights/underlines to paint over the pages.
  final List<ReaderOverlayRect> overlays;

  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onDocumentLoaded;
  final ValueChanged<PdfTextSelectionData>? onSelectionChanged;

  /// Placeholder hook for the future tap-on-word popup. Wired now, unused in
  /// Phase 1 until a [WordAction] is registered.
  final ValueChanged<PdfWordTapContext>? onWordTap;

  PdfViewConfig copyWith({
    int? initialPage,
    ReaderScrollAxis? scrollAxis,
    ReaderColorMode? colorMode,
    List<ReaderOverlayRect>? overlays,
  }) =>
      PdfViewConfig(
        filePath: filePath,
        initialPage: initialPage ?? this.initialPage,
        scrollAxis: scrollAxis ?? this.scrollAxis,
        colorMode: colorMode ?? this.colorMode,
        overlays: overlays ?? this.overlays,
        onPageChanged: onPageChanged,
        onDocumentLoaded: onDocumentLoaded,
        onSelectionChanged: onSelectionChanged,
        onWordTap: onWordTap,
      );
}

/// The swappable PDF engine abstraction.
///
/// Everything outside `features/reader/data` depends only on this interface, so
/// replacing pdfrx with another renderer is a single DI change. The default
/// implementation ([PdfrxEngine]) is registered in the injector.
abstract interface class PdfEngine {
  /// Creates a controller that will drive one viewer instance.
  PdfReaderController createController();

  /// Builds the viewer widget for [config], driven by [controller].
  Widget buildViewer({
    required PdfReaderController controller,
    required PdfViewConfig config,
  });

  /// Reads metadata (page count, ...) without building any UI. Used at import
  /// time and for background indexing of large documents.
  Future<PdfDocumentInfo> readDocumentInfo(String filePath);
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:lexiora/core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// Generates and caches a page-1 cover thumbnail for a PDF, so the library
/// grid can show a book's actual first page instead of a generic placeholder.
///
/// Rendering rasterizes the page as pdfrx (PDFium) sees it, so it works for
/// *any* PDF — including scanned/photographed ones with no text layer — since
/// a cover doesn't depend on the page having selectable text.
///
/// Failures (corrupt file, unsupported encryption, out of memory, ...) are
/// caught and logged; callers get `null` and simply fall back to the
/// placeholder cover. A missing thumbnail must never block importing or
/// opening a document.
class PdfCoverService {
  PdfCoverService();

  /// Thumbnail width in pixels; height is derived from the page's own aspect
  /// ratio. 320px is sharp enough for library grid cards at any density
  /// while staying cheap to render and store.
  static const int _targetWidth = 320;

  /// Renders [pdfPath]'s first page and saves it as a PNG named after
  /// [documentId] under the app's private support directory, returning the
  /// absolute path to the saved file, or `null` on any failure.
  Future<String?> generateCover({
    required String documentId,
    required String pdfPath,
  }) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(pdfPath);
      if (document.pages.isEmpty) return null;
      final PdfPage page = document.pages.first;

      final double aspect = page.width <= 0 ? 1.4 : page.height / page.width;
      const int width = _targetWidth;
      final int height = (width * aspect).round().clamp(1, 4000);

      final dynamic rendered = await page.render(width: width, height: height);
      if (rendered == null) return null;
      try {
        final Uint8List? png = await _toPng(
          rendered.pixels as Uint8List,
          rendered.width as int,
          rendered.height as int,
        );
        if (png == null) return null;

        final Directory dir = await _coverDirectory();
        final File file = File('${dir.path}/$documentId.png');
        await file.writeAsBytes(png, flush: true);
        return file.path;
      } finally {
        rendered.dispose();
      }
    } on Object catch (e) {
      AppLogger.w('PdfCoverService: cover generation failed for $pdfPath: $e');
      return null;
    } finally {
      if (document != null) await document.dispose();
    }
  }

  /// Deletes a previously generated cover file, if any. Safe to call even
  /// when [coverPath] is null or the file no longer exists.
  Future<void> deleteCover(String? coverPath) async {
    if (coverPath == null || coverPath.isEmpty) return;
    try {
      final File file = File(coverPath);
      if (await file.exists()) await file.delete();
    } on Object catch (e) {
      AppLogger.w('PdfCoverService: could not delete cover $coverPath: $e');
    }
  }

  Future<Directory> _coverDirectory() async {
    final Directory support = await getApplicationSupportDirectory();
    final Directory dir = Directory('${support.path}/covers');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Encodes raw RGBA8888 pixels as PNG bytes via Flutter's own image codec
  /// (no extra image-processing dependency needed).
  Future<Uint8List?> _toPng(Uint8List rgba, int width, int height) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final ui.Image image = await completer.future;
    try {
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}

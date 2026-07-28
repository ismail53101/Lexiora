import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// A single OCR-recognized word, positioned as a fraction (0..1) of its
/// page's width/height, top-origin (matches screen/image coordinates).
class _OcrWord {
  const _OcrWord({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  Map<String, Object?> toChannelMap() => <String, Object?>{
        'text': text,
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
      };
}

/// Makes scanned/photographed PDFs selectable and translatable by running
/// on-device OCR and writing the recognized text back into the PDF as an
/// invisible layer (see `MainActivity.embedOcrText`) — after which the
/// document behaves like any other PDF to the rest of the app: the existing
/// text-selection, highlight, dictionary and translate features all work on
/// it unmodified.
///
/// Pages that already have real text are detected and left completely alone,
/// so running this on a normal (non-scanned) or mixed document only ever
/// processes the pages that actually need it.
class PdfOcrService {
  PdfOcrService();

  static const MethodChannel _channel = MethodChannel('lexiora/platform');

  /// Render resolution for OCR input — higher than the library's cover
  /// thumbnail (320px) since recognition accuracy depends on legible glyphs,
  /// especially for smaller body text.
  static const int _renderWidth = 1600;

  /// Whether [pdfPath] already has real, extractable text on at least one
  /// page. A document is only considered "needs OCR" when *none* of its
  /// pages have any meaningful text — a single scanned page inside an
  /// otherwise normal PDF doesn't warrant reprocessing the whole document
  /// (that page simply won't be selectable, same as today).
  Future<bool> hasSelectableText(String pdfPath) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(pdfPath);
      for (final PdfPage page in document.pages) {
        if (await _pageHasText(page)) return true;
      }
      return false;
    } on Object catch (e) {
      AppLogger.w('PdfOcrService: hasSelectableText check failed: $e');
      // Unknown/unreadable — don't offer to reprocess a document we can't
      // even open for inspection.
      return true;
    } finally {
      if (document != null) await document.dispose();
    }
  }

  /// Runs OCR over every page of [sourcePath] that lacks real text and writes
  /// a new, searchable copy under the app's private storage, returning its
  /// path. Pages that already have text are left completely untouched.
  ///
  /// Never throws: any failure (a single page's recognition, the final
  /// embed step, ...) results in [sourcePath] being returned unchanged, so
  /// the reader always has a valid file to open either way.
  Future<String> makeSearchable({
    required String documentId,
    required String sourcePath,
    void Function(int page, int totalPages)? onProgress,
  }) async {
    PdfDocument? document;
    final List<String> tempImages = <String>[];
    try {
      document = await PdfDocument.openFile(sourcePath);
      final List<PdfPage> pages = document.pages;
      final List<Map<String, Object?>> pagesPayload = <Map<String, Object?>>[];

      for (int i = 0; i < pages.length; i++) {
        onProgress?.call(i + 1, pages.length);
        final PdfPage page = pages[i];
        if (await _pageHasText(page)) continue; // already selectable

        final String? imagePath =
            await _renderPageToTempPng(page, documentId, i);
        if (imagePath == null) continue;
        tempImages.add(imagePath);

        final List<_OcrWord>? words = await _recognize(imagePath);
        if (words == null || words.isEmpty) continue;
        pagesPayload.add(<String, Object?>{
          'pageIndex': i,
          'words':
              words.map((_OcrWord w) => w.toChannelMap()).toList(growable: false),
        });
      }

      if (pagesPayload.isEmpty) {
        // Nothing needed OCR, or nothing was recognized — the source is
        // already as searchable as it's going to get.
        return sourcePath;
      }

      final Directory dir = await _ocrDirectory();
      final String outputPath = '${dir.path}/$documentId.pdf';
      final String? saved = await _channel.invokeMethod<String>(
        'embedOcrText',
        <String, Object?>{
          'sourcePath': sourcePath,
          'outputPath': outputPath,
          'pages': pagesPayload,
        },
      );
      AppLogger.i(
        'PdfOcrService: made searchable — ${pagesPayload.length}/${pages.length} '
        'page(s) OCR\'d, saved to ${saved ?? "(unchanged)"}',
      );
      return saved ?? sourcePath;
    } on Object catch (e) {
      AppLogger.w('PdfOcrService: makeSearchable failed: $e');
      return sourcePath;
    } finally {
      if (document != null) await document.dispose();
      for (final String p in tempImages) {
        _deleteQuiet(p);
      }
    }
  }

  Future<bool> _pageHasText(PdfPage page) async {
    try {
      // pdfrx's per-page text loader — typed dynamically since the exact
      // return type isn't part of this file's otherwise-static API surface.
      final dynamic dynamicPage = page;
      final dynamic pageText = await dynamicPage.loadText();
      final String text = (pageText.fullText as String?) ?? '';
      return text.trim().length > 3;
    } on Object {
      return false;
    }
  }

  Future<String?> _renderPageToTempPng(
    PdfPage page,
    String documentId,
    int pageIndex,
  ) async {
    try {
      final double aspect = page.width <= 0 ? 1.4 : page.height / page.width;
      const int width = _renderWidth;
      final int height = (width * aspect).round().clamp(1, 6000);

      // See PdfCoverService for why fullWidth/fullHeight are required here —
      // without them this would only capture a native-scale crop of the
      // page's top-left corner instead of the whole page.
      final dynamic rendered = await page.render(
        width: width,
        height: height,
        fullWidth: width.toDouble(),
        fullHeight: height.toDouble(),
      );
      if (rendered == null) return null;
      try {
        final Uint8List? png = await _toPng(
          rendered.pixels as Uint8List,
          rendered.width as int,
          rendered.height as int,
        );
        if (png == null) return null;

        final Directory tmp = await getTemporaryDirectory();
        final File file = File('${tmp.path}/ocr_${documentId}_$pageIndex.png');
        await file.writeAsBytes(png, flush: true);
        return file.path;
      } finally {
        rendered.dispose();
      }
    } on Object catch (e) {
      AppLogger.w('PdfOcrService: render failed for page $pageIndex: $e');
      return null;
    }
  }

  Future<List<_OcrWord>?> _recognize(String imagePath) async {
    try {
      final Map<Object?, Object?>? raw = await _channel
          .invokeMapMethod<Object?, Object?>(
        'recognizeText',
        <String, Object?>{'path': imagePath},
      );
      if (raw == null) return null;
      final int imageWidth = (raw['imageWidth'] as num?)?.toInt() ?? 0;
      final int imageHeight = (raw['imageHeight'] as num?)?.toInt() ?? 0;
      if (imageWidth <= 0 || imageHeight <= 0) return null;

      final List<Object?> rawWords =
          (raw['words'] as List<Object?>?) ?? const <Object?>[];
      final List<_OcrWord> out = <_OcrWord>[];
      for (final Object? w in rawWords) {
        if (w is! Map) continue;
        final String? text = w['text'] as String?;
        if (text == null || text.trim().isEmpty) continue;
        final num? left = w['left'] as num?;
        final num? top = w['top'] as num?;
        final num? right = w['right'] as num?;
        final num? bottom = w['bottom'] as num?;
        if (left == null || top == null || right == null || bottom == null) {
          continue;
        }
        out.add(
          _OcrWord(
            text: text,
            left: left / imageWidth,
            top: top / imageHeight,
            right: right / imageWidth,
            bottom: bottom / imageHeight,
          ),
        );
      }
      return out;
    } on Object catch (e) {
      AppLogger.w('PdfOcrService: recognizeText failed: $e');
      return null;
    }
  }

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

  Future<Directory> _ocrDirectory() async {
    final Directory support = await getApplicationSupportDirectory();
    final Directory dir = Directory('${support.path}/ocr');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  void _deleteQuiet(String path) {
    try {
      final File f = File(path);
      if (f.existsSync()) f.deleteSync();
    } on Object {
      // Best-effort temp cleanup only.
    }
  }
}

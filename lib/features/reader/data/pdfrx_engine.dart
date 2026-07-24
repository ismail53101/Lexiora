import 'package:flutter/widgets.dart';
import 'package:lexiora/core/reader_engine/pdf_engine.dart';
import 'package:lexiora/core/reader_engine/pdf_reader_controller.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';
import 'package:lexiora/features/reader/data/pdfrx_reader_controller.dart';
import 'package:lexiora/features/reader/data/pdfrx_reader_view.dart';
import 'package:pdfrx/pdfrx.dart';

/// The default [PdfEngine], backed by pdfrx (PDFium). Registered in the
/// injector as the app's `PdfEngine`; replace this single binding to swap the
/// rendering engine.
class PdfrxEngine implements PdfEngine {
  const PdfrxEngine();

  @override
  PdfReaderController createController() => PdfrxReaderController();

  @override
  Widget buildViewer({
    required PdfReaderController controller,
    required PdfViewConfig config,
  }) =>
      PdfrxReaderView(
        controller: controller as PdfrxReaderController,
        config: config,
      );

  @override
  Future<PdfDocumentInfo> readDocumentInfo(String filePath) async {
    final PdfDocument document = await PdfDocument.openFile(filePath);
    try {
      return PdfDocumentInfo(pageCount: document.pages.length);
    } finally {
      await document.dispose();
    }
  }
}

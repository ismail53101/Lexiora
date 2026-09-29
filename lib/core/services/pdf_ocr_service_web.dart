/// OCR is currently implemented by Android's native channel only. Browser
/// PDFs remain usable; scanned PDFs simply retain their existing text layer.
class PdfOcrService {
  PdfOcrService();

  Future<bool> hasSelectableText(String pdfPath) async => true;

  Future<String> makeSearchable({
    required String documentId,
    required String sourcePath,
    void Function(int page, int totalPages)? onProgress,
  }) async => sourcePath;

  Future<void> deleteSearchable(String documentId) async {}
}

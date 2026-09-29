/// Browser PDF readers render their own page surfaces; no native cover cache
/// is created for browser-local documents.
class PdfCoverService {
  PdfCoverService();

  Future<String?> generateCover({
    required String documentId,
    required String pdfPath,
  }) async => null;

  Future<void> deleteCover(String? coverPath) async {}
}

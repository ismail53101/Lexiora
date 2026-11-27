import 'dart:io';
import 'dart:typed_data';

/// Persists bytes produced by the isolated PDF editor.
///
/// The reader keeps ownership of the library path; this service deliberately
/// does not update library metadata or annotations. A flushed write preserves
/// the existing document path so bookmarks, progress, and library references
/// remain valid.
class PdfEditService {
  const PdfEditService();

  Future<void> overwrite({required String filePath, required Uint8List bytes}) {
    return File(filePath).writeAsBytes(bytes, flush: true);
  }
}

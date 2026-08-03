import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/repositories/library_repository.dart';
import 'package:lexiora/modules/admin/data/services/admin_content_service.dart';
import 'package:lexiora/modules/admin/domain/entities/admin_link.dart';
import 'package:lexiora/modules/admin/domain/entities/admin_note.dart';
import 'package:path_provider/path_provider.dart';

/// Packages everything added through the Admin Panel — links, notes, and
/// every admin-tagged PDF's file + subject — into one zip, so it can be
/// handed off (e.g. attached to a message, or committed to the repo) and
/// later folded into the app's bundled content for a public release. This
/// device never publishes anything on its own; exporting is the deliberate,
/// one-time hand-off step in that workflow.
class AdminExportService {
  AdminExportService(this._content, this._library);

  final AdminContentService _content;
  final LibraryRepository _library;

  /// Builds the export zip and returns its path.
  ///
  /// Layout inside the zip:
  /// ```
  /// admin_export.json   — links, notes, and one entry per PDF (title,
  ///                        subject, original filename)
  /// pdfs/<filename>.pdf  — the actual PDF files, one per admin-tagged
  ///                        document that could still be found on disk
  /// ```
  Future<String> exportToZip() async {
    final List<AdminLink> links = await _content.loadLinks();
    final List<AdminNote> notes = await _content.loadNotes();
    final Map<String, String> pdfSubjects = await _content.loadPdfSubjects();

    final List<Map<String, Object?>> pdfEntries = <Map<String, Object?>>[];
    final Archive archive = Archive();
    int missing = 0;

    for (final MapEntry<String, String> entry in pdfSubjects.entries) {
      final LibraryDocument? doc = await _library.getById(entry.key);
      if (doc == null) {
        missing++;
        continue;
      }
      final File source = File(doc.filePath);
      if (!await source.exists()) {
        missing++;
        continue;
      }

      // Keep filenames unique inside the zip even if two admin PDFs
      // happen to share a display name.
      final String safeName =
          '${doc.id}_${_sanitizeFileName(doc.title)}.pdf';
      final List<int> bytes = await source.readAsBytes();
      archive.addFile(ArchiveFile('pdfs/$safeName', bytes.length, bytes));

      pdfEntries.add(<String, Object?>{
        'title': doc.title,
        'subject': entry.value,
        'filename': safeName,
      });
    }

    final Map<String, Object?> manifest = <String, Object?>{
      'exportedAt': DateTime.now().toIso8601String(),
      'links': links.map((AdminLink l) => l.toJson()).toList(),
      'notes': notes.map((AdminNote n) => n.toJson()).toList(),
      'pdfs': pdfEntries,
    };
    final List<int> manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );
    archive.addFile(
      ArchiveFile('admin_export.json', manifestBytes.length, manifestBytes),
    );

    final List<int> zipBytes = ZipEncoder().encode(archive);

    final Directory dir = await getApplicationSupportDirectory();
    final String stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .substring(0, 14);
    final File outFile = File('${dir.path}/sapiora-admin-export-$stamp.zip');
    await outFile.writeAsBytes(zipBytes);

    AppLogger.i(
      'AdminExportService: exported ${pdfEntries.length} PDF(s), '
      '${links.length} link(s), ${notes.length} note(s)'
      '${missing > 0 ? " ($missing PDF(s) skipped — file not found)" : ""}'
      ' -> ${outFile.path}',
    );
    return outFile.path;
  }

  String _sanitizeFileName(String name) {
    final String cleaned =
        name.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
    return cleaned.isEmpty ? 'document' : cleaned.replaceAll(' ', '_');
  }
}

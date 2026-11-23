import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:lexiora/modules/flashcards/domain/logic/csv_codec.dart';
import 'package:lexiora/modules/flashcards/domain/logic/export_rows.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/fc_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// A saved local backup file.
class FcBackupFile {
  const FcBackupFile({required this.path, required this.name, required this.savedAt});
  final String path;
  final String name;
  final DateTime savedAt;
}

/// Exports cards (CSV, Anki text, XLSX, PDF, JSON) and manages local JSON
/// backups. Files are written to a temp folder and handed to the share sheet.
class FcExportService {
  const FcExportService();

  /// Builds the file in memory (no I/O); useful for tests.
  Future<List<int>> buildBytes({
    required String title,
    required List<FcCard> cards,
    required Map<String, String> deckNames,
    required FcExportFormat format,
  }) async {
    final List<List<String>> rows = exportMatrix(cards, deckNames);
    return switch (format) {
      FcExportFormat.csv => utf8.encode('\uFEFF${encodeDelimited(rows)}'),
      FcExportFormat.anki => utf8.encode(ankiText(cards)),
      FcExportFormat.pdf => await _pdf(title, rows),
      FcExportFormat.xlsx => _xlsx(rows),
      FcExportFormat.json => utf8.encode(jsonEncode(<String, dynamic>{
          'title': title,
          'cards': <Map<String, dynamic>>[
            for (final FcCard c in cards)
              <String, dynamic>{
                'deck': deckNames[c.deckId],
                'type': c.type.label,
                'front': c.front,
                'back': c.back,
                'tags': c.tags,
                'notes': c.notes,
                'subject': c.subject,
                'topic': c.topic,
              },
          ],
        })),
    };
  }

  Future<String> exportCards({
    required String title,
    required List<FcCard> cards,
    required Map<String, String> deckNames,
    required FcExportFormat format,
  }) async {
    final List<int> bytes = await buildBytes(
        title: title, cards: cards, deckNames: deckNames, format: format);
    final String safe =
        title.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_').toLowerCase();
    final String filename = 'flashcards_$safe.${format.ext}';
    await shareBytes(bytes, filename, format.mime);
    return filename;
  }

  Future<void> shareBytes(List<int> bytes, String filename, String mime) async {
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(
      files: <XFile>[XFile(file.path, mimeType: mime, name: filename)],
      subject: filename,
    ));
  }

  // ── Backup / restore ─────────────────────────────────────────────────────────

  Future<Directory> _backupDir() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${base.path}/flashcards_backups');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Saves a backup in the app folder and offers it to the share sheet.
  Future<void> backupAndShare(FcRepository repo) async {
    final Map<String, dynamic> data = await repo.exportBackup();
    final String json = jsonEncode(data);
    final Directory dir = await _backupDir();
    final String stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .substring(0, 19);
    final File file = File('${dir.path}/flashcards_backup_$stamp.json');
    await file.writeAsString(json, flush: true);
    await shareBytes(utf8.encode(json), file.uri.pathSegments.last, 'application/json');
  }

  Future<List<FcBackupFile>> listBackups() async {
    final Directory dir = await _backupDir();
    final List<FcBackupFile> files = dir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.json'))
        .map((File f) => FcBackupFile(
              path: f.path,
              name: f.uri.pathSegments.last,
              savedAt: f.statSync().modified,
            ))
        .toList()
      ..sort((FcBackupFile a, FcBackupFile b) => b.savedAt.compareTo(a.savedAt));
    return files;
  }

  Future<void> deleteBackup(String path) async {
    final File f = File(path);
    if (f.existsSync()) await f.delete();
  }

  /// Replaces all flashcards data with the backup at [path].
  Future<void> restore(FcRepository repo, String path) async {
    final String json = await File(path).readAsString();
    await repo.importBackup((jsonDecode(json) as Map).cast<String, dynamic>());
  }

  // ── Format builders ───────────────────────────────────────────────────────────

  Future<Uint8List> _pdf(String title, List<List<String>> rows) async {
    final pw.Document doc = pw.Document();
    doc.addPage(pw.MultiPage(
      build: (pw.Context ctx) => <pw.Widget>[
        pw.Header(level: 0, text: title),
        if (rows.length <= 1)
          pw.Text('No cards.')
        else
          pw.TableHelper.fromTextArray(
            headers: rows.first,
            data: rows.skip(1).toList(),
            headerStyle:
                const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
      ],
    ));
    return doc.save();
  }

  Uint8List _xlsx(List<List<String>> rows) {
    final StringBuffer sheet = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<worksheet xmlns="http://schemas.openxmlformats.org/'
          'spreadsheetml/2006/main"><sheetData>');
    for (int r = 0; r < rows.length; r++) {
      sheet.write('<row r="${r + 1}">');
      for (int c = 0; c < rows[r].length; c++) {
        sheet.write('<c r="${_col(c)}${r + 1}" t="inlineStr"><is>'
            '<t xml:space="preserve">${_xml(rows[r][c])}</t></is></c>');
      }
      sheet.write('</row>');
    }
    sheet.write('</sheetData></worksheet>');
    final Archive archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes))
      ..addFile(ArchiveFile.string('_rels/.rels', _rootRels))
      ..addFile(ArchiveFile.string('xl/workbook.xml', _workbook))
      ..addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', _workbookRels))
      ..addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', sheet.toString()));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static String _col(int index) {
    String name = '';
    int n = index;
    while (true) {
      name = String.fromCharCode(65 + (n % 26)) + name;
      n = n ~/ 26 - 1;
      if (n < 0) break;
    }
    return name;
  }

  static String _xml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static const String _contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '</Types>';
  static const String _rootRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>';
  static const String _workbook =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets><sheet name="Flashcards" sheetId="1" r:id="rId1"/></sheets></workbook>';
  static const String _workbookRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '</Relationships>';
}

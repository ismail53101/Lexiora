import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

enum QuizExportFormat {
  csv,
  pdf,
  xlsx,
  json;

  String get label => switch (this) {
        QuizExportFormat.csv => 'CSV',
        QuizExportFormat.pdf => 'PDF',
        QuizExportFormat.xlsx => 'Excel (.xlsx)',
        QuizExportFormat.json => 'JSON',
      };
  String get ext => switch (this) {
        QuizExportFormat.csv => 'csv',
        QuizExportFormat.pdf => 'pdf',
        QuizExportFormat.xlsx => 'xlsx',
        QuizExportFormat.json => 'json',
      };
  String get mime => switch (this) {
        QuizExportFormat.csv => 'text/csv',
        QuizExportFormat.pdf => 'application/pdf',
        QuizExportFormat.xlsx =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        QuizExportFormat.json => 'application/json',
      };
}

/// What the user is exporting (Results / Wrong answers / Bookmarks / Analytics).
enum QuizExportScope {
  results,
  wrongAnswers,
  bookmarks,
  analytics;

  String get label => switch (this) {
        QuizExportScope.results => 'Results',
        QuizExportScope.wrongAnswers => 'Wrong answers',
        QuizExportScope.bookmarks => 'Bookmarks',
        QuizExportScope.analytics => 'Analytics',
      };
}

/// A saved local backup file.
class QuizBackupFile {
  const QuizBackupFile(
      {required this.path, required this.name, required this.savedAt});
  final String path;
  final String name;
  final DateTime savedAt;
}

/// Exports Quiz data (CSV/PDF/XLSX/JSON) and provides local JSON backup/restore.
/// Same pure-Dart approach (pdf + archive + share_plus) used across Sapiora, so
/// the XLSX is hand-built to avoid the `excel` package's XML version conflict.
class QuizExportService {
  const QuizExportService();

  /// Exports a header+rows matrix (row 0 = headers) in [format] and shares it.
  Future<String> exportMatrix({
    required String title,
    required List<List<String>> rows,
    required QuizExportFormat format,
  }) async {
    final List<int> bytes = switch (format) {
      QuizExportFormat.csv => utf8.encode(_csv(rows)),
      QuizExportFormat.pdf => await _pdf(title, rows),
      QuizExportFormat.xlsx => _xlsx(rows),
      QuizExportFormat.json => utf8.encode(jsonEncode(_asObjects(rows))),
    };
    final String safe =
        title.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_').toLowerCase();
    final String filename = 'sapiora_quiz_$safe.${format.ext}';
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
    final Directory dir = Directory('${base.path}/quiz_backups');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> backupAndShare(QuizRepository repo) async {
    final Map<String, dynamic> data = await repo.exportBackup();
    final String json = jsonEncode(data);
    final Directory dir = await _backupDir();
    final String stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .substring(0, 19);
    final File file = File('${dir.path}/quiz_backup_$stamp.json');
    await file.writeAsString(json, flush: true);
    await shareBytes(
        utf8.encode(json), file.uri.pathSegments.last, 'application/json');
  }

  Future<List<QuizBackupFile>> listBackups() async {
    final Directory dir = await _backupDir();
    final List<QuizBackupFile> files = dir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.json'))
        .map((File f) => QuizBackupFile(
              path: f.path,
              name: f.uri.pathSegments.last,
              savedAt: f.statSync().modified,
            ))
        .toList()
      ..sort((QuizBackupFile a, QuizBackupFile b) =>
          b.savedAt.compareTo(a.savedAt));
    return files;
  }

  Future<void> restore(QuizRepository repo, String path) async {
    final String json = await File(path).readAsString();
    await repo.importBackup((jsonDecode(json) as Map).cast<String, dynamic>());
  }

  // ── Format builders ───────────────────────────────────────────────────────────

  List<Map<String, String>> _asObjects(List<List<String>> rows) {
    if (rows.isEmpty) return const <Map<String, String>>[];
    final List<String> headers = rows.first;
    return rows.skip(1).map((List<String> r) {
      final Map<String, String> m = <String, String>{};
      for (int i = 0; i < headers.length; i++) {
        m[headers[i]] = i < r.length ? r[i] : '';
      }
      return m;
    }).toList();
  }

  String _csv(List<List<String>> rows) =>
      rows.map((List<String> r) => r.map(_csvCell).join(',')).join('\r\n');

  String _csvCell(String v) {
    final bool q =
        v.contains(',') || v.contains('"') || v.contains('\n') || v.contains('\r');
    final String e = v.replaceAll('"', '""');
    return q ? '"$e"' : e;
  }

  Future<Uint8List> _pdf(String title, List<List<String>> rows) async {
    final pw.Document doc = pw.Document();
    doc.addPage(pw.MultiPage(
      build: (pw.Context ctx) => <pw.Widget>[
        pw.Header(level: 0, text: title),
        if (rows.length <= 1)
          pw.Text('No data.')
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
      '<sheets><sheet name="Quiz" sheetId="1" r:id="rId1"/></sheets></workbook>';
  static const String _workbookRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '</Relationships>';
}

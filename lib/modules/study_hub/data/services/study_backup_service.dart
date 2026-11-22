import 'dart:convert';
import 'dart:io';

import 'package:lexiora/modules/study_hub/data/services/study_export_service.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/study_hub_repository.dart';
import 'package:path_provider/path_provider.dart';

/// A saved local backup file.
class BackupFile {
  const BackupFile({required this.path, required this.name, required this.savedAt, required this.sizeBytes});
  final String path;
  final String name;
  final DateTime savedAt;
  final int sizeBytes;
}

/// Local backup & restore for the whole Study Hub (sessions, breaks,
/// templates, subject colours). Backups live in the app's documents dir and can
/// also be shared out. Cloud sync can later reuse [StudyHubRepository.exportBackup]
/// / [importBackup] — this service is the local seam only.
class StudyBackupService {
  const StudyBackupService(this._export);

  final StudyExportService _export;

  Future<Directory> _dir() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${base.path}/darsnexa_backups');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Writes a backup file locally and returns it (does not share).
  Future<BackupFile> createBackup(StudyHubRepository repo) async {
    final Map<String, dynamic> data = await repo.exportBackup();
    final String json = jsonEncode(data);
    final Directory dir = await _dir();
    final String stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .split('T')
        .join('_')
        .substring(0, 19);
    final File file = File('${dir.path}/sapiora_backup_$stamp.json');
    await file.writeAsString(json, flush: true);
    return BackupFile(
      path: file.path,
      name: file.uri.pathSegments.last,
      savedAt: DateTime.now(),
      sizeBytes: json.length,
    );
  }

  /// Creates a backup and opens the share sheet so the user can store it safely.
  Future<void> backupAndShare(StudyHubRepository repo) async {
    final BackupFile backup = await createBackup(repo);
    await _export.shareBytes(
      await File(backup.path).readAsBytes(),
      backup.name,
      'application/json',
    );
  }

  /// Lists locally saved backups, newest first.
  Future<List<BackupFile>> listBackups() async {
    final Directory dir = await _dir();
    final List<BackupFile> files = dir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.json'))
        .map((File f) {
      final FileStat s = f.statSync();
      return BackupFile(
        path: f.path,
        name: f.uri.pathSegments.last,
        savedAt: s.modified,
        sizeBytes: s.size,
      );
    }).toList()
      ..sort((BackupFile a, BackupFile b) => b.savedAt.compareTo(a.savedAt));
    return files;
  }

  /// Restores a previously saved backup, replacing current Study Hub data.
  Future<void> restore(StudyHubRepository repo, String path) async {
    final String json = await File(path).readAsString();
    final Map<String, dynamic> data =
        (jsonDecode(json) as Map).cast<String, dynamic>();
    await repo.importBackup(data);
  }

  /// Restores a backup selected outside the app.
  ///
  /// The payload is validated before any database rows are replaced.
  Future<void> restoreBytes(
    StudyHubRepository repo,
    List<int> bytes,
  ) async {
    final dynamic decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('The selected file is not a valid backup.');
    }
    final Map<String, dynamic> data = decoded.cast<String, dynamic>();
    final String type = data['type']?.toString() ?? '';
    final String app = data['app']?.toString().toLowerCase() ?? '';
    final int? version = data['version'] is int
        ? data['version'] as int
        : int.tryParse(data['version']?.toString() ?? '');

    if (type != 'study_hub_backup') {
      throw const FormatException(
        'This file is not a DarsNexa Study Planner backup.',
      );
    }
    if (app.isNotEmpty && app != 'sapiora' && app != 'darsnexa') {
      throw const FormatException('This backup belongs to another app.');
    }
    if (version != 1) {
      throw const FormatException('This backup version is not supported.');
    }

    const List<String> requiredLists = <String>[
      'tasks',
      'logs',
      'templates',
      'templateItems',
      'subjects',
    ];
    for (final String key in requiredLists) {
      if (data[key] is! List) {
        throw FormatException('Backup is missing "$key".');
      }
    }

    await repo.importBackup(data);
  }

  /// Imports a DarsNexa Study Planner CSV export as planner entries.
  /// Existing data is kept; imported rows are added as new tasks.
  Future<int> importCsv(
    StudyHubRepository repo,
    List<int> bytes,
  ) async {
    final String csv = utf8.decode(bytes, allowMalformed: false);
    final List<List<String>> rows = _parseCsv(csv);
    if (rows.isEmpty) {
      throw const FormatException('The CSV file is empty.');
    }
    final List<String> header =
        rows.first.map((String v) => v.trim().toLowerCase()).toList();
    const List<String> expected = <String>[
      'date', 'type', 'subject', 'topic', 'start', 'end', 'priority', 'status', 'notes',
    ];
    if (header.length != expected.length ||
        !List.generate(expected.length, (int i) => header[i] == expected[i])
            .every((bool v) => v)) {
      throw const FormatException(
        'This is not a DarsNexa Study Planner CSV export.',
      );
    }

    int imported = 0;
    final DateTime now = DateTime.now();
    for (final List<String> row in rows.skip(1)) {
      if (row.every((String v) => v.trim().isEmpty)) continue;
      if (row.length != expected.length) {
        throw const FormatException('A CSV row has an invalid number of columns.');
      }
      final String day = row[0].trim();
      final String type = row[1].trim().toLowerCase();
      final String subject = row[2].trim();
      final String topic = row[3].trim();
      final int? start = _parseCsvMinute(row[4]);
      final int? end = _parseCsvMinute(row[5]);
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}
    final File f = File(path);
    if (f.existsSync()) await f.delete();
  }
}
).hasMatch(day)) {
        throw FormatException('Invalid date in CSV: ${row[0]}');
      }
      if ((row[4].trim().isNotEmpty && start == null) ||
          (row[5].trim().isNotEmpty && end == null)) {
        throw FormatException('Invalid time in CSV row.');
      }
      if (start != null && end != null && end <= start) {
        throw const FormatException('End time must be after start time in CSV.');
      }

      final bool isBreak = type == 'break';
      final TaskPriority priority = switch (row[6].trim().toLowerCase()) {
        'low' => TaskPriority.low,
        'high' => TaskPriority.high,
        _ => TaskPriority.medium,
      };
      final TaskStatus status = switch (row[7].trim().toLowerCase()) {
        'completed' => TaskStatus.completed,
        'in progress' => TaskStatus.inProgress,
        _ => TaskStatus.pending,
      };
      final String title = isBreak
          ? (subject.isEmpty ? 'Break' : subject)
          : (subject.isEmpty ? 'Imported session' : subject);
      await repo.saveTask(
        StudyTask(
          id: 'csv-${now.microsecondsSinceEpoch}-$imported',
          day: day,
          title: title,
          subject: isBreak ? null : (subject.isEmpty ? null : subject),
          topic: topic.isEmpty ? null : topic,
          notes: row[8].trim().isEmpty ? null : row[8].trim(),
          startMinute: start,
          endMinute: end,
          priority: priority,
          status: status,
          kind: isBreak ? SessionKind.breakTime : SessionKind.session,
          durationMinutes: start != null && end != null ? end - start : null,
          autoScheduled: false,
          orderIndex: imported,
          createdAt: now,
          updatedAt: now,
        ),
      );
      imported++;
    }
    if (imported == 0) {
      throw const FormatException('No planner rows were found in this CSV.');
    }
    return imported;
  }

  int? _parseCsvMinute(String value) {
    final String v = value.trim();
    if (v.isEmpty) return null;
    final List<String> parts = v.split(':');
    if (parts.length != 2) return null;
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 ||
        minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  List<List<String>> _parseCsv(String input) {
    final List<List<String>> rows = <List<String>>[];
    List<String> row = <String>[];
    final StringBuffer cell = StringBuffer();
    bool quoted = false;
    for (int i = 0; i < input.length; i++) {
      final String ch = input[i];
      if (ch == '"') {
        if (quoted && i + 1 < input.length && input[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (ch == ',' && !quoted) {
        row.add(cell.toString());
        cell.clear();
      } else if ((ch == '\n' || ch == '\r') && !quoted) {
        if (ch == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
        row.add(cell.toString());
        rows.add(row);
        row = <String>[];
        cell.clear();
      } else {
        cell.write(ch);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }

  Future<void> deleteBackup(String path) async {
    final File f = File(path);
    if (f.existsSync()) await f.delete();
  }
}

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
    final Directory dir = Directory('${base.path}/sapiora_backups');
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

  Future<void> deleteBackup(String path) async {
    final File f = File(path);
    if (f.existsSync()) await f.delete();
  }
}

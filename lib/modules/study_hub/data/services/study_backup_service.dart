import 'dart:convert';

import 'package:lexiora/core/services/backup_store.dart' as platform_backup;
import 'package:lexiora/modules/study_hub/data/services/study_export_service.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/study_hub_repository.dart';

/// A saved local backup file.
class BackupFile {
  const BackupFile({required this.path, required this.name, required this.savedAt, required this.sizeBytes});
  final String path;
  final String name;
  final DateTime savedAt;
  final int sizeBytes;
}

/// Local backup & restore for the whole Study Hub (sessions, goals, breaks,
/// templates, subject colours). Backups live in the app's documents dir and can
/// also be shared out. Cloud sync can later reuse [StudyHubRepository.exportBackup]
/// / [importBackup] — this service is the local seam only.
class StudyBackupService {
  const StudyBackupService(this._export);

  final StudyExportService _export;

  /// Writes a backup file locally and returns it (does not share).
  Future<BackupFile> createBackup(StudyHubRepository repo) async {
    final Map<String, dynamic> data = await repo.exportBackup();
    final String json = jsonEncode(data);
    final String stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .split('T')
        .join('_')
        .substring(0, 19);
    final platform_backup.StoredBackup stored = await platform_backup.saveBackup(
      'sapiora_backups',
      'sapiora_backup_$stamp.json',
      utf8.encode(json),
    );
    return BackupFile(
      path: stored.path,
      name: stored.name,
      savedAt: stored.savedAt,
      sizeBytes: stored.sizeBytes,
    );
  }

  /// Creates a backup and opens the share sheet so the user can store it safely.
  Future<void> backupAndShare(StudyHubRepository repo) async {
    final BackupFile backup = await createBackup(repo);
    await _export.shareBytes(
      await platform_backup.readBackup(backup.path),
      backup.name,
      'application/json',
    );
  }

  /// Lists locally saved backups, newest first.
  Future<List<BackupFile>> listBackups() async {
    final List<platform_backup.StoredBackup> stored =
        await platform_backup.listBackups('sapiora_backups');
    return stored.map((platform_backup.StoredBackup s) {
      return BackupFile(
        path: s.path,
        name: s.name,
        savedAt: s.savedAt,
        sizeBytes: s.sizeBytes,
      );
    }).toList(growable: false);
  }

  /// Restores a previously saved backup, replacing current Study Hub data.
  Future<void> restore(StudyHubRepository repo, String path) async {
    final String json = utf8.decode(await platform_backup.readBackup(path));
    final Map<String, dynamic> data =
        (jsonDecode(json) as Map).cast<String, dynamic>();
    await repo.importBackup(data);
  }

  Future<void> deleteBackup(String path) async {
    await platform_backup.deleteBackup(path);
  }
}

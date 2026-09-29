import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StoredBackup {
  const StoredBackup({required this.path, required this.name, required this.savedAt, required this.sizeBytes});
  final String path;
  final String name;
  final DateTime savedAt;
  final int sizeBytes;
}

Future<StoredBackup> saveBackup(String namespace, String filename, List<int> bytes) async {
  final Directory base = await getApplicationDocumentsDirectory();
  final Directory dir = Directory('${base.path}/$namespace');
  if (!dir.existsSync()) await dir.create(recursive: true);
  final File file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return StoredBackup(path: file.path, name: filename, savedAt: DateTime.now(), sizeBytes: bytes.length);
}

Future<List<StoredBackup>> listBackups(String namespace) async {
  final Directory base = await getApplicationDocumentsDirectory();
  final Directory dir = Directory('${base.path}/$namespace');
  if (!dir.existsSync()) return const <StoredBackup>[];
  return dir.listSync()
      .whereType<File>()
      .where((File file) => file.path.endsWith('.json'))
      .map((File file) {
        final FileStat stat = file.statSync();
        return StoredBackup(
          path: file.path,
          name: file.uri.pathSegments.last,
          savedAt: stat.modified,
          sizeBytes: stat.size,
        );
      })
      .toList()
    ..sort((StoredBackup a, StoredBackup b) => b.savedAt.compareTo(a.savedAt));
}

Future<List<int>> readBackup(String path) => File(path).readAsBytes();
Future<void> deleteBackup(String path) async {
  final File file = File(path);
  if (file.existsSync()) await file.delete();
}

import 'dart:convert';
import 'dart:html' as html;

class StoredBackup {
  const StoredBackup({required this.path, required this.name, required this.savedAt, required this.sizeBytes});
  final String path;
  final String name;
  final DateTime savedAt;
  final int sizeBytes;
}

String _prefix(String namespace) => 'sapiora_backup:$namespace:';

Future<StoredBackup> saveBackup(String namespace, String filename, List<int> bytes) async {
  final DateTime now = DateTime.now();
  final String path = '${_prefix(namespace)}$filename';
  html.window.localStorage[path] = jsonEncode(<String, Object>{
    'savedAt': now.toIso8601String(),
    'bytes': base64Encode(bytes),
  });
  return StoredBackup(path: path, name: filename, savedAt: now, sizeBytes: bytes.length);
}

Future<List<StoredBackup>> listBackups(String namespace) async {
  final String prefix = _prefix(namespace);
  final List<StoredBackup> out = <StoredBackup>[];
  for (final String key in html.window.localStorage.keys) {
    if (!key.startsWith(prefix)) continue;
    final String? raw = html.window.localStorage[key];
    if (raw == null) continue;
    try {
      final Map<String, dynamic> record = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final List<int> bytes = base64Decode(record['bytes'] as String);
      out.add(StoredBackup(
        path: key,
        name: key.substring(prefix.length),
        savedAt: DateTime.parse(record['savedAt'] as String),
        sizeBytes: bytes.length,
      ));
    } on Object {
      // Ignore malformed browser records.
    }
  }
  out.sort((StoredBackup a, StoredBackup b) => b.savedAt.compareTo(a.savedAt));
  return out;
}

Future<List<int>> readBackup(String path) async {
  final String? raw = html.window.localStorage[path];
  if (raw == null) throw StateError('Backup not found');
  final Map<String, dynamic> record = (jsonDecode(raw) as Map).cast<String, dynamic>();
  return base64Decode(record['bytes'] as String);
}

Future<void> deleteBackup(String path) async {
  html.window.localStorage.remove(path);
}

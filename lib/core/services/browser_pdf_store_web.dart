import 'dart:async';
import 'dart:html' as html;
// Flutter's Web compiler provides this platform library; the non-Web analyzer
// does not index it even though this file is selected only for Web builds.
// ignore: uri_does_not_exist
import 'dart:indexed_db' as idb;

import 'pdf_discovery_service.dart';

const String _databaseName = 'sapiora_local_files';
const String _storeName = 'pdfs';
const int _databaseVersion = 1;
const String _pathPrefix = 'sapiora-web-pdf:';

Future<idb.Database> _openDatabase() async {
  final idb.IdbFactory factory = html.window.indexedDB!;
  return factory.open(
    _databaseName,
    version: _databaseVersion,
    onUpgradeNeeded: (idb.VersionChangeEvent event) {
      final idb.Database database = (event.target as idb.Request).result;
      if (!database.objectStoreNames!.contains(_storeName)) {
        database.createObjectStore(_storeName);
      }
    },
  );
}

Future<DeviceFile> storeBrowserPdf(html.File file) async {
  final String id = '${DateTime.now().microsecondsSinceEpoch}-${file.name}';
  final idb.Database database = await _openDatabase();
  final idb.Transaction transaction = database.transaction(_storeName, 'readwrite');
  transaction.objectStore(_storeName).put(file, id);
  await transaction.onComplete.first;
  database.close();
  return DeviceFile(path: '$_pathPrefix$id', name: file.name, size: file.size);
}

Future<String> resolveBrowserPdf(String path) async {
  if (!path.startsWith(_pathPrefix)) return path;
  final String id = path.substring(_pathPrefix.length);
  final idb.Database database = await _openDatabase();
  final idb.Transaction transaction = database.transaction(_storeName, 'readonly');
  final html.Blob? blob =
      await transaction.objectStore(_storeName).getObject(id) as html.Blob?;
  await transaction.onComplete.first;
  database.close();
  if (blob == null) throw StateError('Saved PDF is no longer available.');
  return html.Url.createObjectUrl(blob);
}

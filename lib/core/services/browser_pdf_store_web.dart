import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
// Flutter's Web compiler provides this platform library; the non-Web analyzer
// does not index it even though this file is selected only for Web builds.
// ignore: uri_does_not_exist
import 'dart:indexed_db' as idb;

import 'pdf_discovery_service.dart';

const String _databaseName = 'sapiora_local_files';
const String _storeName = 'pdfs';
const int _databaseVersion = 1;
const String _pathPrefix = 'sapiora-web-pdf:';
final Map<String, String> _objectUrls = <String, String>{};

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
  final String? existingUrl = _objectUrls[id];
  if (existingUrl != null) return existingUrl;
  final idb.Database database = await _openDatabase();
  final idb.Transaction transaction = database.transaction(_storeName, 'readonly');
  final html.Blob? blob =
      await transaction.objectStore(_storeName).getObject(id) as html.Blob?;
  await transaction.onComplete.first;
  database.close();
  if (blob == null) throw StateError('Saved PDF is no longer available.');
  final String url = html.Url.createObjectUrl(blob);
  _objectUrls[id] = url;
  return url;
}

Future<List<int>> readBrowserPdfBytes(String path) async {
  if (!path.startsWith(_pathPrefix)) {
    throw StateError('Not a browser-managed PDF path.');
  }
  final String id = path.substring(_pathPrefix.length);
  final idb.Database database = await _openDatabase();
  final idb.Transaction transaction = database.transaction(_storeName, 'readonly');
  final html.Blob? blob =
      await transaction.objectStore(_storeName).getObject(id) as html.Blob?;
  await transaction.onComplete.first;
  database.close();
  if (blob == null) throw StateError('Saved PDF is no longer available.');
  final html.FileReader reader = html.FileReader();
  reader.readAsArrayBuffer(blob);
  await reader.onLoad.first;
  return (reader.result as ByteBuffer).asUint8List();
}

Future<void> deleteBrowserPdf(String path) async {
  if (!path.startsWith(_pathPrefix)) return;
  final String id = path.substring(_pathPrefix.length);
  final String? objectUrl = _objectUrls.remove(id);
  if (objectUrl != null) html.Url.revokeObjectUrl(objectUrl);
  final idb.Database database = await _openDatabase();
  final idb.Transaction transaction = database.transaction(_storeName, 'readwrite');
  transaction.objectStore(_storeName).delete(id);
  await transaction.onComplete.first;
  database.close();
}

Future<void> releaseBrowserPdf(String path) async {
  if (!path.startsWith(_pathPrefix)) return;
  final String id = path.substring(_pathPrefix.length);
  final String? objectUrl = _objectUrls.remove(id);
  if (objectUrl != null) html.Url.revokeObjectUrl(objectUrl);
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lexiora/core/error/exceptions.dart';
import 'package:lexiora/core/services/storage_paths.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// A PDF that has been copied into app-private storage.
class ImportedFile {
  const ImportedFile({
    required this.filePath,
    required this.displayName,
    required this.fileSize,
  });

  final String filePath;
  final String displayName;
  final int fileSize;
}

/// Handles picking a PDF and copying it into app-private storage.
///
/// Picking goes through a tiny native [MethodChannel] backed by the Android
/// Storage Access Framework (see `MainActivity.kt`), so no third-party plugin
/// and no storage permission are required. The native side returns a cache copy
/// of the chosen file; here we move it into the app documents directory so it
/// remains available offline and independent of the original.
class FileImportService {
  FileImportService(this._paths);

  final StoragePaths _paths;
  static const Uuid _uuid = Uuid();
  static const MethodChannel _channel = MethodChannel('lexiora/file_picker');

  /// Opens the system picker for a single PDF and imports it. Returns `null`
  /// when the user cancels.
  Future<ImportedFile?> pickAndImportPdf() async {
    final Map<Object?, Object?>? picked;
    try {
      picked = await _channel.invokeMapMethod<Object?, Object?>('pickPdf');
    } on PlatformException catch (e) {
      throw ImportException('Could not open the file picker.', cause: e);
    }

    if (picked == null) return null; // cancelled

    final String? cachePath = picked['path'] as String?;
    final String pickedName = (picked['name'] as String?) ?? 'document.pdf';
    if (cachePath == null) {
      throw const ImportException('The selected file is not accessible.');
    }

    try {
      final String safeName = _uniqueFileName(pickedName);
      final String destPath = await _paths.documentPath(safeName);
      final File cacheFile = File(cachePath);
      await cacheFile.copy(destPath);
      final int size = await File(destPath).length();
      // Best-effort cleanup of the native cache copy.
      try {
        if (await cacheFile.exists()) await cacheFile.delete();
      } on Object {
        // Ignore — the OS clears the cache dir eventually.
      }
      return ImportedFile(
        filePath: destPath,
        displayName: _titleFrom(pickedName),
        fileSize: size,
      );
    } on Object catch (e) {
      throw ImportException('Failed to import the selected PDF.', cause: e);
    }
  }

  String _uniqueFileName(String original) {
    final String ext =
        p.extension(original).isEmpty ? '.pdf' : p.extension(original);
    final String base = p
        .basenameWithoutExtension(original)
        .replaceAll(RegExp(r'[^A-Za-z0-9-_ ]'), '')
        .trim();
    final String slug = base.isEmpty ? 'document' : base;
    return '${slug}_${_uuid.v4().substring(0, 8)}$ext';
  }

  String _titleFrom(String fileName) {
    final String base = p.basenameWithoutExtension(fileName).trim();
    return base.isEmpty ? 'Untitled document' : base;
  }
}

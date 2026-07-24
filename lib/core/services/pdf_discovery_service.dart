import 'dart:io';

import 'package:flutter/services.dart';

/// A PDF found by walking the device filesystem (with all-files access),
/// referenced in place by its absolute [path] — never copied.
class DeviceFile {
  const DeviceFile({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;
  final int size;
}

/// Discovers every PDF on the device via the native `lexiora/platform` channel.
///
/// The app indexes files in place (no import, no copy): [scanAll] walks the
/// shared storage volumes and returns each PDF's absolute path, which the
/// reader opens directly. [hasFullAccess] reports whether the one-time
/// all-files-access grant is in place (always true below API 30).
class PdfDiscoveryService {
  PdfDiscoveryService();

  static const MethodChannel _channel = MethodChannel('lexiora/platform');

  /// True when the app currently has all-files access (always true below
  /// API 30, where broad read access is covered by the storage permission).
  Future<bool> hasFullAccess() async {
    if (!Platform.isAndroid) return true;
    return (await _channel.invokeMethod<bool>('isExternalStorageManager')) ??
        false;
  }

  /// Walks the shared-storage volumes for PDFs (requires all-files access).
  /// Each file is referenced by absolute path; nothing is copied.
  Future<List<DeviceFile>> scanAll() async {
    if (!Platform.isAndroid) return const <DeviceFile>[];
    final List<Object?>? raw =
        await _channel.invokeMethod<List<Object?>>('scanAllPdfs');
    if (raw == null) return const <DeviceFile>[];
    final List<DeviceFile> out = <DeviceFile>[];
    for (final Object? e in raw) {
      if (e is! Map) continue;
      final String? path = e['path'] as String?;
      if (path == null || path.isEmpty) continue;
      out.add(
        DeviceFile(
          path: path,
          name: (e['name'] as String?) ?? 'document.pdf',
          size: (e['size'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    return out;
  }
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lexiora/core/services/pdf_discovery_service.dart' show DeviceFile;

/// Manual PDF import via the system file picker (Storage Access Framework,
/// multi-select). The native side copies each chosen PDF into the app's private
/// files directory and returns its absolute path, original display name and
/// size. This complements — and coexists with — automatic discovery.
///
/// Returns an empty list when the user cancels or picks nothing.
class PdfImportService {
  PdfImportService();

  static const MethodChannel _channel = MethodChannel('lexiora/platform');

  Future<List<DeviceFile>> pickAndImport() async {
    if (!Platform.isAndroid) return const <DeviceFile>[];
    final List<Object?>? raw =
        await _channel.invokeMethod<List<Object?>>('pickPdfs');
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

import 'dart:io';

import 'package:flutter/foundation.dart';
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

  /// Installs the callback used when Android delivers a PDF while the app is
  /// already running or resumed from the background.
  void registerIncomingPdfHandler(ValueChanged<DeviceFile> onIncoming) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method != 'incomingPdf') return;
      final DeviceFile? file = _parseDeviceFile(call.arguments);
      if (file != null) onIncoming(file);
    });
  }

  /// Retrieves a PDF that launched the app before Flutter installed its
  /// method-channel callback (cold-start path).
  Future<DeviceFile?> takeInitialIncomingPdf() async {
    if (!Platform.isAndroid) return null;
    final Object? raw = await _channel.invokeMethod<Object?>('takeIncomingPdf');
    return _parseDeviceFile(raw);
  }

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

  DeviceFile? _parseDeviceFile(Object? raw) {
    if (raw is! Map) return null;
    final String? path = raw['path'] as String?;
    if (path == null || path.isEmpty) return null;
    return DeviceFile(
      path: path,
      name: (raw['name'] as String?) ?? 'document.pdf',
      size: (raw['size'] as num?)?.toInt() ?? 0,
    );
  }
}

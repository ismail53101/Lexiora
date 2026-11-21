import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lexiora/core/services/device_info_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Outcome of a storage-access request for automatic PDF discovery.
enum StorageAccessStatus { granted, denied, permanentlyDenied }

/// Version-aware storage-access flow for automatic PDF discovery.
///
/// Android 11+ uses the platform's All Files Access state directly. This is
/// more reliable than relying on permission_handler's cached state after the
/// user returns from the system settings screen.
class PermissionService {
  PermissionService(this._device);

  final DeviceInfoService _device;
  static const MethodChannel _platform = MethodChannel('lexiora/platform');

  Future<int> _sdk() => _device.androidSdkInt();

  Future<StorageAccessStatus> requestForDiscovery() async {
    if (!Platform.isAndroid) return StorageAccessStatus.granted;

    final int sdk = await _sdk();
    if (sdk >= 30) {
      try {
        final bool granted = await _isAllFilesAccessGranted();
        if (granted) return StorageAccessStatus.granted;

        await _platform.invokeMethod<void>('openAllFilesAccessSettings');

        // The user must grant this in Android Settings. The Library listens
        // for the app resume and re-checks the real native state there.
        return StorageAccessStatus.denied;
      } on PlatformException {
        return StorageAccessStatus.denied;
      }
    }

    final PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) return StorageAccessStatus.granted;
    if (status.isPermanentlyDenied) return StorageAccessStatus.permanentlyDenied;
    return StorageAccessStatus.denied;
  }

  Future<bool> isGrantedForDiscovery() async {
    if (!Platform.isAndroid) return true;

    final int sdk = await _sdk();
    if (sdk >= 30) {
      return _isAllFilesAccessGranted();
    }

    return (await Permission.storage.status).isGranted;
  }

  Future<bool> _isAllFilesAccessGranted() async {
    try {
      final bool? value =
          await _platform.invokeMethod<bool>('isExternalStorageManager');
      return value ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openSystemSettings() async {
    if (Platform.isAndroid && await _sdk() >= 30) {
      await _platform.invokeMethod<void>('openAllFilesAccessSettings');
      return;
    }
    await openAppSettings();
  }
}

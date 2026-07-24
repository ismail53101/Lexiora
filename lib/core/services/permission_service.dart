import 'dart:io';

import 'package:lexiora/core/services/device_info_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Outcome of a storage-access request for automatic PDF discovery.
enum StorageAccessStatus { granted, denied, permanentlyDenied }

/// Version-aware storage-access flow for automatic device-wide PDF discovery.
///
/// On Android 11+ (API 30+), listing every PDF on the device requires
/// "All files access" (MANAGE_EXTERNAL_STORAGE) — the same capability Adobe
/// Acrobat / Xodo use — so we request that (permission_handler opens the system
/// All-files-access screen). On Android 10 and below, READ_EXTERNAL_STORAGE is
/// sufficient.
class PermissionService {
  PermissionService(this._device);

  final DeviceInfoService _device;

  Future<Permission> _permission() async {
    final int sdk = await _device.androidSdkInt();
    return sdk >= 30 ? Permission.manageExternalStorage : Permission.storage;
  }

  Future<StorageAccessStatus> requestForDiscovery() async {
    if (!Platform.isAndroid) return StorageAccessStatus.granted;
    final PermissionStatus status = await (await _permission()).request();
    if (status.isGranted) return StorageAccessStatus.granted;
    if (status.isPermanentlyDenied) return StorageAccessStatus.permanentlyDenied;
    return StorageAccessStatus.denied;
  }

  Future<bool> isGrantedForDiscovery() async {
    if (!Platform.isAndroid) return true;
    return (await (await _permission()).status).isGranted;
  }

  Future<void> openSystemSettings() => openAppSettings();
}

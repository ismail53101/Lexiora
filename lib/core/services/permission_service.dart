import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper over `permission_handler`.
///
/// Lexiora Phase 1 is deliberately permission-free: importing a PDF uses the
/// Android system picker (Storage Access Framework), which grants scoped access
/// to the chosen file without any runtime permission. That is why the manifest
/// declares no storage permissions.
///
/// This service therefore exposes only:
///  * [openSystemSettings] — used by the Settings screen; and
///  * generic [request]/[isGranted] helpers that future modules (e.g. a camera
///    document scanner, or notifications) can use to ask for a specific
///    permission *only when that feature actually needs it* — never up front.
class PermissionService {
  const PermissionService();

  Future<bool> request(Permission permission) async {
    final PermissionStatus status = await permission.request();
    return status.isGranted || status.isLimited;
  }

  Future<bool> isGranted(Permission permission) async =>
      (await permission.status).isGranted;

  Future<void> openSystemSettings() => openAppSettings();
}

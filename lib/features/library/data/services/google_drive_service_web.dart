import 'package:lexiora/features/library/data/services/google_drive_models.dart';

const String sapioraAndroidOAuthClientId =
    '201143865879-gvgqcnsec1nj1g9drva2mu52bgcvd402.apps.googleusercontent.com';
const String sapioraWebOAuthClientId =
    '201143865879-g6e2o0jgl71uuf2qeah4589vs45ousmi.apps.googleusercontent.com';
const String googleDriveReadonlyScope =
    'https://www.googleapis.com/auth/drive.readonly';

/// Web implementation for the Android-only Google Drive cache flow.
///
/// The Web UI presents a deliberate availability message. Keeping this
/// implementation behind the conditional export prevents dart:io,
/// path_provider, and native Google Sign-In cache code from entering Web builds.
class GoogleDriveService {
  GoogleDriveService();

  bool get isConnected => false;

  Future<void> connect() async {
    throw UnsupportedError(
      'Google Drive browsing is currently available in the Android app.',
    );
  }

  Future<void> disconnect() async {}
  Future<void> clearDriveCache() async {}

  Future<List<GoogleDrivePdf>> listPdfs() async {
    throw UnsupportedError(
      'Google Drive browsing is currently available in the Android app.',
    );
  }

  Future<DriveCachedFile?> downloadThumbnail(GoogleDrivePdf pdf) async {
    throw UnsupportedError(
      'Google Drive browsing is currently available in the Android app.',
    );
  }

  Future<DrivePdfOpenResult> openPdf(
    GoogleDrivePdf pdf, {
    void Function(DriveDownloadProgress progress)? onProgress,
  }) async {
    throw UnsupportedError(
      'Google Drive browsing is currently available in the Android app.',
    );
  }

  Future<DriveCachedFile> downloadPdf(GoogleDrivePdf pdf) async {
    throw UnsupportedError(
      'Google Drive browsing is currently available in the Android app.',
    );
  }
}

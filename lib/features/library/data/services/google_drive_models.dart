class GoogleDrivePdf {
  const GoogleDrivePdf({
    required this.id,
    required this.name,
    required this.size,
    required this.modifiedTime,
    this.thumbnailLink,
  });
  final String id;
  final String name;
  final int size;
  final DateTime? modifiedTime;
  final String? thumbnailLink;
  String get cacheVersion =>
      '${modifiedTime?.toUtc().toIso8601String() ?? ''}|$size';
}

class DriveDownloadProgress {
  const DriveDownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    this.fromCache = false,
  });
  final int downloadedBytes;
  final int? totalBytes;
  final bool fromCache;
  double? get fraction {
    final int? total = totalBytes;
    if (total == null || total <= 0) return null;
    return (downloadedBytes / total).clamp(0.0, 1.0);
  }
  int? get remainingBytes {
    final int? total = totalBytes;
    if (total == null) return null;
    return (total - downloadedBytes).clamp(0, total);
  }
}

class DriveCachedFile {
  const DriveCachedFile({required this.path, required this.size});
  final String path;
  final int size;
}

class DrivePdfOpenResult {
  const DrivePdfOpenResult({required this.file, required this.fromCache});
  final DriveCachedFile file;
  final bool fromCache;
}

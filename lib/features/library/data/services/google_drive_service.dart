import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String sapioraAndroidOAuthClientId =
    '201143865879-gvgqcnsec1nj1g9drva2mu52bgcvd402.apps.googleusercontent.com';
const String sapioraWebOAuthClientId =
    '201143865879-g6e2o0jgl71uuf2qeah4589vs45ousmi.apps.googleusercontent.com';
const String googleDriveReadonlyScope =
    'https://www.googleapis.com/auth/drive.readonly';

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

class DrivePdfOpenResult {
  const DrivePdfOpenResult({required this.file, required this.fromCache});

  final File file;
  final bool fromCache;
}

/// Authenticates the current Google user and manages private, version-aware
/// Drive PDF cache files. Cached files are keyed by the immutable Drive file ID
/// and are never inserted into the local Device Library database.
class GoogleDriveService {
  GoogleDriveService({GoogleSignIn? signIn})
      : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  final http.Client _client = http.Client();
  final Map<String, Future<DrivePdfOpenResult>> _activeDownloads =
      <String, Future<DrivePdfOpenResult>>{};
  bool _initialized = false;
  GoogleSignInAccount? _account;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _signIn.initialize(
      clientId: sapioraAndroidOAuthClientId,
      serverClientId: sapioraWebOAuthClientId,
    );
    _initialized = true;
    _account = await _signIn.attemptLightweightAuthentication();
  }

  Future<GoogleSignInAccount> connect() async {
    await _ensureInitialized();
    final GoogleSignInAccount? restored = _account;
    if (restored != null) return restored;
    final GoogleSignInAccount account = await _signIn.authenticate();
    _account = account;
    return account;
  }

  bool get isConnected => _account != null;

  Future<void> disconnect() async {
    _account = null;
    await _signIn.signOut();
  }

  Future<void> clearDriveCache() async {
    final Directory cache = await _cacheDirectory();
    if (await cache.exists()) await cache.delete(recursive: true);
    final Directory thumbnailCache = await _thumbnailDirectory();
    if (await thumbnailCache.exists()) {
      await thumbnailCache.delete(recursive: true);
    }
  }

  Future<String> _accessToken() async {
    await _ensureInitialized();
    final GoogleSignInAccount account = await connect();
    final GoogleSignInClientAuthorization authorization = await account
        .authorizationClient
        .authorizeScopes(const <String>[googleDriveReadonlyScope]);
    final String token = authorization.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Google Drive authorization did not return an access token.');
    }
    return token;
  }

  Future<List<GoogleDrivePdf>> listPdfs() async {
    try {
      final List<GoogleDrivePdf> live = await _listPdfsFromDrive();
      await _writeIndex(live);
      return live;
    } on Object {
      final List<GoogleDrivePdf>? cached = await _readIndex();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<GoogleDrivePdf>> _listPdfsFromDrive() async {
    final String token = await _accessToken();
    final Uri uri = Uri.https(
      'www.googleapis.com',
      '/drive/v3/files',
      <String, String>{
        'q': "mimeType = 'application/pdf' and trashed = false",
        'orderBy': 'modifiedTime desc',
        'pageSize': '100',
        'spaces': 'drive',
        'fields': 'files(id,name,size,modifiedTime,mimeType,thumbnailLink)',
      },
    );
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw HttpException('Google Drive returned ${response.statusCode}.');
    }
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['files'] is! List<Object?>) {
      return const <GoogleDrivePdf>[];
    }
    return (decoded['files'] as List<Object?>)
        .whereType<Map<String, dynamic>>()
        .map(_pdfFromMap)
        .whereType<GoogleDrivePdf>()
        .toList(growable: false);
  }

  GoogleDrivePdf? _pdfFromMap(Map<String, dynamic> raw) {
    final String? id = raw['id'] as String?;
    final String? name = raw['name'] as String?;
    if (id == null || name == null) return null;
    return GoogleDrivePdf(
      id: id,
      name: name,
      size: int.tryParse('${raw['size'] ?? 0}') ?? 0,
      modifiedTime: DateTime.tryParse('${raw['modifiedTime'] ?? ''}'),
      thumbnailLink: raw['thumbnailLink'] as String?,
    );
  }

  Future<void> _writeIndex(List<GoogleDrivePdf> files) async {
    final Directory cache = await _cacheDirectory();
    await cache.create(recursive: true);
    await File(p.join(cache.path, 'index.json')).writeAsString(
      jsonEncode(files
          .map((GoogleDrivePdf file) => <String, Object?>{
                'id': file.id,
                'name': file.name,
                'size': file.size,
                'modifiedTime': file.modifiedTime?.toUtc().toIso8601String(),
                'thumbnailLink': file.thumbnailLink,
              })
          .toList(growable: false)),
      flush: true,
    );
  }

  Future<List<GoogleDrivePdf>?> _readIndex() async {
    try {
      final Directory cache = await _cacheDirectory();
      final File index = File(p.join(cache.path, 'index.json'));
      if (!await index.exists()) return null;
      final Object? decoded = jsonDecode(await index.readAsString());
      if (decoded is! List<Object?>) return null;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_pdfFromMap)
          .whereType<GoogleDrivePdf>()
          .toList(growable: false);
    } on Object {
      return null;
    }
  }

  Future<File?> downloadThumbnail(GoogleDrivePdf pdf) async {
    final String? thumbnailLink = pdf.thumbnailLink;
    if (thumbnailLink == null || thumbnailLink.isEmpty) return null;
    final String token = await _accessToken();
    final http.Response response = await _client.get(
      Uri.parse(thumbnailLink),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return null;
    final Directory cache = await _thumbnailDirectory();
    await cache.create(recursive: true);
    final File target = File(p.join(cache.path, '${pdf.id}.png'));
    return target.writeAsBytes(response.bodyBytes, flush: true);
  }

  /// Returns a complete local PDF, reusing the current cached Drive version or
  /// streaming a new one. Concurrent requests for the same file share one
  /// future, so a second tap can never start a duplicate download.
  Future<DrivePdfOpenResult> openPdf(
    GoogleDrivePdf pdf, {
    void Function(DriveDownloadProgress progress)? onProgress,
  }) {
    final Future<DrivePdfOpenResult>? active = _activeDownloads[pdf.id];
    if (active != null) return active;
    final Future<DrivePdfOpenResult> future = _openPdf(
      pdf,
      onProgress: onProgress,
    );
    _activeDownloads[pdf.id] = future;
    future.then<void>(
      (_) => _activeDownloads.remove(pdf.id),
      onError: (Object _, StackTrace _) => _activeDownloads.remove(pdf.id),
    );
    return future;
  }

  /// Compatibility wrapper for the existing local-import use case. The
  /// dedicated Drive Library uses [openPdf] to receive cache/progress state.
  Future<File> downloadPdf(GoogleDrivePdf pdf) async =>
      (await openPdf(pdf)).file;

  Future<DrivePdfOpenResult> _openPdf(
    GoogleDrivePdf pdf, {
    void Function(DriveDownloadProgress progress)? onProgress,
  }) async {
    final Directory cache = await _cacheDirectory();
    await cache.create(recursive: true);
    final File target = File(p.join(cache.path, '${pdf.id}.pdf'));
    final File metadata = File(p.join(cache.path, '${pdf.id}.json'));
    final Map<String, dynamic>? saved = await _readMetadata(metadata);
    if (await _isCompleteCurrentCache(target, saved, pdf)) {
      onProgress?.call(
        DriveDownloadProgress(
          downloadedBytes: await target.length(),
          totalBytes: pdf.size > 0 ? pdf.size : await target.length(),
          fromCache: true,
        ),
      );
      return DrivePdfOpenResult(file: target, fromCache: true);
    }

    final String token = await _accessToken();
    final File partial = File(p.join(cache.path, '${pdf.id}.part'));
    final int existingBytes = await partial.exists() ? await partial.length() : 0;
    final Uri uri = Uri.https(
      'www.googleapis.com',
      '/drive/v3/files/${pdf.id}',
      const <String, String>{'alt': 'media'},
    );
    final http.Request request = http.Request('GET', uri)
      ..headers['Authorization'] = 'Bearer $token';
    if (existingBytes > 0) {
      request.headers['Range'] = 'bytes=$existingBytes-';
    }

    http.StreamedResponse response = await _client.send(request);
    bool append = existingBytes > 0 && response.statusCode == 206;
    if (response.statusCode == 416 || (existingBytes > 0 && response.statusCode == 200)) {
      if (await partial.exists()) await partial.delete();
      append = false;
      final http.Request restart = http.Request('GET', uri)
        ..headers['Authorization'] = 'Bearer $token';
      response = await _client.send(restart);
    }
    if (response.statusCode != 200 && response.statusCode != 206) {
      throw HttpException('Google Drive download failed (${response.statusCode}).');
    }

    final int initialBytes = append ? existingBytes : 0;
    final int? totalBytes = response.contentLength == null
        ? (pdf.size > 0 ? pdf.size : null)
        : initialBytes + response.contentLength!;
    final IOSink sink = partial.openWrite(
      mode: append ? FileMode.append : FileMode.write,
    );
    int downloaded = initialBytes;
    try {
      onProgress?.call(
        DriveDownloadProgress(
          downloadedBytes: downloaded,
          totalBytes: totalBytes,
        ),
      );
      await for (final List<int> chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        onProgress?.call(
          DriveDownloadProgress(
            downloadedBytes: downloaded,
            totalBytes: totalBytes,
          ),
        );
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    final int finalSize = await partial.length();
    final int? expectedSize = pdf.size > 0 ? pdf.size : totalBytes;
    if (finalSize <= 0 || (expectedSize != null && finalSize != expectedSize)) {
      throw StateError(
        'Incomplete Google Drive PDF download: $finalSize/${expectedSize ?? '?'} bytes.',
      );
    }
    if (await target.exists()) await target.delete();
    await partial.rename(target.path);
    await metadata.writeAsString(
      jsonEncode(<String, Object?>{
        'fileId': pdf.id,
        'version': pdf.cacheVersion,
        'size': finalSize,
        'cachedAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
    return DrivePdfOpenResult(file: target, fromCache: false);
  }

  Future<bool> _isCompleteCurrentCache(
    File target,
    Map<String, dynamic>? metadata,
    GoogleDrivePdf pdf,
  ) async {
    if (!await target.exists() || metadata == null) return false;
    final int length = await target.length();
    if (length <= 0 || (pdf.size > 0 && length != pdf.size)) return false;
    return metadata['fileId'] == pdf.id &&
        metadata['version'] == pdf.cacheVersion &&
        int.tryParse('${metadata['size'] ?? 0}') == length;
  }

  Future<Map<String, dynamic>?> _readMetadata(File file) async {
    try {
      if (!await file.exists()) return null;
      final Object? decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }

  Future<Directory> _cacheDirectory() async {
    final Directory root = await getApplicationSupportDirectory();
    return Directory(p.join(root.path, 'drive_cache'));
  }

  Future<Directory> _thumbnailDirectory() async {
    final Directory root = await getApplicationSupportDirectory();
    return Directory(p.join(root.path, 'drive_thumbnail_cache'));
  }
}

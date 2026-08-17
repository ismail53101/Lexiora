import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String sapioraAndroidOAuthClientId =
    '201143865879-gvgqcnsec1nj1g9drva2mu52bgcvd402.apps.googleusercontent.com';
const String googleDriveReadonlyScope =
    'https://www.googleapis.com/auth/drive.readonly';

class GoogleDrivePdf {
  const GoogleDrivePdf({
    required this.id,
    required this.name,
    required this.size,
    required this.modifiedTime,
  });

  final String id;
  final String name;
  final int size;
  final DateTime? modifiedTime;
}

/// Authenticates the current Google user and downloads selected PDFs only into
/// app-private cache. The existing managed-file reader and annotation pipeline
/// then handles the cached file exactly like a device import.
class GoogleDriveService {
  GoogleDriveService({GoogleSignIn? signIn})
      : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  bool _initialized = false;
  GoogleSignInAccount? _account;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _signIn.initialize(clientId: sapioraAndroidOAuthClientId);
    _initialized = true;
  }

  Future<GoogleSignInAccount> connect() async {
    await _ensureInitialized();
    final GoogleSignInAccount account = await _signIn.authenticate();
    _account = account;
    return account;
  }

  Future<void> disconnect() async {
    _account = null;
    await _signIn.signOut();
  }

  Future<String> _accessToken() async {
    await _ensureInitialized();
    final GoogleSignInAccount account = _account ?? await connect();
    final GoogleSignInClientAuthorization authorization = await account
        .authorizationClient
        .authorizeScopes(const <String>[googleDriveReadonlyScope]);
    final String? token = authorization.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Google Drive authorization did not return an access token.');
    }
    return token;
  }

  Future<List<GoogleDrivePdf>> listPdfs() async {
    final String token = await _accessToken();
    final Uri uri = Uri.https('www.googleapis.com', '/drive/v3/files', <String, String>{
      'q': "mimeType = 'application/pdf' and trashed = false",
      'orderBy': 'modifiedTime desc',
      'pageSize': '100',
      'spaces': 'drive',
      'fields': 'files(id,name,size,modifiedTime,mimeType)',
    });
    final http.Response response = await http.get(
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
        .map((Map<String, dynamic> raw) {
          final String? id = raw['id'] as String?;
          final String? name = raw['name'] as String?;
          if (id == null || name == null) return null;
          return GoogleDrivePdf(
            id: id,
            name: name,
            size: int.tryParse('${raw['size'] ?? 0}') ?? 0,
            modifiedTime: DateTime.tryParse('${raw['modifiedTime'] ?? ''}'),
          );
        })
        .whereType<GoogleDrivePdf>()
        .toList(growable: false);
  }

  Future<File> downloadPdf(GoogleDrivePdf pdf) async {
    final String token = await _accessToken();
    final Uri uri = Uri.https(
      'www.googleapis.com',
      '/drive/v3/files/${pdf.id}',
      const <String, String>{'alt': 'media'},
    );
    final http.Response response = await http.get(
      uri,
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw HttpException('Google Drive download failed (${response.statusCode}).');
    }
    final Directory root = await getApplicationSupportDirectory();
    final Directory cache = Directory(p.join(root.path, 'drive_cache'));
    await cache.create(recursive: true);
    final String safeName = pdf.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final File target = File(p.join(cache.path, '${pdf.id}_$safeName'));
    return target.writeAsBytes(response.bodyBytes, flush: true);
  }
}

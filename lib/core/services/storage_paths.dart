import 'dart:io';

import 'package:lexiora/core/constants/app_constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves and lazily creates the app-private storage locations Lexiora uses.
///
/// Everything is stored under the application documents directory, which is
/// private to the app and requires no permission — imported PDFs live in
/// `documents/`, generated cover thumbnails in `covers/`.
class StoragePaths {
  StoragePaths();

  Directory? _appDir;

  Future<Directory> _appDocuments() async =>
      _appDir ??= await getApplicationDocumentsDirectory();

  Future<Directory> _subDir(String name) async {
    final Directory dir = Directory(p.join((await _appDocuments()).path, name));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> documentsDir() => _subDir(AppConstants.documentsDirName);

  Future<Directory> coversDir() => _subDir(AppConstants.coversDirName);

  /// Absolute destination path for an imported document [fileName].
  Future<String> documentPath(String fileName) async =>
      p.join((await documentsDir()).path, fileName);
}

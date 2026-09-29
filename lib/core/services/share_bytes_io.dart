import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareBytes(List<int> bytes, String filename, String mime) async {
  final Directory dir = await getTemporaryDirectory();
  final File file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[XFile(file.path, mimeType: mime, name: filename)],
      subject: filename,
    ),
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

Future<String> persistAiImage(String sourcePath, String imageId) async {
  final Directory support = await getApplicationSupportDirectory();
  final Directory dir = Directory('${support.path}/ai_images');
  if (!await dir.exists()) await dir.create(recursive: true);
  final String ext = sourcePath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
  final String savedPath = '${dir.path}/$imageId.$ext';
  await File(sourcePath).copy(savedPath);
  return savedPath;
}

Future<String?> readAiImageDataUrl(String path) async {
  try {
    final File file = File(path);
    if (!await file.exists()) return null;
    final List<int> bytes = await file.readAsBytes();
    final String mime = path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  } on Object {
    return null;
  }
}

ImageProvider<Object> aiImageProvider(String path) =>
    FileImage(File(path)) as ImageProvider<Object>;

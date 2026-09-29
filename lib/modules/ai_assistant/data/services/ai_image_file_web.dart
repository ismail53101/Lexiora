import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

Future<String> persistAiImage(String sourcePath, String imageId) async {
  final XFile file = XFile(sourcePath);
  final List<int> bytes = await file.readAsBytes();
  final String mime = sourcePath.toLowerCase().endsWith('.png')
      ? 'image/png'
      : 'image/jpeg';
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

Future<String?> readAiImageDataUrl(String path) async {
  if (path.startsWith('data:image/')) return path;
  try {
    final XFile file = XFile(path);
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
    NetworkImage(path) as ImageProvider<Object>;

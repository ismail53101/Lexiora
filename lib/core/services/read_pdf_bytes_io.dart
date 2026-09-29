import 'dart:io';

Future<List<int>> readPdfBytes(String path) => File(path).readAsBytes();

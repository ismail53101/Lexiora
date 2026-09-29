import 'dart:io';

Future<bool> localFileExists(String path) => File(path).exists();
Future<int> localFileLength(String path) => File(path).length();
Future<void> deleteLocalFile(String path) => File(path).delete();

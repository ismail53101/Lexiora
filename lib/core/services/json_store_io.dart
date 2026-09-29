import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<Map<String, dynamic>> readJsonStore(String name) async {
  final Directory dir = await getApplicationSupportDirectory();
  final File file = File('${dir.path}/$name.json');
  if (!await file.exists()) return <String, dynamic>{};
  final String text = await file.readAsString();
  if (text.trim().isEmpty) return <String, dynamic>{};
  final Object? decoded = jsonDecode(text);
  return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
}

Future<void> writeJsonStore(String name, Map<String, dynamic> data) async {
  final Directory dir = await getApplicationSupportDirectory();
  if (!await dir.exists()) await dir.create(recursive: true);
  await File('${dir.path}/$name.json').writeAsString(jsonEncode(data));
}

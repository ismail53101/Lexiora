import 'dart:convert';
import 'dart:html' as html;

Future<Map<String, dynamic>> readJsonStore(String name) async {
  final String? raw = html.window.localStorage['sapiora_json:$name'];
  if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
  final Object? decoded = jsonDecode(raw);
  return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
}

Future<void> writeJsonStore(String name, Map<String, dynamic> data) async {
  html.window.localStorage['sapiora_json:$name'] = jsonEncode(data);
}

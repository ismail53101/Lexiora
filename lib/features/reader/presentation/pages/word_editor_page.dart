import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lexiora/core/services/pdf_discovery_service.dart';
import 'package:lexiora/core/services/pdf_import_service.dart';

class WordEditorPage extends StatefulWidget {
  const WordEditorPage({required this.file, super.key});
  final DeviceFile file;
  @override State<WordEditorPage> createState() => _WordEditorPageState();
}

class _WordEditorPageState extends State<WordEditorPage> {
  final TextEditingController _text = TextEditingController();
  bool _loading = true;
  String? _error;
  bool get _docx => widget.file.name.toLowerCase().endsWith('.docx');

  @override void initState() { super.initState(); if (_docx) _load(); else _loading = false; }
  Future<void> _load() async {
    try {
      final archive = ZipDecoder().decodeBytes(await File(widget.file.path).readAsBytes());
      final entry = archive.findFile('word/document.xml');
      if (entry == null) throw const FormatException('This DOCX has no document.xml');
      final xml = utf8.decode(entry.content as List<int>);
      final paragraphs = RegExp(r'<w:p(?: [^>]*)?>(.*?)</w:p>', dotAll: true).allMatches(xml).map((m) => RegExp(r'<w:t(?: [^>]*)?>(.*?)</w:t>', dotAll: true).allMatches(m.group(1)!).map((t) => _unescape(t.group(1)!)).join()).join('\n');
      _text.text = paragraphs;
    } catch (e) { _error = 'Could not read this DOCX: $e'; }
    if (mounted) setState(() => _loading = false);
  }
  String _unescape(String s) => s.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"').replaceAll('&apos;', "'");
  String _escape(String s) => const HtmlEscape().convert(s);
  Future<void> _save() async {
    try {
      final source = await File(widget.file.path).readAsBytes(); final archive = ZipDecoder().decodeBytes(source); final old = archive.findFile('word/document.xml'); if (old == null) throw const FormatException('Missing document.xml');
      final body = _text.text.split('\n').map((p) => '<w:p><w:r><w:t xml:space="preserve">${_escape(p)}</w:t></w:r></w:p>').join();
      final original = utf8.decode(old.content as List<int>); final replaced = original.replaceFirst(RegExp(r'<w:body>.*?</w:body>', dotAll: true), '<w:body>$body</w:body>');
      final out = Archive(); for (final e in archive) { out.addFile(ArchiveFile(e.name, e.name == 'word/document.xml' ? utf8.encode(replaced).length : e.size, e.name == 'word/document.xml' ? Uint8List.fromList(utf8.encode(replaced)) : e.content)); }
      await File(widget.file.path).writeAsBytes(ZipEncoder().encode(out)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to the same DOCX file')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save DOCX: $e'))); }
  }
  Future<void> _openExternal() async { try { await const MethodChannel('lexiora/platform').invokeMethod('openWordFile', {'path': widget.file.path, 'mime': widget.file.mimeType}); } on PlatformException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'No compatible app installed'))); } }
  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (!_docx) {
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Legacy .doc files cannot be edited inside DarsNexa.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _openExternal, icon: const Icon(Icons.open_in_new), label: const Text('Open in Word/Docs')),
      ])));
    } else if (_error != null) {
      body = Center(child: Text(_error!));
    } else {
      body = Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Expanded(child: TextField(controller: _text, expands: true, maxLines: null, minLines: null, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Edit document text'))),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: _openExternal, icon: const Icon(Icons.open_in_new), label: const Text('Open in installed app'))),
      ]));
    }
    return Scaffold(appBar: AppBar(title: Text(widget.file.name), actions: [if (_docx && !_loading) IconButton(onPressed: _save, icon: const Icon(Icons.save))]), body: body);
  }
  @override void dispose() { _text.dispose(); super.dispose(); }
}

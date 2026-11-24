import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/pdf_discovery_service.dart';
import 'package:lexiora/core/services/pdf_import_service.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/repositories/library_repository.dart';

class WordEditorPage extends StatefulWidget {
  const WordEditorPage({
    this.file,
    this.documentId,
    this.externalLaunch = false,
    super.key,
  }) : assert(file != null || documentId != null);

  final DeviceFile? file;
  final String? documentId;
  final bool externalLaunch;

  @override
  State<WordEditorPage> createState() => _WordEditorPageState();
}

class _FormatRange {
  const _FormatRange(
    this.start,
    this.end,
    this.bold,
    this.italic,
    this.underline,
    this.size,
    this.color,
  );

  final int start;
  final int end;
  final bool bold;
  final bool italic;
  final bool underline;
  final double size;
  final Color color;
}

class _WordEditorPageState extends State<WordEditorPage> {
  final TextEditingController _text = TextEditingController();
  final List<_FormatRange> _ranges = <_FormatRange>[];
  LibraryDocument? _document;
  bool _loading = true;
  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  double _size = 11;
  Color _color = Colors.black;
  TextAlign _align = TextAlign.left;
  String? _error;

  bool get _docx =>
      (_document?.fileName ?? widget.file?.name ?? '')
          .toLowerCase()
          .endsWith('.docx');
  String get _path => _document?.filePath ?? widget.file!.path;
  String get _name => _document?.fileName ?? widget.file!.name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _document = widget.file == null
          ? await sl<LibraryRepository>().getById(widget.documentId!)
          : LibraryDocument(
              id: 'external',
              title: widget.file!.name,
              fileName: widget.file!.name,
              filePath: widget.file!.path,
              fileSize: widget.file!.size,
              pageCount: 0,
              isFavorite: false,
              importedAt: DateTime.now(),
            );
      if (_document == null) {
        throw const FormatException('Document is no longer in the library');
      }
      if (_docx) {
        final Archive archive =
            ZipDecoder().decodeBytes(await File(_path).readAsBytes());
        final ArchiveFile? entry = archive.findFile('word/document.xml');
        if (entry == null) {
          throw const FormatException('This DOCX has no document.xml');
        }
        final String xml = utf8.decode(entry.content as List<int>);
        final Iterable<RegExpMatch> paragraphs = RegExp(
          r'<w:p(?: [^>]*)?>(.*?)</w:p>',
          dotAll: true,
        ).allMatches(xml);
        _text.text = paragraphs
            .map(
              (RegExpMatch paragraph) => RegExp(
                r'<w:t(?: [^>]*)?>(.*?)</w:t>',
                dotAll: true,
              )
                  .allMatches(paragraph.group(1)!)
                  .map((RegExpMatch text) => _unescape(text.group(1)!))
                  .join(),
            )
            .join('\n');
      }
    } on Object catch (error) {
      _error = 'Could not read this document: $error';
    }
    if (mounted) setState(() => _loading = false);
  }

  String _unescape(String value) => value
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");

  String _escape(String value) => const HtmlEscape().convert(value);

  void _applyFormat() {
    final TextSelection selection = _text.selection;
    if (selection.isValid && !selection.isCollapsed) {
      _ranges.add(
        _FormatRange(
          selection.start,
          selection.end,
          _bold,
          _italic,
          _underline,
          _size,
          _color,
        ),
      );
      setState(() {});
    }
  }

  String _props(_FormatRange? range) {
    if (range == null) return '';
    final String color =
        range.color.value.toRadixString(16).substring(2).toUpperCase();
    return '<w:rPr>'
        '${range.bold ? '<w:b/>' : ''}'
        '${range.italic ? '<w:i/>' : ''}'
        '${range.underline ? '<w:u w:val="single"/>' : ''}'
        '<w:sz w:val="${(range.size * 2).round()}"/>'
        '<w:color w:val="$color"/>'
        '</w:rPr>';
  }

  String _paragraphXml(String text, int base) {
    final List<int> cuts = <int>[0, text.length];
    for (final _FormatRange range in _ranges) {
      if (range.end > base && range.start < base + text.length) {
        cuts
          ..add((range.start - base).clamp(0, text.length))
          ..add((range.end - base).clamp(0, text.length));
      }
    }
    cuts.sort();
    final String justification = switch (_align) {
      TextAlign.center => 'center',
      TextAlign.right => 'right',
      TextAlign.justify => 'both',
      _ => 'left',
    };
    final StringBuffer output = StringBuffer(
      '<w:p><w:pPr><w:jc w:val="$justification"/></w:pPr>',
    );
    for (int index = 0; index < cuts.length - 1; index++) {
      final int start = cuts[index];
      final int end = cuts[index + 1];
      if (start == end) continue;
      _FormatRange? format;
      for (final _FormatRange range in _ranges.reversed) {
        if (base + start >= range.start && base + start < range.end) {
          format = range;
          break;
        }
      }
      output.write(
        '<w:r>${_props(format)}<w:t xml:space="preserve">'
        '${_escape(text.substring(start, end))}</w:t></w:r>',
      );
    }
    return '$output</w:p>';
  }

  Future<void> _save() async {
    try {
      final Archive archive =
          ZipDecoder().decodeBytes(await File(_path).readAsBytes());
      final ArchiveFile? old = archive.findFile('word/document.xml');
      if (old == null) throw const FormatException('Missing document.xml');
      int offset = 0;
      final String body = _text.text.split('\n').map((String paragraph) {
        final String xml = _paragraphXml(paragraph, offset);
        offset += paragraph.length + 1;
        return xml;
      }).join();
      final String original = utf8.decode(old.content as List<int>);
      final String replaced = original.replaceFirst(
        RegExp(r'<w:body>.*?</w:body>', dotAll: true),
        '<w:body>$body</w:body>',
      );
      final Archive output = Archive();
      for (final ArchiveFile entry in archive) {
        final Uint8List content = entry.name == 'word/document.xml'
            ? Uint8List.fromList(utf8.encode(replaced))
            : entry.content;
        output.addFile(ArchiveFile(entry.name, content.length, content));
      }
      await File(_path).writeAsBytes(ZipEncoder().encode(output));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to the same DOCX file')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save DOCX: $error')),
        );
      }
    }
  }

  Future<void> _openExternal() async {
    try {
      await const MethodChannel('lexiora/platform').invokeMethod<void>(
        'openWordFile',
        <String, Object?>{
          'path': _path,
          'mime': widget.file?.mimeType ??
              (_path.toLowerCase().endsWith('.docx')
                  ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                  : 'application/msword'),
        },
      );
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'No compatible app installed')),
        );
      }
    }
  }

  void _leave() {
    if (widget.externalLaunch) {
      unawaited(PdfImportService.finishExternalPdf());
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(_error!));
    } else if (!_docx) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Legacy .doc files cannot be edited inside DarsNexa.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openExternal,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in Word/Docs'),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _tool(
                  Icons.format_bold,
                  () {
                    setState(() => _bold = !_bold);
                    _applyFormat();
                  },
                  _bold,
                ),
                _tool(
                  Icons.format_italic,
                  () {
                    setState(() => _italic = !_italic);
                    _applyFormat();
                  },
                  _italic,
                ),
                _tool(
                  Icons.format_underline,
                  () {
                    setState(() => _underline = !_underline);
                    _applyFormat();
                  },
                  _underline,
                ),
                DropdownButton<double>(
                  value: _size,
                  items: <double>[10, 11, 12, 14, 16, 18, 24, 32]
                      .map(
                        (double size) => DropdownMenuItem<double>(
                          value: size,
                          child: Text('${size.toInt()}'),
                        ),
                      )
                      .toList(),
                  onChanged: (double? size) {
                    if (size != null) {
                      setState(() => _size = size);
                      _applyFormat();
                    }
                  },
                ),
                _tool(
                  Icons.format_color_text,
                  () {
                    setState(
                      () => _color =
                          _color == Colors.black ? Colors.red : Colors.black,
                    );
                    _applyFormat();
                  },
                  false,
                  color: _color,
                ),
                _tool(
                  Icons.format_align_left,
                  () => setState(() => _align = TextAlign.left),
                  false,
                ),
                _tool(
                  Icons.format_align_center,
                  () => setState(() => _align = TextAlign.center),
                  false,
                ),
                _tool(
                  Icons.format_align_right,
                  () => setState(() => _align = TextAlign.right),
                  false,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _text,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlign: _align,
                style: TextStyle(
                  fontSize: _size,
                  fontWeight: _bold ? FontWeight.bold : null,
                  fontStyle: _italic ? FontStyle.italic : null,
                  decoration:
                      _underline ? TextDecoration.underline : null,
                  color: _color,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Edit document text',
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: OutlinedButton.icon(
                onPressed: _openExternal,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in installed app'),
              ),
            ),
          ),
        ],
      );
    }

    return PopScope(
      canPop: !widget.externalLaunch,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_name),
          actions: <Widget>[
            if (_docx && !_loading)
              IconButton(onPressed: _save, icon: const Icon(Icons.save)),
          ],
        ),
        body: body,
      ),
    );
  }

  Widget _tool(
    IconData icon,
    VoidCallback onPressed,
    bool active, {
    Color? color,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: color ??
            (active ? Theme.of(context).colorScheme.primary : null),
      ),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }
}

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

class _TableModel {
  _TableModel(this.token, this.rows, this.columns, this.cells);

  final String token;
  final int rows;
  final int columns;
  final List<List<String>> cells;
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
  final List<_TableModel> _tables = <_TableModel>[];
  int _nextTableId = 1;
  final List<String> _undoStack = <String>[];
  final List<String> _redoStack = <String>[];
  LibraryDocument? _document;
  bool _loading = true;
  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  double _size = 11;
  Color _color = Colors.black;
  TextAlign _align = TextAlign.left;
  String? _error;
  String _lastText = '';
  bool _restoringText = false;

  bool get _docx {
    final String fileName =
        (_document?.fileName ?? widget.file?.name ?? '').toLowerCase();
    final String path = (_document?.filePath ?? widget.file?.path ?? '').toLowerCase();
    // Auto-discovered Android files can have a display name without an
    // extension in the database, while the actual path still has .docx.
    return fileName.endsWith('.docx') || path.endsWith('.docx');
  }
  String get _path => _document?.filePath ?? widget.file!.path;
  String get _name => _document?.fileName ?? widget.file!.name;

  @override
  void initState() {
    super.initState();
    _text.addListener(_recordTextChange);
    _load();
  }

  void _recordTextChange() {
    if (_restoringText || _text.text == _lastText) return;
    _undoStack.add(_lastText);
    _redoStack.clear();
    _lastText = _text.text;
    if (mounted) setState(() {});
  }

  void _setEditorText(String value) {
    _restoringText = true;
    _text.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _lastText = value;
    _restoringText = false;
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_text.text);
    final String value = _undoStack.removeLast();
    _setEditorText(value);
    setState(() {});
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_text.text);
    final String value = _redoStack.removeLast();
    _setEditorText(value);
    setState(() {});
  }

  Future<void> _findAndReplace() async {
    final TextEditingController find = TextEditingController();
    final TextEditingController replace = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Find and replace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: find,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Find'),
            ),
            TextField(
              controller: replace,
              decoration: const InputDecoration(labelText: 'Replace with'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final String query = find.text;
              if (query.isEmpty) return;
              final int count = query.allMatches(_text.text).length;
              _undoStack.add(_text.text);
              _redoStack.clear();
              _setEditorText(_text.text.replaceAll(query, replace.text));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$count occurrence(s) replaced')),
              );
            },
            child: const Text('Replace all'),
          ),
        ],
      ),
    );
    find.dispose();
    replace.dispose();
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
      if (!_docx && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_openExternal());
          }
        });
      }
      if (_docx) {
        final Archive archive =
            ZipDecoder().decodeBytes(await File(_path).readAsBytes());
        final ArchiveFile? entry = archive.findFile('word/document.xml');
        if (entry == null) {
          throw const FormatException('This DOCX has no document.xml');
        }
        final String xml = utf8.decode(entry.content as List<int>);
        final Iterable<RegExpMatch> blocks = RegExp(
          r'<w:p(?: [^>]*)?>.*?</w:p>|<w:tbl>.*?</w:tbl>',
          dotAll: true,
        ).allMatches(xml);
        final List<String> loadedParagraphs = <String>[];
        for (final RegExpMatch block in blocks) {
          final String content = block.group(0)!;
          final RegExpMatch? table = RegExp(r'<w:tbl>(.*?)</w:tbl>', dotAll: true).firstMatch(content);
          if (table != null) {
            final List<List<String>> cells = RegExp(r'<w:tr>(.*?)</w:tr>', dotAll: true)
                .allMatches(table.group(1)!)
                .map((RegExpMatch row) => RegExp(r'<w:tc(?: [^>]*)?>(.*?)</w:tc>', dotAll: true)
                    .allMatches(row.group(1)!)
                    .map((RegExpMatch cell) => RegExp(r'<w:t(?: [^>]*)?>(.*?)</w:t>', dotAll: true)
                        .allMatches(cell.group(1)!)
                        .map((RegExpMatch text) => _unescape(text.group(1)!))
                        .join())
                    .toList())
                .toList();
            final int rows = cells.isEmpty ? 1 : cells.length;
            final int columns = cells.isEmpty ? 1 : cells.map((List<String> row) => row.length).fold<int>(1, (int a, int b) => a > b ? a : b);
            final String token = _newTableToken();
            _tables.add(_TableModel(token, rows, columns, cells));
            loadedParagraphs.add(token);
          } else {
            loadedParagraphs.add(RegExp(r'<w:t(?: [^>]*)?>(.*?)</w:t>', dotAll: true)
                .allMatches(content)
                .map((RegExpMatch text) => _unescape(text.group(1)!))
                .join());
          }
        }
        _setEditorText(loadedParagraphs.join('\n'));
      }
    } on Object catch (error) {
      _error = 'Could not read this document: $error';
    }
    if (mounted) setState(() => _loading = false);
  }

  String _newTableToken() => '\uFFFCTABLE${_nextTableId++}\uFFFC';

  bool _isBullet(String paragraph) => paragraph.startsWith('• ');
  bool _isNumbered(String paragraph) => RegExp(r'^\d+\. ').hasMatch(paragraph);
  String _plainListText(String paragraph) => paragraph.replaceFirst(RegExp(r'^(?:• |\d+\. )'), '');

  void _toggleList({required bool numbered}) {
    final String value = _text.text;
    final TextSelection selection = _text.selection;
    final int start = selection.isValid ? value.lastIndexOf('\n', selection.start - 1) + 1 : 0;
    final int endBreak = selection.isValid ? value.indexOf('\n', selection.end) : -1;
    final int end = endBreak < 0 ? value.length : endBreak;
    final List<String> lines = value.substring(start, end).split('\n');
    int number = 1;
    final List<String> updated = lines.map((String line) {
      final String plain = _plainListText(line);
      if (numbered) return '${number++}. $plain';
      return '• $plain';
    }).toList();
    _setEditorText(value.substring(0, start) + updated.join('\n') + value.substring(end));
    setState(() {});
  }

  void _insertBlankPage() {
    final String value = _text.text;
    final int offset =
        _text.selection.isValid ? _text.selection.end : value.length;
    const int pageLines = 36;
    final String blankPage = List<String>.filled(pageLines, '').join('\n');
    final String prefix = value.substring(0, offset);
    final String suffix = value.substring(offset);
    final String next = '$prefix\n$blankPage\n$suffix';
    _restoringText = true;
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset: prefix.length + 1 + blankPage.length + 1,
      ),
    );
    _lastText = next;
    _restoringText = false;
    setState(() {});
  }

  Future<void> _insertTable() async {
    final TextEditingController rows = TextEditingController(text: '2');
    final TextEditingController columns = TextEditingController(text: '2');
    final int? dimensions = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Insert table'),
        content: Row(children: <Widget>[
          Expanded(child: TextField(controller: rows, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rows'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: columns, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Columns'))),
        ]),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final int rowCount = int.tryParse(rows.text) ?? 0;
            final int columnCount = int.tryParse(columns.text) ?? 0;
            if (rowCount >= 1 && rowCount <= 20 && columnCount >= 1 && columnCount <= 10) {
              Navigator.of(dialogContext).pop(rowCount * 100 + columnCount);
            }
          }, child: const Text('Insert')),
        ],
      ),
    );
    rows.dispose();
    columns.dispose();
    if (dimensions == null) return;
    final int rowCount = dimensions ~/ 100;
    final int columnCount = dimensions % 100;
    final String token = _newTableToken();
    // Keep the table model constructor expanded to avoid parser ambiguity in CI builds.
    _tables.add(
      _TableModel(
        token,
        rowCount,
        columnCount,
        List<List<String>>.generate(
          rowCount,
          (_) => List<String>.filled(columnCount, ''),
        ),
      ),
    );
    final String value = _text.text;
    final int offset = _text.selection.isValid ? _text.selection.end : value.length;
    final int lineEnd = value.indexOf('\n', offset);
    final int insertAt = lineEnd < 0 ? value.length : lineEnd;
    final String prefix = value.substring(0, insertAt);
    final String suffix = value.substring(insertAt);
    _setEditorText('$prefix\n$token$suffix');
    setState(() {});
  }

  Widget _tableSurface() {
    if (_tables.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _tables.length,
        itemBuilder: (BuildContext context, int tableIndex) {
          final _TableModel table = _tables[tableIndex];
          return Card(child: Padding(padding: const EdgeInsets.all(8), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Table ${tableIndex + 1} (${table.rows} × ${table.columns})', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              for (int row = 0; row < table.rows; row++) Row(children: <Widget>[
                for (int column = 0; column < table.columns; column++) Expanded(child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: TextFormField(
                    initialValue: row < table.cells.length && column < table.cells[row].length ? table.cells[row][column] : '',
                    onChanged: (String text) => table.cells[row][column] = text,
                    decoration: InputDecoration(isDense: true, hintText: 'Cell ${row + 1},${column + 1}', border: const OutlineInputBorder()),
                  ),
                )),
              ]),
            ],
          )));
        },
      ),
    );
  }

  _TableModel? _tableForToken(String token) {
    for (final _TableModel table in _tables) {
      if (table.token == token) return table;
    }
    return null;
  }

  String _tableXml(_TableModel table) {
    final StringBuffer output = StringBuffer('<w:tbl><w:tblPr><w:tblBorders>'
        '<w:top w:val="single" w:sz="4" w:space="0" w:color="B7C3D0"/>'
        '<w:left w:val="single" w:sz="4" w:space="0" w:color="B7C3D0"/>'
        '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="B7C3D0"/>'
        '<w:right w:val="single" w:sz="4" w:space="0" w:color="B7C3D0"/>'
        '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="B7C3D0"/>'
        '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="B7C3D0"/>'
        '</w:tblBorders></w:tblPr>');
    for (int row = 0; row < table.rows; row++) {
      output.write('<w:tr>');
      for (int column = 0; column < table.columns; column++) {
        final String value = row < table.cells.length && column < table.cells[row].length ? table.cells[row][column] : '';
        output.write('<w:tc><w:p><w:r><w:t xml:space="preserve">${_escape(value)}</w:t></w:r></w:p></w:tc>');
      }
      output.write('</w:tr>');
    }
    return '$output</w:tbl>';
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

  String _paragraphXml(String text, int base, {int? number}) {
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
    final StringBuffer output = StringBuffer('<w:p><w:pPr><w:jc w:val="$justification"/>'
        '${number == null ? '' : '<w:numPr><w:ilvl w:val="0"/><w:numId w:val="$number"/></w:numPr>'}'
        '</w:pPr>');
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
      final List<String> parts = <String>[];
      final List<String> paragraphs = _text.text.split('\n');
      for (int index = 0; index < paragraphs.length; index++) {
        final String paragraph = paragraphs[index];
        if (paragraph.isEmpty &&
            index + 30 < paragraphs.length &&
            paragraphs.skip(index).take(30).every((String p) => p.isEmpty)) {
          parts.add('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
          while (index + 1 < paragraphs.length &&
              paragraphs[index + 1].isEmpty) {
            index++;
          }
          offset += 1;
          continue;
        }
        final _TableModel? table = _tableForToken(paragraph);
        if (table != null) {
          parts.add(_tableXml(table));
        } else {
          final int? numId =
              _isBullet(paragraph) ? 1 : _isNumbered(paragraph) ? 2 : null;
          parts.add(
            _paragraphXml(
              _plainListText(paragraph),
              offset,
              number: numId,
            ),
          );
          offset += paragraph.length + 1;
        }
      }
      final String body = parts.join();
      final String original = utf8.decode(old.content as List<int>);
      final RegExp bodyPattern = RegExp(r'<w:body>(.*?)</w:body>', dotAll: true);
      final RegExpMatch? bodyMatch = bodyPattern.firstMatch(original);
      if (bodyMatch == null) throw const FormatException('Missing document body');
      final String bodyTail = RegExp(r'<w:sectPr.*?</w:sectPr>', dotAll: true).firstMatch(bodyMatch.group(1) ?? '')?.group(0) ?? '';
      final String replaced = original.replaceFirst(bodyPattern, '<w:body>$body$bodyTail</w:body>');
      final Archive output = Archive();
      for (final ArchiveFile entry in archive) {
        Uint8List content = entry.name == 'word/document.xml' ? Uint8List.fromList(utf8.encode(replaced)) : entry.content;
        if (entry.name == '[Content_Types].xml') {
          final String types = utf8.decode(content);
          if (!types.contains('/word/numbering.xml')) {
            content = Uint8List.fromList(utf8.encode(types.replaceFirst('</Types>', '<Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/></Types>')));
          }
        }
        if (entry.name == 'word/_rels/document.xml.rels') {
          final String rels = utf8.decode(content);
          if (!rels.contains('/word/numbering.xml')) {
            content = Uint8List.fromList(utf8.encode(rels.replaceFirst('</Relationships>', '<Relationship Id="rIdLexioraNumbering" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/></Relationships>')));
          }
        }
        output.addFile(ArchiveFile(entry.name, content.length, content));
      }
      if (archive.findFile('word/numbering.xml') == null) {
        const String numbering = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:abstractNum w:abstractNumId="0"><w:multiLevelType w:val="singleLevel"/><w:lvl w:ilvl="0"><w:numFmt w:val="bullet"/><w:lvlText w:val="•"/><w:start w:val="1"/></w:lvl></w:abstractNum><w:abstractNum w:abstractNumId="1"><w:multiLevelType w:val="singleLevel"/><w:lvl w:ilvl="0"><w:numFmt w:val="decimal"/><w:lvlText w:val="%1."/><w:start w:val="1"/></w:lvl></w:abstractNum><w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num><w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num></w:numbering>';
        output.addFile(ArchiveFile('word/numbering.xml', numbering.length, Uint8List.fromList(utf8.encode(numbering))));
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
      body = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Opening in Word/Docs…'),
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
                _tool(Icons.undo, _undo, _undoStack.isNotEmpty),
                _tool(Icons.redo, _redo, _redoStack.isNotEmpty),
                _tool(Icons.find_replace, _findAndReplace, false),
                _tool(Icons.format_list_bulleted, () => _toggleList(numbered: false), false),
                _tool(Icons.format_list_numbered, () => _toggleList(numbered: true), false),
                _tool(Icons.table_chart, _insertTable, false),
                _tool(Icons.note_add, _insertBlankPage, false),
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
          _tableSurface(),
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
    _text.removeListener(_recordTextChange);
    _text.dispose();
    super.dispose();
  }
}

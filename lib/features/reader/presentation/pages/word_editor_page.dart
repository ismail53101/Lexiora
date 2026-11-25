import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/pdf_import_service.dart';
import 'package:lexiora/core/services/pdf_discovery_service.dart' show DeviceFile;
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/repositories/library_repository.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

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

class _WordEditorPageState extends State<WordEditorPage> {
  late final WordEditorController _controller;
  LibraryDocument? _document;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  bool get _docx {
    final String fileName =
        (_document?.fileName ?? widget.file?.name ?? '').toLowerCase();
    final String path =
        (_document?.filePath ?? widget.file?.path ?? '').toLowerCase();
    return fileName.endsWith('.docx') || path.endsWith('.docx');
  }

  String get _path => _document?.filePath ?? widget.file!.path;
  String get _name => _document?.fileName ?? widget.file!.name;

  @override
  void initState() {
    super.initState();
    _controller = WordEditorController(
      config: const OfficeSurfaceConfig(
        mode: OfficeInteractionMode.editing,
        textDirection: TextDirection.ltr,
        strings: OfficeStrings.english,
        theme: OfficeTheme.light,
        showRulers: false,
        showFormulaBar: false,
        showGridlines: false,
        showSlideHandles: false,
        showFindChrome: false,
        showNotesPane: false,
        showNavigationPane: false,
        enableUndo: true,
      ),
    );
    _controller.addListener(_onControllerChanged);
    unawaited(_load());
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
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
        final Uint8List bytes = await File(_path).readAsBytes();
        // Open synchronously so the live controller receives the exact WML
        // tree (including floating text boxes/pictures) before the first
        // pagination pass. This is important for Word files whose first page
        // is composed from anchored objects.
        // Use the editor's asynchronous OOXML loader so the complete Word
        // package is parsed before we touch pagination/layout.
        await _controller.loadBytesAsync(_prepareDocxBytes(bytes));
        _normalizeImportedWordLayout();
        // fitPaintMetrics() already re-lays out and then applies the same
        // Flutter font metrics used by the canvas. Do not call relayout()
        // afterwards, because that would discard the fitted paint metrics.
        _controller.fitPaintMetrics();
        _controller.refresh();
        _controller.markClean();
        // Library DOCX files should open in the installed Word-compatible app
        // for faithful page layout. Keep this parsed editor underneath as a
        // fallback if the external app cannot be launched or returns to DarsNexa.
        if (widget.documentId != null && !widget.externalLaunch) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_openExternal());
          });
        }
      } else if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_openExternal());
        });
      }
    } on Object catch (error) {
      _error = 'Could not open this Word document: $error';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final Uint8List bytes = await _controller.saveBytesAsync();
      await File(_path).writeAsBytes(bytes, flush: true);
      _controller.markClean();
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
    } finally {
      if (mounted) setState(() => _saving = false);
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

  Uint8List _prepareDocxBytes(Uint8List bytes) {
    // Word stores DrawingML text boxes in mc:Choice and an identical VML
    // copy in mc:Fallback. The current Quds importer can see both branches,
    // which makes the same text box appear twice. Keep the preferred
    // DrawingML branch and remove only the redundant fallback from the
    // document story before handing the package to the editor.
    final Archive archive = ZipDecoder().decodeBytes(bytes);
    final ArchiveFile? document = archive.findFile('word/document.xml');
    if (document == null || !document.isFile) return bytes;

    final String xml = String.fromCharCodes(document.content);
    if (!xml.contains('<mc:Fallback>')) return bytes;
    final String cleaned = xml.replaceAll(
      RegExp(r'<mc:Fallback>[\s\S]*?</mc:Fallback>'),
      '',
    );
    if (cleaned == xml) return bytes;

    final Uint8List cleanedBytes = Uint8List.fromList(cleaned.codeUnits);
    final CompressionType? compression = document.compression;
    archive.removeFile(document);
    final ArchiveFile replacement = ArchiveFile(
      'word/document.xml',
      cleanedBytes.length,
      cleanedBytes,
    )..compression = compression;
    archive.addFile(replacement);
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  void _normalizeImportedWordLayout() {
    // The first five paragraphs of this assignment are Word text-box hosts.
    // Quds applies list/style geometry to those hosts even though their
    // visible content is positioned by floating text boxes. Clear only this
    // cover/form area; real bullet lists later in the document must remain
    // intact.
    final List<WmlParagraph> paragraphs = _controller.document.paragraphs.toList();
    for (final WmlParagraph paragraph in paragraphs.take(5)) {
      paragraph.properties
        ..numId = null
        ..ilvl = 0
        ..listLabel = null
        ..indent = const WmlIndent();
    }

    // Quds currently uses paragraph alignment when calculating the origin of
    // anchored text boxes. Word's anchors are relative to the page/column and
    // must not inherit the centered Title paragraph's text origin.
    if (paragraphs.isNotEmpty && paragraphs.first.properties.styleId == 'Title') {
      paragraphs.first.properties.justification = WmlJustification.left;
    }
  }

  bool _looksLikeFormParagraph(String text) {
    final String lower = text.toLowerCase();
    const List<String> labels = <String>[
      'student name',
      'roll no',
      'semester',
      'department',
      'course',
      'teacher',
      'submission date',
      'sub title',
    ];
    final int matches = labels.where(lower.contains).length;
    return matches >= 2;
  }

  void _insertTable() {
    final TextEditingController rows = TextEditingController(text: '2');
    final TextEditingController columns = TextEditingController(text: '2');
    showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Insert table'),
        content: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: rows,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Rows'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: columns,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Columns'),
              ),
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
              final int r = int.tryParse(rows.text) ?? 0;
              final int c = int.tryParse(columns.text) ?? 0;
              if (r >= 1 && r <= 20 && c >= 1 && c <= 10) {
                Navigator.of(dialogContext).pop(r * 100 + c);
              }
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    ).then((int? value) {
      rows.dispose();
      columns.dispose();
      if (value == null) return;
      _controller.insertTable(rows: value ~/ 100, columns: value % 100);
    });
  }

  void _insertBlankPage() => _controller.insertPageBreak();

  void _applyRun(void Function(WmlRunProps props) update) {
    _controller.applyRunFormat(update);
  }

  void _applyParagraph(void Function(WmlParagraphProps props) update) {
    _controller.applyParagraphFormat(update);
  }

  Widget _icon(
    IconData icon,
    VoidCallback action, {
    String? tooltip,
    bool active = false,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: action,
      color: active ? Theme.of(context).colorScheme.primary : null,
      icon: Icon(icon),
    );
  }

  int get _zoomPercent => (_controller.viewport.scale * 100).round();

  void _setZoom(double value) {
    final double clamped = value.clamp(0.5, 2.0).toDouble();
    _controller.viewport.setScale(clamped);
    _controller.refresh();
    if (mounted) setState(() {});
  }

  Widget _toolbar() {
    final WmlRunProps run = _controller.activeRunProps;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _icon(Icons.undo, _controller.undo, tooltip: 'Undo', active: _controller.canUndo),
            _icon(Icons.redo, _controller.redo, tooltip: 'Redo', active: _controller.canRedo),
            _icon(Icons.search, _controller.requestFind, tooltip: 'Find'),
            _icon(Icons.format_bold, () => _applyRun((WmlRunProps p) => p.bold = !p.bold), active: run.bold),
            _icon(Icons.format_italic, () => _applyRun((WmlRunProps p) => p.italic = !p.italic), active: run.italic),
            _icon(
              Icons.format_underlined,
              () => _applyRun(
                (WmlRunProps p) => p.underline =
                    p.underline == WmlUnderline.none
                        ? WmlUnderline.single
                        : WmlUnderline.none,
              ),
              active: run.underline != WmlUnderline.none,
            ),
            PopupMenuButton<int>(
              tooltip: 'Text size',
              icon: Text('${run.fontSizePoints.round()}', style: const TextStyle(fontWeight: FontWeight.w600)),
              onSelected: (int size) => _applyRun((WmlRunProps p) => p.fontSizeHalfPoints = size * 2),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                for (final int size in <int>[10, 11, 12, 14, 16, 18, 20, 24, 28, 32])
                  PopupMenuItem<int>(value: size, child: Text('$size pt')),
              ],
            ),
            PopupMenuButton<String>(
              tooltip: 'Text color',
              icon: Icon(Icons.format_color_text, color: _hexColor(run.color)),
              onSelected: (String value) => _applyRun((WmlRunProps p) => p.color = value),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                for (final String value in <String>['000000','D32F2F','1976D2','388E3C','F57C00','7B1FA2','00838F'])
                  PopupMenuItem<String>(
                    value: value,
                    child: Row(children: <Widget>[
                      Icon(Icons.circle, color: _hexColor(value), size: 18),
                      const SizedBox(width: 10),
                      Text(value),
                    ]),
                  ),
              ],
            ),
            PopupMenuButton<String?>(
              tooltip: 'Highlight',
              icon: Icon(Icons.highlight, color: run.highlight == null ? null : _hexColor(run.highlight!)),
              onSelected: (String? value) => _applyRun((WmlRunProps p) => p.highlight = value),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String?>>[
                const PopupMenuItem<String?>(value: null, child: Text('No highlight')),
                for (final String value in <String>['FFFF00','FFCC80','B3E5FC','C8E6C9','E1BEE7','FFCDD2'])
                  PopupMenuItem<String?>(
                    value: value,
                    child: Row(children: <Widget>[
                      Icon(Icons.highlight, color: _hexColor(value)),
                      const SizedBox(width: 10),
                      const Text('Highlight'),
                    ]),
                  ),
              ],
            ),
            PopupMenuButton<int>(
              tooltip: 'Heading',
              icon: const Icon(Icons.title),
              onSelected: (int level) => _controller.applyHeading(level),
              itemBuilder: (BuildContext context) => const <PopupMenuEntry<int>>[
                PopupMenuItem<int>(value: 1, child: Text('Heading 1')),
                PopupMenuItem<int>(value: 2, child: Text('Heading 2')),
                PopupMenuItem<int>(value: 3, child: Text('Heading 3')),
              ],
            ),
            _icon(Icons.format_list_bulleted, () => _controller.applyList(numbered: false), tooltip: 'Bullets'),
            _icon(Icons.format_list_numbered, () => _controller.applyList(numbered: true), tooltip: 'Numbered list'),
            _icon(Icons.table_chart, _insertTable, tooltip: 'Insert table'),
            _icon(Icons.note_add, _insertBlankPage, tooltip: 'New blank page'),
            _icon(Icons.format_align_left, () => _applyParagraph((WmlParagraphProps p) => p.justification = WmlJustification.left), tooltip: 'Align left'),
            _icon(Icons.format_align_center, () => _applyParagraph((WmlParagraphProps p) => p.justification = WmlJustification.center), tooltip: 'Align center'),
            _icon(Icons.format_align_right, () => _applyParagraph((WmlParagraphProps p) => p.justification = WmlJustification.right), tooltip: 'Align right'),
            _icon(Icons.format_align_justify, () => _applyParagraph((WmlParagraphProps p) => p.justification = WmlJustification.justify), tooltip: 'Justify'),
            const VerticalDivider(width: 16, indent: 8, endIndent: 8),
            _icon(
              Icons.zoom_out,
              () => _setZoom(_controller.viewport.scale - 0.1),
              tooltip: 'Zoom out',
            ),
            IconButton(
              tooltip: 'Reset zoom',
              onPressed: () => _setZoom(1.0),
              icon: Text(
                '$_zoomPercent%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _icon(
              Icons.zoom_in,
              () => _setZoom(_controller.viewport.scale + 0.1),
              tooltip: 'Zoom in',
            ),
          ],
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    final String value = hex.replaceAll('#', '').padLeft(6, '0');
    final int? rgb = int.tryParse(value.substring(value.length - 6), radix: 16);
    return rgb == null ? Colors.black : Color(0xFF000000 | rgb);
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
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)));
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
      body = QudsWordEditor(
        controller: _controller,
        toolbarBuilder: (BuildContext context, WordEditorController controller) => _toolbar(),
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
              IconButton(
                tooltip: 'Save',
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
              ),
          ],
        ),
        body: body,
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }
}

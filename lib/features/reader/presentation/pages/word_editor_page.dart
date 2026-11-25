import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:archive/archive.dart';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/pdf_import_service.dart';
import 'package:lexiora/core/services/pdf_discovery_service.dart' show DeviceFile;
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/repositories/library_repository.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

/// Formatting chosen while the caret is collapsed (no selection). Like Word, it
/// is applied to the text typed next instead of the whole word/run.
class _TypingStyle {
  bool? bold;
  bool? italic;
  bool? underline;
  int? sizeHalf;
  String? color;
  String? highlight;
  bool highlightSet = false;

  bool get isEmpty =>
      bold == null &&
      italic == null &&
      underline == null &&
      sizeHalf == null &&
      color == null &&
      !highlightSet;

  void clear() {
    bold = null;
    italic = null;
    underline = null;
    sizeHalf = null;
    color = null;
    highlight = null;
    highlightSet = false;
  }

  void apply(WmlRunProps p) {
    if (bold != null) p.bold = bold!;
    if (italic != null) p.italic = italic!;
    if (underline != null) {
      p.underline = underline! ? WmlUnderline.single : WmlUnderline.none;
    }
    if (sizeHalf != null) p.fontSizeHalfPoints = sizeHalf!;
    if (color != null) p.color = color!;
    if (highlightSet) p.highlight = highlight;
  }
}

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
  final Map<int, Offset> _touchPositions = <int, Offset>{};
  final Map<int, bool> _touchMoved = <int, bool>{};
  static const double _scrollGestureSlop = 8.0;

  // "Phone view" (like WPS mobile view): every section is temporarily made as
  // wide as the screen so the text re-wraps to the phone. The original page
  // geometry is restored before saving, so the .docx layout is never changed.
  bool _phoneView = true;
  bool _editing = false;
  final _TypingStyle _typing = _TypingStyle();
  bool _applyingTyping = false;
  int _snapPara = 0;
  int _snapLen = 0;
  int _snapCaret = 0;
  bool _pinching = false;
  List<WmlPageSize>? _origSizes;
  List<WmlPageMargins>? _origMargins;
  static const double _phoneScale = 0.8;
  static const double _wordInitialScale = 0.8;
  bool _initializingViewport = false;

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
        // Start read-only: touching/scrolling must never open the keyboard.
        // Editing is switched on explicitly with the Edit button.
        mode: OfficeInteractionMode.viewing,
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
    _trackTyping();
    if (mounted) setState(() {});
  }

  List<WmlParagraph> get _paras => _controller.document.paragraphs.toList();

  void _snapshotTyping() {
    final List<WmlParagraph> paras = _paras;
    if (paras.isEmpty) return;
    final CaretEngine c = _controller.caret;
    _snapPara = c.paragraphIndex.clamp(0, paras.length - 1);
    _snapLen = paras[_snapPara].text.length;
    _snapCaret = c.logicalIndex;
  }

  /// Applies the pending typing style to text that was just typed.
  void _trackTyping() {
    if (_typing.isEmpty || _applyingTyping || !_editing) return;
    final List<WmlParagraph> paras = _paras;
    if (paras.isEmpty) return;
    final CaretEngine c = _controller.caret;
    if (!c.isCollapsed) {
      _typing.clear();
      return;
    }
    final int pi = c.paragraphIndex.clamp(0, paras.length - 1);
    final int len = paras[pi].text.length;
    final int grew = len - _snapLen;
    if (pi == _snapPara && grew > 0 && c.logicalIndex == _snapCaret + grew) {
      final int from = _snapCaret;
      final int to = c.logicalIndex;
      _applyingTyping = true;
      try {
        c.selectionAnchorParagraph = pi;
        c.selectionAnchor = from;
        c.logicalIndex = to;
        _controller.applyRunFormat(_typing.apply);
        c.logicalIndex = to;
        c.collapseSelection();
      } finally {
        _applyingTyping = false;
      }
      _snapshotTyping();
      return;
    }
    if (pi == _snapPara && len == _snapLen && c.logicalIndex == _snapCaret) {
      return;
    }
    // Caret moved elsewhere or text was deleted: forget the pending style.
    _typing.clear();
  }

  /// Formats the selection, or (with no selection) the text typed next.
  void _formatRun({
    required void Function(WmlRunProps p) update,
    required void Function(_TypingStyle t) remember,
  }) {
    if (!_editing) return;
    if (_controller.caret.isCollapsed) {
      remember(_typing);
      _snapshotTyping();
      if (mounted) setState(() {});
    } else {
      _controller.applyRunFormat(update);
    }
  }

  bool get _boldNow => _typing.bold ?? _controller.activeRunProps.bold;
  bool get _italicNow => _typing.italic ?? _controller.activeRunProps.italic;
  bool get _underNow =>
      _typing.underline ??
      (_controller.activeRunProps.underline != WmlUnderline.none);
  int get _sizeHalfNow =>
      _typing.sizeHalf ?? _controller.activeRunProps.fontSizeHalfPoints;

  void _toggleBold() {
    final bool next = !_boldNow;
    _formatRun(update: (WmlRunProps p) => p.bold = next, remember: (_TypingStyle t) => t.bold = next);
  }

  void _toggleItalic() {
    final bool next = !_italicNow;
    _formatRun(update: (WmlRunProps p) => p.italic = next, remember: (_TypingStyle t) => t.italic = next);
  }

  void _toggleUnderline() {
    final bool next = !_underNow;
    _formatRun(
      update: (WmlRunProps p) =>
          p.underline = next ? WmlUnderline.single : WmlUnderline.none,
      remember: (_TypingStyle t) => t.underline = next,
    );
  }

  void _setSize(int points) {
    final int half = points.clamp(6, 96) * 2;
    _formatRun(update: (WmlRunProps p) => p.fontSizeHalfPoints = half, remember: (_TypingStyle t) => t.sizeHalf = half);
  }

  void _stepSize(int delta) => _setSize((_sizeHalfNow / 2).round() + delta);

  void _setColor(String hex) => _formatRun(update: (WmlRunProps p) => p.color = hex, remember: (_TypingStyle t) => t.color = hex);

  void _setHighlight(String? hex) => _formatRun(
        update: (WmlRunProps p) => p.highlight = hex,
        remember: (_TypingStyle t) {
          t.highlight = hex;
          t.highlightSet = true;
        },
      );

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
        final bool blankNew = _document?.isManaged == true && bytes.length < 3000;
        await _controller.loadBytesAsync(_prepareDocxBytes(bytes));
        if (blankNew) {
          // New Assignment opens as a normal Word-like A4 page in view mode.
          // Do not enter editing/IME automatically; the first deliberate tap
          // on the document can enter editing and show the keyboard.
          _editing = false;
          _phoneView = false;
        }
        _normalizeImportedWordLayout();
        // fitPaintMetrics() already re-lays out and then applies the same
        // Flutter font metrics used by the canvas. Do not call relayout()
        // afterwards, because that would discard the fitted paint metrics.
        _controller.fitPaintMetrics();
        _controller.refresh();
        _controller.markClean();
        // Keep the real Word page geometry. Fit-to-width (≈27% on a phone)
        // makes 11/12pt text look microscopic and removes the useful horizontal
        // pan range. Start at a readable Word-like zoom instead.
        _phoneView = false;
        _initializingViewport = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _setGeometry(phone: false);
          _controller.relayout();
          _controller.fitPaintMetrics();
          _controller.viewport.setScale(_wordInitialScale);
          _controller.viewport.origin = Offset.zero;
          _controller.refresh();
          _initializingViewport = false;
          if (_editing) _controller.setMode(OfficeInteractionMode.editing);
          if (mounted) setState(() => _loading = false);
        });
      } else if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_openExternal());
        });
      }
    } on Object catch (error) {
      _error = 'Could not open this Word document: $error';
    }
    // For DOCX, loading is completed by the post-frame viewport setup above.
    if (mounted && !_docx && !_initializingViewport) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final bool wasPhone = _phoneView;
    try {
      // Put the real page size/margins back so the saved file is unchanged.
      if (wasPhone) _setGeometry(phone: false);
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
      if (wasPhone) _applyPhoneView(true);
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
      _afterTableInserted(value % 100);
    });
  }

  void _afterTableInserted(int columns) {
    try {
      final ({WmlTable table, int row, int col})? loc = _controller.tableAtCaret;
      final List<WmlSection> sections = _controller.document.sections;
      if (loc != null && sections.isNotEmpty) {
        final WmlSection sec = sections.first;
        final double content =
            sec.pageSize.width - sec.margins.left - sec.margins.right - 4;
        final double each = (content / columns).clamp(24.0, 400.0).toDouble();
        for (int i = 0; i < loc.table.grid.length; i++) {
          loc.table.grid[i] = each;
        }
      }
      // A table must never be the last block, or nothing can be typed below it.
      final List<WmlBlock> blocks = sections.last.blocks;
      if (blocks.isNotEmpty && blocks.last is WmlTable) {
        blocks.add(WmlParagraph(inlines: <WmlInline>[WmlRun()]));
      }
      _controller.relayout();
      _controller.fitPaintMetrics();
      _controller.refresh();
    } on Object {
      // Table is still inserted; only the auto-fit was skipped.
    }
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
    final double clamped = value.clamp(0.25, 2.0).toDouble();
    _controller.viewport.setScale(clamped);
    _controller.viewport.origin = Offset(
      math.max(0, _controller.viewport.origin.dx),
      math.max(0, _controller.viewport.origin.dy),
    );
    _controller.refresh();
    if (mounted) setState(() {});
  }

  // Quds paints 64px gutters on both sides of a page. In phone view the editor
  // is laid out (w + 142) wide and shifted left by 64, so the page fills the
  // screen edge to edge and the gutters/scrollbar fall outside the clip.
  static const double _editorExtra = 64.0 * 2 + 14.0;

  void _setGeometry({required bool phone}) {
    final List<WmlSection> sections = _controller.document.sections;
    _origSizes ??= <WmlPageSize>[for (final WmlSection s in sections) s.pageSize];
    _origMargins ??=
        <WmlPageMargins>[for (final WmlSection s in sections) s.margins];
    final double screen = MediaQuery.sizeOf(context).width;
    final double scale = _controller.viewport.scale;
    // +1px so the page is pinned to the left gutter (never re-centred).
    final double pagePt = ((screen + 1.0) * 72.0 / 96.0) / scale;
    for (int i = 0; i < sections.length; i++) {
      if (i >= _origSizes!.length) break;
      final WmlSection section = sections[i];
      if (phone) {
        final WmlPageMargins m = _origMargins![i];
        section.pageSize = WmlPageSize(width: pagePt, height: _origSizes![i].height);
        section.margins = WmlPageMargins(
          top: m.top.clamp(24.0, 48.0).toDouble(),
          bottom: m.bottom.clamp(24.0, 48.0).toDouble(),
          left: 18,
          right: 18,
          header: m.header,
          footer: m.footer,
        );
      } else {
        section.pageSize = _origSizes![i];
        section.margins = _origMargins![i];
      }
    }
  }

  void _applyPhoneView(bool phone) {
    if (!mounted) return;
    _setGeometry(phone: phone);
    _controller.relayout();
    _controller.fitPaintMetrics();
    _controller.viewport.origin = Offset(0, _controller.viewport.origin.dy);
    _controller.refresh();
    if (mounted) setState(() {});
  }

  void _setEditing(bool value) {
    if (_editing == value) return;
    setState(() => _editing = value);
    _typing.clear();
    if (value) {
      // Enable editing, but do not request the keyboard. A single tap on the
      // document attaches the IME; a drag is treated as scrolling.
      _controller.setMode(OfficeInteractionMode.editing);
      unawaited(
        SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
      );
    } else {
      // Leave edit mode: close the keyboard and stop caret/selection.
      _controller.setMode(OfficeInteractionMode.viewing);
      FocusManager.instance.primaryFocus?.unfocus();
      unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
    }
  }

  void _togglePhoneView() {
    _phoneView = !_phoneView;
    if (_phoneView) {
      _controller.viewport.setScale(_phoneScale);
      _applyPhoneView(true);
    } else {
      _setGeometry(phone: false);
      _controller.relayout();
      _controller.fitPaintMetrics();
      _controller.viewport.setScale(_wordInitialScale);
      _controller.viewport.origin = Offset.zero;
      _controller.refresh();
    }
  }

  // Quds canvas layout constants (see RenderWordCanvas): the page is painted
  // with a 64px gutter on both sides plus a 14px vertical scrollbar. When the
  // page (at the current scale) plus both gutters fits in the view, the canvas
  // centres it by itself; otherwise it is pinned to the left gutter.
  static const double _canvasGutter = 64.0;
  static const double _canvasScrollBar = 14.0;
  static const double _pointsToPixels = 96.0 / 72.0;

  void _fitPageToWidth() {
    if (!mounted) return;
    final double viewWidth = MediaQuery.sizeOf(context).width;
    final double pagePx = _controller.pageSize.width * _pointsToPixels;
    if (pagePx <= 0) return;
    // Largest scale at which the whole page + gutters + scrollbar fit, so the
    // canvas centres the page and nothing is clipped on the right.
    final double usable =
        viewWidth - (_canvasGutter * 2) - _canvasScrollBar - 1.0;
    final double scale = (usable / pagePx).clamp(0.25, 1.0).toDouble();
    _controller.viewport.setScale(scale);
    // Always start at the left/top edge; the canvas clamps and centres.
    _controller.viewport.origin = Offset.zero;
    _controller.refresh();
    if (mounted) setState(() {});
  }

  void _onWordPointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.touch) {
      _touchPositions[event.pointer] = event.position;
      _touchMoved[event.pointer] = false;

      // Do not hide the keyboard on pointer-down. A stationary tap is a
      // legitimate editing action; only hide it after the gesture is proven
      // to be a scroll.
    }
  }

  double? _lastPinchDistance;

  void _onWordPointerMove(PointerMoveEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    final Offset? previous = _touchPositions[event.pointer];
    if (previous == null) return;
    _touchPositions[event.pointer] = event.position;

    if ((event.position - previous).distance > _scrollGestureSlop) {
      _touchMoved[event.pointer] = true;
    }

    // Two fingers: pinch to zoom, or two-finger drag to scroll.
    if (_touchPositions.length == 2) {
      final List<Offset> pts = _touchPositions.values.toList();
      final double distance = (pts[0] - pts[1]).distance;
      final double? last = _lastPinchDistance;
      _lastPinchDistance = distance;
      if (last != null && last > 0 && distance > 0) {
        final double ratio = distance / last;
        if ((ratio - 1.0).abs() > 0.01) {
          _pinching = true;
          if (_editing) {
            _controller.setMode(OfficeInteractionMode.viewing);
            unawaited(
              SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
            );
          }
          final double next = (_controller.viewport.scale * ratio)
              .clamp(0.25, 2.0)
              .toDouble();
          _controller.viewport.setScale(next);
          _controller.refresh();
          if (mounted) setState(() {});
        } else {
          _scrollBy(event.position - previous, 0.5);
        }
      }
      return;
    }

    // One finger: scrolling must work even after Edit is enabled. Once the
    // movement passes the slop threshold, switch the Office surface to view
    // mode so a drag never turns into text selection/IME input.
    if (_touchMoved[event.pointer] == true) {
      if (_editing && _controller.mode != OfficeInteractionMode.viewing) {
        _controller.setMode(OfficeInteractionMode.viewing);
        unawaited(
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
        );
      }
      _scrollBy(event.position - previous, 1.0);
    }
  }

  void _scrollBy(Offset delta, double factor) {
    if (delta.distance == 0) return;
    final Offset origin = _controller.viewport.origin;
    _controller.viewport.origin = Offset(
      math.max(0, origin.dx - delta.dx * factor),
      math.max(0, origin.dy - delta.dy * factor),
    );
    _controller.refresh();
  }

  void _onWordPointerEnd(PointerEvent event) {
    final bool moved = _touchMoved[event.pointer] ?? false;
    _touchPositions.remove(event.pointer);
    _touchMoved.remove(event.pointer);

    if (_touchPositions.length < 2) {
      _lastPinchDistance = null;
      if (_pinching) {
        _pinching = false;
        if (_phoneView) _applyPhoneView(true);
      }
    }

    if (event.kind == PointerDeviceKind.touch && _editing && !moved && !_pinching) {
      // Stationary tap: edit at the caret and open the IME.
      _controller.setMode(OfficeInteractionMode.editing);
      _controller.attachInput();
    } else if (event.kind == PointerDeviceKind.touch &&
        _editing &&
        moved &&
        !_pinching) {
      // Scroll completed. Stay in viewing mode so the IME cannot immediately
      // reclaim focus on the next frame. The next deliberate tap re-enters edit.
      _controller.setMode(OfficeInteractionMode.viewing);
      FocusManager.instance.primaryFocus?.unfocus();
      unawaited(
        SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
      );
    }
  }

  Widget _selectionPopup() {
    final WmlRunProps run = _controller.activeRunProps;
    final String? highlight = run.highlight;
    final int sizePt = (run.fontSizeHalfPoints / 2).round();

    Widget iconButton(
      IconData icon,
      VoidCallback onPressed, {
      String? tooltip,
      bool active = false,
    }) {
      return IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        color: active ? Theme.of(context).colorScheme.primary : null,
        icon: Icon(icon, size: 20),
      );
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PopupMenuButton<String>(
                tooltip: 'Highlight',
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.highlight,
                  size: 20,
                  color: highlight == null ? null : _hexColor(highlight),
                ),
                onSelected: (String value) => _setHighlight(
                  value == 'none' ? null : value,
                ),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'none',
                    child: Text('No highlight'),
                  ),
                  for (final String value in <String>[
                    'FFFF00',
                    'FFCC80',
                    'B3E5FC',
                    'C8E6C9',
                    'E1BEE7',
                    'FFCDD2',
                  ])
                    PopupMenuItem<String>(
                      value: value,
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.highlight, color: _hexColor(value)),
                          const SizedBox(width: 8),
                          const Text('Highlight'),
                        ],
                      ),
                    ),
                ],
              ),
              iconButton(
                Icons.text_decrease,
                () => _setSize(sizePt - 1),
                tooltip: 'Smaller text',
              ),
              iconButton(
                Icons.text_increase,
                () => _setSize(sizePt + 1),
                tooltip: 'Larger text',
              ),
              PopupMenuButton<String>(
                tooltip: 'Text color',
                padding: EdgeInsets.zero,
                icon: Icon(Icons.format_color_text, color: _hexColor(run.color), size: 20),
                onSelected: _setColor,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  for (final String value in <String>[
                    '000000',
                    'D32F2F',
                    '1976D2',
                    '388E3C',
                    'F57C00',
                    '7B1FA2',
                    '00838F',
                  ])
                    PopupMenuItem<String>(
                      value: value,
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.circle, color: _hexColor(value), size: 18),
                          const SizedBox(width: 8),
                          Text(value),
                        ],
                      ),
                    ),
                ],
              ),
              iconButton(
                Icons.format_bold,
                () => _formatRun(
                  update: (WmlRunProps p) => p.bold = !p.bold,
                  remember: (_TypingStyle t) => t.bold = !_boldNow,
                ),
                tooltip: 'Bold',
                active: run.bold,
              ),
              iconButton(
                Icons.format_underlined,
                () => _formatRun(
                  update: (WmlRunProps p) => p.underline =
                      p.underline == WmlUnderline.none
                          ? WmlUnderline.single
                          : WmlUnderline.none,
                  remember: (_TypingStyle t) => t.underline = !_underNow,
                ),
                tooltip: 'Underline',
                active: run.underline != WmlUnderline.none,
              ),
              PopupMenuButton<int>(
                tooltip: 'Heading',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.title, size: 20),
                onSelected: _controller.applyHeading,
                itemBuilder: (BuildContext context) => const <PopupMenuEntry<int>>[
                  PopupMenuItem<int>(value: 0, child: Text('Normal text')),
                  PopupMenuItem<int>(value: 1, child: Text('Heading 1')),
                  PopupMenuItem<int>(value: 2, child: Text('Heading 2')),
                  PopupMenuItem<int>(value: 3, child: Text('Heading 3')),
                  PopupMenuItem<int>(value: 4, child: Text('Heading 4')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbar() {
    final int sizePt = (_sizeHalfNow / 2).round();
    final WmlRunProps run = _controller.activeRunProps;
    final String color = _typing.color ?? run.color;
    final String? highlight = _typing.highlightSet ? _typing.highlight : run.highlight;
    return Material(
      elevation: 6,
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _icon(Icons.undo, _controller.undo, tooltip: 'Undo', active: _controller.canUndo),
            _icon(Icons.redo, _controller.redo, tooltip: 'Redo', active: _controller.canRedo),
            _icon(Icons.text_fields, _controller.selectWordAtCaret, tooltip: 'Select word'),
            _icon(Icons.select_all, _controller.selectAll, tooltip: 'Select all'),
            _icon(Icons.format_bold, _toggleBold, tooltip: 'Bold', active: _boldNow),
            _icon(Icons.format_italic, _toggleItalic, tooltip: 'Italic', active: _italicNow),
            _icon(Icons.format_underlined, _toggleUnderline, tooltip: 'Underline', active: _underNow),
            _icon(Icons.text_decrease, () => _stepSize(-1), tooltip: 'Smaller text'),
            PopupMenuButton<int>(
              tooltip: 'Text size',
              icon: Text('$sizePt', style: const TextStyle(fontWeight: FontWeight.w600)),
              onSelected: _setSize,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                for (final int size in <int>[8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48])
                  PopupMenuItem<int>(value: size, child: Text('$size pt')),
              ],
            ),
            _icon(Icons.text_increase, () => _stepSize(1), tooltip: 'Larger text'),
            PopupMenuButton<String>(
              tooltip: 'Text color',
              icon: Icon(Icons.format_color_text, color: _hexColor(color)),
              onSelected: _setColor,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                for (final String value in <String>['000000', 'D32F2F', '1976D2', '388E3C', 'F57C00', '7B1FA2', '00838F'])
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
            PopupMenuButton<String>(
              tooltip: 'Highlight',
              icon: Icon(Icons.highlight, color: highlight == null ? null : _hexColor(highlight)),
              onSelected: (String value) => _setHighlight(value == 'none' ? null : value),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'none', child: Text('No highlight')),
                for (final String value in <String>['FFFF00', 'FFCC80', 'B3E5FC', 'C8E6C9', 'E1BEE7', 'FFCDD2'])
                  PopupMenuItem<String>(
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
                PopupMenuItem<int>(value: 0, child: Text('Normal text')),
                PopupMenuItem<int>(value: 1, child: Text('Heading 1')),
                PopupMenuItem<int>(value: 2, child: Text('Heading 2')),
                PopupMenuItem<int>(value: 3, child: Text('Heading 3')),
                PopupMenuItem<int>(value: 4, child: Text('Heading 4')),
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
              _phoneView ? Icons.description_outlined : Icons.smartphone,
              _togglePhoneView,
              tooltip: _phoneView ? 'A4 page size' : 'Phone view',
            ),
            _icon(Icons.zoom_out, () => _setZoom(_controller.viewport.scale - 0.1), tooltip: 'Zoom out'),
            IconButton(
              tooltip: 'Reset zoom',
              onPressed: () => _setZoom(_phoneView ? _phoneScale : 1.0),
              icon: Text('$_zoomPercent%', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            _icon(Icons.zoom_in, () => _setZoom(_controller.viewport.scale + 0.1), tooltip: 'Zoom in'),
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
      final Widget editor = QudsWordEditor(controller: _controller);
      final Widget canvas = _phoneView
          ? LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) => ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: c.maxWidth + _editorExtra,
                  maxWidth: c.maxWidth + _editorExtra,
                  child: Transform.translate(
                    offset: const Offset(-64, 0),
                    child: editor,
                  ),
                ),
              ),
            )
          : editor;
      body = Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Listener(
                    onPointerDown: _onWordPointerDown,
                    onPointerMove: _onWordPointerMove,
                    onPointerUp: _onWordPointerEnd,
                    onPointerCancel: _onWordPointerEnd,
                    child: canvas,
                  ),
                ),
                if (_editing && !_controller.caret.isCollapsed)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 12,
                    child: Center(child: _selectionPopup()),
                  ),
              ],
            ),
          ),
          if (!_loading && _editing && _controller.caret.isCollapsed)
            SafeArea(top: false, child: _toolbar()),
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
              IconButton(
                tooltip: _editing ? 'Done editing' : 'Edit',
                onPressed: () => _setEditing(!_editing),
                icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
              ),
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
        floatingActionButton: (_docx && !_loading && _error == null && !_editing)
            ? FloatingActionButton(
                tooltip: 'Edit',
                onPressed: () => _setEditing(true),
                child: const Icon(Icons.edit),
              )
            : null,
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

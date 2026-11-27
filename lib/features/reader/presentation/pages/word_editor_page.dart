import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:archive/archive.dart';

import 'package:flutter/gestures.dart';
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

/// Draws the selection highlight ourselves: the package paints the selection
/// with the inverse of the text colour, which is invisible on black text.
class _SelectionPainter extends CustomPainter {
  _SelectionPainter(this.rects, this.color);

  final List<Rect> rects;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    for (final Rect r in rects) {
      canvas.drawRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter old) =>
      old.color != color || old.rects != rects;
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

class _WordEditorPageState extends State<WordEditorPage> with WidgetsBindingObserver {
  late final WordEditorController _controller;
  LibraryDocument? _document;
  bool _loading = true;
  String? _error;
  bool _saving = false;
  final Map<int, Offset> _touchPositions = <int, Offset>{};
  final GlobalKey _editorStackKey = GlobalKey();

  // "Phone view" (like WPS mobile view): every section is temporarily made as
  // wide as the screen so the text re-wraps to the phone. The original page
  // geometry is restored before saving, so the .docx layout is never changed.
  bool _phoneView = true;
  bool _editing = false;
  // While selecting text the controller runs in "selecting" mode: selection
  // works but no keyboard is attached, so it can never pop up mid-selection.
  bool _selectMode = false;
  final _TypingStyle _typing = _TypingStyle();
  bool _applyingTyping = false;
  int _snapPara = 0;
  int _snapLen = 0;
  int _snapCaret = 0;
  int _snapStart = 0;
  bool _pinching = false;
  bool _scrollbarDragging = false;
  bool _visualDragging = false;
  bool _visualDragMoved = false;
  Offset? _visualDragLastPosition;
  Timer? _keyboardCaretFollowTimer;
  List<WmlPageSize>? _origSizes;
  List<WmlPageMargins>? _origMargins;
  static const double _phoneScale = 0.9;

  bool get _docx {
    final String fileName =
        (_document?.fileName ?? widget.file?.name ?? '').toLowerCase();
    final String path =
        (_document?.filePath ?? widget.file?.path ?? '').toLowerCase();
    return fileName.endsWith('.docx') || path.endsWith('.docx');
  }

  String get _path => _document?.filePath ?? widget.file?.path ?? '';
  String get _name => _document?.fileName ?? widget.file?.name ?? 'Document';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _scheduleKeyboardCaretVisibility();
  }

  /// Keyboard appearance changes the available editor height without changing
  /// the Quds controller. Re-check the caret after the window metrics change
  /// so the active line is automatically brought above the keyboard.
  @override
  void didChangeMetrics() {
    if (!mounted || !_editing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureKeyboardCaretVisible();
    });
  }

  /// Quds owns the document viewport, so Scaffold resize only reduces the
  /// available canvas. It does not automatically pan the document to the caret.
  /// Keyboard opening is animated on Android, so a single frame is too early.
  /// Re-check for a short window until the keyboard settles.
  void _scheduleKeyboardCaretVisibility() {
    if (!_editing || !mounted) return;
    if (MediaQuery.viewInsetsOf(context).bottom <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_editing) return;
      _ensureKeyboardCaretVisible();
    });

    _keyboardCaretFollowTimer?.cancel();
    int ticks = 0;
    _keyboardCaretFollowTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (Timer timer) {
        if (!mounted ||
            !_editing ||
            MediaQuery.viewInsetsOf(context).bottom <= 0 ||
            ticks++ >= 8) {
          timer.cancel();
          if (identical(_keyboardCaretFollowTimer, timer)) {
            _keyboardCaretFollowTimer = null;
          }
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _editing) _ensureKeyboardCaretVisible();
        });
      },
    );
  }

  void _ensureKeyboardCaretVisible() {
    if (!_editing || !mounted || MediaQuery.viewInsetsOf(context).bottom <= 0) {
      return;
    }

    final CaretEngine c = _controller.caret;
    final List<dynamic> pages = _controller.documentLaidOut.pages.toList();
    final double scale = _controller.viewport.scale * _pointsToPixels;
    final Offset origin = _controller.viewport.origin;

    double pageTop = 24.0;
    double? caretTop;
    double? caretBottom;

    for (final dynamic page in pages) {
      final List<LaidOutLine> lines =
          (page.lines as List<dynamic>).cast<LaidOutLine>();
      for (final LaidOutLine line in lines) {
        if (line.paragraphIndex != c.paragraphIndex) continue;
        caretTop = pageTop + line.y * scale - origin.dy;
        caretBottom = pageTop + (line.y + line.height) * scale - origin.dy;
        break;
      }
      if (caretTop != null) break;
      pageTop += (page.height as double) * scale + 24.0;
    }

    if (caretTop == null || caretBottom == null) return;

    const double topPadding = 24.0;
    // Keep the active line comfortably above the keyboard/format bar.
    const double bottomPadding = 56.0;
    double delta = 0;
    if (caretTop < topPadding) {
      delta = caretTop - topPadding;
    } else if (caretBottom > _canvasSize.height - bottomPadding) {
      delta = caretBottom - (_canvasSize.height - bottomPadding);
    }
    if (delta.abs() < 1) return;

    _controller.viewport.origin = Offset(
      origin.dx,
      (origin.dy + delta).clamp(0.0, double.infinity).toDouble(),
    );
    _controller.refresh();
  }

  List<WmlParagraph> get _paras => _controller.document.paragraphs.toList();

  void _snapshotTyping() {
    final List<WmlParagraph> paras = _paras;
    if (paras.isEmpty) return;
    final CaretEngine c = _controller.caret;
    _snapPara = c.paragraphIndex.clamp(0, paras.length - 1);
    _snapStart = c.logicalIndex;
    _snapLen = paras[_snapPara].text.length;
    _snapCaret = c.logicalIndex;
  }

  bool _rangeMatchesTyping(WmlParagraph para, int from, int to) {
    for (int i = from; i < to; i++) {
      final WmlRunProps p = WmlRunEdit.propsAt(para, i);
      if (_typing.bold != null && p.bold != _typing.bold) return false;
      if (_typing.italic != null && p.italic != _typing.italic) return false;
      if (_typing.underline != null &&
          (p.underline != WmlUnderline.none) != _typing.underline) {
        return false;
      }
      if (_typing.sizeHalf != null && p.fontSizeHalfPoints != _typing.sizeHalf) {
        return false;
      }
      if (_typing.color != null && p.color != _typing.color) return false;
      if (_typing.highlightSet && p.highlight != _typing.highlight) return false;
    }
    return true;
  }

  /// Keeps everything typed after the style was chosen in that style, even
  /// when the keyboard replaces text (suggestions, auto-correct, composing).
  void _trackTyping() {
    if (_typing.isEmpty || _applyingTyping || !_editing) return;
    final List<WmlParagraph> paras = _paras;
    if (paras.isEmpty) return;
    final CaretEngine c = _controller.caret;
    final int pi = c.paragraphIndex.clamp(0, paras.length - 1);
    final int caret = c.logicalIndex;
    if (pi != _snapPara || caret < _snapStart) {
      _typing.clear(); // caret moved away from where the style was chosen
      return;
    }
    final WmlParagraph para = paras[pi];
    final int end = caret.clamp(0, para.text.length);
    if (end <= _snapStart || _rangeMatchesTyping(para, _snapStart, end)) return;
    _applyingTyping = true;
    final int anchor = c.selectionAnchor;
    final int anchorPara = c.selectionAnchorParagraph;
    try {
      c.selectionAnchorParagraph = pi;
      c.selectionAnchor = _snapStart;
      c.logicalIndex = end;
      _controller.applyRunFormat(_typing.apply);
      c.logicalIndex = caret;
      c.selectionAnchorParagraph = anchorPara;
      c.selectionAnchor = anchor;
      if (anchor == caret && anchorPara == pi) c.collapseSelection();
    } finally {
      _applyingTyping = false;
    }
  }

  /// In an empty paragraph the next typed character copies the properties of
  /// the paragraph's (empty) run, so set the style there directly.
  void _primeEmptyParagraph() {
    final List<WmlParagraph> paras = _paras;
    if (paras.isEmpty) return;
    final int pi = _controller.caret.paragraphIndex.clamp(0, paras.length - 1);
    final WmlParagraph para = paras[pi];
    if (para.text.isNotEmpty) return;
    WmlRun? run;
    for (final WmlInline inline in para.inlines) {
      if (inline is WmlRun) {
        run = inline;
        break;
      }
    }
    if (run == null) {
      run = WmlRun();
      para.inlines.add(run);
    }
    _typing.apply(run.properties);
  }

  /// Formats the selection, or (with no selection) the text typed next.
  void _formatRun({
    required void Function(WmlRunProps p) update,
    required void Function(_TypingStyle t) remember,
  }) {
    if (!_editing) return;
    _ensureEditing();
    if (_controller.caret.isCollapsed) {
      remember(_typing);
      _snapshotTyping();
      _primeEmptyParagraph();
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
        // New assignment: A4 document, edited in the readable reflow view.
        if (blankNew) _editing = true;
        _normalizeImportedWordLayout();
        // fitPaintMetrics() already re-lays out and then applies the same
        // Flutter font metrics used by the canvas. Do not call relayout()
        // afterwards, because that would discard the fitted paint metrics.
        _controller.fitPaintMetrics();
        _controller.refresh();
        _controller.markClean();
        // Library DOCX files must stay inside DarsNexa. The office canvas is
        // wider than a phone at 100%, so choose a readable initial scale that
        // fits an A4/Letter page inside the available screen width.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_editing) _controller.setMode(OfficeInteractionMode.editing);
          if (_phoneView) {
            _controller.viewport.setScale(_phoneScale);
            _applyPhoneView(true);
          } else {
            _fitPageToWidth();
          }
        });
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
      onPressed: () {
        _ensureEditing();
        action();
      },
      color: active ? Theme.of(context).colorScheme.primary : null,
      icon: Icon(icon),
    );
  }

  int get _zoomPercent => (_controller.viewport.scale * 100).round();

  void _setZoom(double value) {
    final double clamped = value.clamp(0.25, 2.0).toDouble();
    _controller.viewport.setScale(clamped);
    _clampOrigin();
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

  void _beginSelect() {
    if (_selectMode) return;
    _selectMode = true;
    _controller.setMode(OfficeInteractionMode.selecting); // also hides keyboard
  }

  /// Leaves selection mode (without touching the selection) so formatting and
  /// other edits are allowed again. This does not open the keyboard.
  void _ensureEditing() {
    if (!_selectMode) return;
    _selectMode = false;
    _controller.setMode(OfficeInteractionMode.editing);
  }

  void _setEditing(bool value) {
    _selectMode = false;
    if (_editing == value) return;
    setState(() => _editing = value);
    _typing.clear();
    if (value) {
      _controller.setMode(OfficeInteractionMode.editing);
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
      _fitPageToWidth();
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
    // The canvas is edge to edge (gutters are clipped away), so the page can
    // use the full screen width. Pinch/zoom then pans horizontally.
    final double scale = ((viewWidth + 1.0) / pagePx).clamp(0.25, 1.0).toDouble();
    _controller.viewport.setScale(scale);
    _controller.viewport.origin = Offset.zero;
    _controller.refresh();
    if (mounted) setState(() {});
  }

  // All touch input is handled here; the Quds canvas is wrapped in an
  // IgnorePointer so scrolling can never move the caret or open the keyboard.
  // Only a genuine tap (or long press) is forwarded to the canvas.
  bool _forwarding = false;
  int _fwdSeq = 0;
  Offset? _downPos;
  DateTime? _downAt;
  bool _moved = false;
  Timer? _longPress;

  /// Returns the visible screen rect of the currently selected floating visual.
  /// Quds stores visual coordinates in document points; convert them to the
  /// current canvas scale and viewport origin.
  Rect? _selectedVisualRect() {
    final WmlVisual? selected = _controller.selectedVisual;
    if (selected == null || !selected.visual.isPicture) return null;

    final OfficeVisual visual = selected.visual;
    final double scale = _controller.viewport.scale * _pointsToPixels;
    if (scale <= 0) return null;

    final Offset origin = _controller.viewport.origin;
    const double pageTop = 24.0;
    final double left = visual.offsetX * scale - origin.dx;
    final double top = pageTop + visual.offsetY * scale - origin.dy;
    final double width = visual.width * scale;
    final double height = visual.height * scale;
    if (width <= 0 || height <= 0) return null;

    return Rect.fromLTWH(left, top, width, height);
  }

  bool _tryStartVisualDrag(Offset position) {
    if (!_editing || _controller.mode != OfficeInteractionMode.editing) {
      return false;
    }
    final WmlVisual? selected = _controller.selectedVisual;
    final Rect? rect = _selectedVisualRect();
    if (selected == null ||
        !selected.visual.isPicture ||
        rect == null ||
        !rect.inflate(18).contains(position)) {
      return false;
    }

    _visualDragging = true;
    _visualDragMoved = false;
    _visualDragLastPosition = position;
    _controller.beginVisualTransform();
    _longPress?.cancel();
    _downPos = null;
    return true;
  }

  void _updateVisualDrag(Offset position) {
    if (!_visualDragging || _visualDragLastPosition == null) return;
    final Offset deltaPx = position - _visualDragLastPosition!;
    if (deltaPx.distance < 0.1) return;

    final double scale = _controller.viewport.scale * _pointsToPixels;
    if (scale <= 0) return;

    _visualDragMoved = true;
    _visualDragLastPosition = position;
    // previewVisualMove works in document points, not screen pixels.
    _controller.previewVisualMove(deltaPx.dx / scale, deltaPx.dy / scale);
    _controller.refresh();
  }

  void _endVisualDrag() {
    if (!_visualDragging) return;
    _visualDragging = false;
    _visualDragLastPosition = null;
    if (_visualDragMoved) {
      _controller.commitVisualTransform();
    }
    _visualDragMoved = false;
    if (mounted) setState(() {});
  }

  void _onWordPointerDown(PointerDownEvent event) {
    if (_forwarding || event.kind != PointerDeviceKind.touch) return;
    if (_tryStartVisualDrag(event.position)) return;
    _touchPositions[event.pointer] = event.position;
    if (_touchPositions.length == 1) {
      _downPos = event.position;
      _downAt = DateTime.now();
      _moved = false;
      _longPress?.cancel();
      _longPress = Timer(const Duration(milliseconds: 450), () {
        if (!_moved && _touchPositions.length == 1 && _downPos != null) {
          _forwardTaps(_downPos!, count: 2, enterEdit: false, select: true);
          _downPos = null; // consumed: do not also treat release as a tap
          _selectDrag = true; // keep pressing and drag to extend the selection
          _selectionDragActive = true;
        }
      });
    } else {
      _moved = true;
      _longPress?.cancel();
    }
  }

  double? _lastPinchDistance;

  void _onWordPointerMove(PointerMoveEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    if (_visualDragging) {
      _updateVisualDrag(event.position);
      return;
    }
    if (_forwarding && !_selectDrag) return;
    final Offset? previous = _touchPositions[event.pointer];
    _touchPositions[event.pointer] = event.position;
    if (previous == null) return;
    if (_selectDrag) {
      // Wait until the long-press word selection has been applied, otherwise
      // it would reset the selection the finger has already started extending.
      if (_forwarding) return;
      // event.position is a SCREEN position; the selection code works in the
      // editor's own coordinates. Passing the screen position made the
      // selection land ~100px (several lines) below the finger and triggered
      // the edge auto-scroll, which is what threw the selection out of control.
      _updateSelectionDrag(
        _editorLocalFromGlobal(event.position) + const Offset(0, -10),
      );
      return;
    }
    if (_downPos != null && (event.position - _downPos!).distance > 10) {
      _moved = true;
      _longPress?.cancel();
    }

    // Two fingers: pinch to zoom, or drag to scroll.
    if (_touchPositions.length == 2) {
      final List<Offset> pts = _touchPositions.values.toList();
      final double distance = (pts[0] - pts[1]).distance;
      final double? last = _lastPinchDistance;
      _lastPinchDistance = distance;
      if (last != null && last > 0 && distance > 0) {
        final double ratio = distance / last;
        if ((ratio - 1.0).abs() > 0.01) {
          _pinching = true;
          final double next = (_controller.viewport.scale * ratio)
              .clamp(0.25, 2.0)
              .toDouble();
          _controller.viewport.setScale(next);
          _clampOrigin();
          _controller.refresh();
          if (mounted) setState(() {});
        } else {
          _scrollBy(event.position - previous, 0.5);
        }
      }
      return;
    }

    // One finger: scroll (vertical and horizontal) in both view and edit mode.
    if (_moved) _scrollBy(event.position - previous, 1.0);
  }

  Size _canvasSize = Size.zero;

  /// Keeps the scroll position inside the real page bounds so the page can
  /// never be dragged out of view.
  void _clampOrigin() {
    final double scale = _controller.viewport.scale * _pointsToPixels;
    final double viewW = _canvasSize.width;
    final double viewH = _canvasSize.height;
    double maxX = 0;
    double maxY = 0;
    try {
      double pageW = _controller.pageSize.width;
      double stack = 24.0;
      final List<dynamic> pages = _controller.documentLaidOut.pages.toList();
      for (final dynamic page in pages) {
        stack += (page.height as double) * scale + 24;
      }
      if (pages.isEmpty) stack += _controller.pageSize.height * scale + 24;
      final double contentW = pageW * scale;
      maxX = math.max(0, contentW - viewW);
      maxY = math.max(0, stack - viewH);
    } on Object {
      maxX = 0;
      maxY = double.infinity;
    }
    final Offset o = _controller.viewport.origin;
    _controller.viewport.origin = Offset(
      o.dx.clamp(0.0, maxX).toDouble(),
      o.dy.clamp(0.0, maxY).toDouble(),
    );
  }

  void _scrollBy(Offset delta, double factor) {
    if (delta.distance == 0) return;
    final Offset origin = _controller.viewport.origin;
    _controller.viewport.origin = Offset(
      origin.dx - delta.dx * factor,
      origin.dy - delta.dy * factor,
    );
    _clampOrigin();
    _controller.refresh();
  }

  double _maxScrollY() {
    final double scale = _controller.viewport.scale * _pointsToPixels;
    if (scale <= 0 || _canvasSize.height <= 0) return 0;
    try {
      double contentHeight = 24.0;
      final List<dynamic> pages = _controller.documentLaidOut.pages.toList();
      for (final dynamic page in pages) {
        contentHeight += (page.height as double) * scale + 24.0;
      }
      if (pages.isEmpty) {
        contentHeight += _controller.pageSize.height * scale + 24.0;
      }
      return math.max(0.0, contentHeight - _canvasSize.height);
    } on Object {
      return 0;
    }
  }

  Widget _verticalScrollbar() {
    final double maxScroll = _maxScrollY();
    if (maxScroll <= 1 || _canvasSize.height <= 0) {
      return const SizedBox.shrink();
    }

    const double trackWidth = 6.0;
    const double trackMargin = 6.0;
    const double minThumbHeight = 36.0;
    final double trackHeight =
        math.max(24.0, _canvasSize.height - trackMargin * 2);
    final double contentHeight = _canvasSize.height + maxScroll;
    final double thumbHeight = math.max(
      minThumbHeight,
      trackHeight * (_canvasSize.height / contentHeight),
    ).clamp(0.0, trackHeight).toDouble();
    final double travel = math.max(0.0, trackHeight - thumbHeight);
    final double progress =
        maxScroll <= 0 ? 0 : (_controller.viewport.origin.dy / maxScroll).clamp(0.0, 1.0).toDouble();
    final double thumbTop = trackMargin + travel * progress;

    void beginDrag(DragStartDetails details) {
      _scrollbarDragging = true;
      if (mounted) setState(() {});
    }

    void updateDrag(DragUpdateDetails details) {
      if (!_scrollbarDragging || travel <= 0) return;
      final double originDelta = details.delta.dy * maxScroll / travel;
      final Offset origin = _controller.viewport.origin;
      _controller.viewport.origin = Offset(
        origin.dx,
        (origin.dy + originDelta).clamp(0.0, maxScroll).toDouble(),
      );
      _controller.refresh();
    }

    void endDrag(DragEndDetails details) {
      _scrollbarDragging = false;
      if (mounted) setState(() {});
    }

    return Positioned(
      top: 0,
      right: 2,
      bottom: 0,
      width: 14,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: beginDrag,
        onVerticalDragUpdate: updateDrag,
        onVerticalDragEnd: endDrag,
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Positioned(
              top: trackMargin,
              bottom: trackMargin,
              child: Container(
                width: trackWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Positioned(
              top: thumbTop,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                width: _scrollbarDragging ? 7.0 : trackWidth,
                height: thumbHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
                    alpha: _scrollbarDragging ? 0.82 : 0.58,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sends one real tap to the canvas. With [shift] the canvas treats it as a
  /// "extend selection to here" click, which is how selection handles and
  /// press-and-drag selection move the end of the selection.
  void _dispatchTap(Offset position, {bool shift = false}) {
    final int viewId = View.of(context).viewId;
    final int id = 9000 + (_fwdSeq++);
    if (shift) {
      HardwareKeyboard.instance.handleKeyEvent(KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.shiftLeft,
        logicalKey: LogicalKeyboardKey.shiftLeft,
        timeStamp: Duration.zero,
      ));
    }
    try {
      GestureBinding.instance.handlePointerEvent(PointerDownEvent(
        viewId: viewId,
        pointer: id,
        position: position,
      ));
      GestureBinding.instance.handlePointerEvent(PointerUpEvent(
        viewId: viewId,
        pointer: id,
        position: position,
      ));
    } finally {
      if (shift) {
        HardwareKeyboard.instance.handleKeyEvent(KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.shiftLeft,
          logicalKey: LogicalKeyboardKey.shiftLeft,
          timeStamp: Duration.zero,
        ));
      }
    }
  }

  /// Sends real tap events to the (otherwise ignored) canvas so that the caret
  /// is placed and the keyboard opens only for a deliberate tap.
  void _forwardTaps(
    Offset position, {
    int count = 1,
    bool enterEdit = true,
    bool select = false,
  }) {
    if (!mounted) return;
    if (!_editing && !enterEdit && !select) return;
    if (!_editing && enterEdit) {
      _setEditing(true);
    }
    if (select) {
      _beginSelect();
    } else {
      _ensureEditing();
    }
    setState(() => _forwarding = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (int i = 0; i < count; i++) {
        _dispatchTap(position);
      }
      if (mounted) setState(() => _forwarding = false);
    });
  }

  bool _extendBusy = false;
  Offset? _extendNext;
  bool _selectDrag = false;
  bool _selectionDragActive = false;
  Offset? _lastSelectionPoint;
  Timer? _selectionAutoScroll;

  void _startSelectionDrag(Offset point) {
    _selectionDragActive = true;
    _updateSelectionDrag(point);
  }

  void _stopSelectionDrag() {
    _selectionDragActive = false;
    _lastSelectionPoint = null;
    _selectionAutoScroll?.cancel();
    _selectionAutoScroll = null;
  }

  /// Converts a screen/global gesture position into the editor Stack's local
  /// coordinates. Handle gestures report globalPosition, while the selection
  /// hit-test below works in the Stack's coordinate system. Mixing those two
  /// spaces was the main reason handle drags could jump by a whole paragraph.
  Offset _editorLocalFromGlobal(Offset globalPosition) {
    final BuildContext? stackContext = _editorStackKey.currentContext;
    final RenderObject? renderObject = stackContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.globalToLocal(globalPosition);
    }
    return globalPosition;
  }

  /// Keeps the injected tap inside the visible editor viewport. The point is
  /// already in the editor Stack's local coordinate space.
  Offset _safeSelectionPoint(Offset point) {
    final double top = 4;
    final double bottom = math.max(top + 20, _canvasSize.height - 4);
    return Offset(
      point.dx,
      point.dy.clamp(top, bottom).toDouble(),
    );
  }

  void _updateSelectionDrag(Offset point) {
    if (!_selectionDragActive || !mounted) return;
    _lastSelectionPoint = point;
    _extendTo(_safeSelectionPoint(point));

    // These coordinates are local to the editor Stack, not screen
    // coordinates. Using screen coordinates here made edge auto-scroll start
    // far too early/late after handle dragging.
    final double top = 8;
    final double bottom = math.max(top + 40, _canvasSize.height - 8);
    final double edge = 56;
    final bool nearTop = point.dy < top + edge;
    final bool nearBottom = point.dy > bottom - edge;
    if (!nearTop && !nearBottom) {
      _selectionAutoScroll?.cancel();
      _selectionAutoScroll = null;
      return;
    }
    _selectionAutoScroll ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_selectionDragActive || !mounted || _lastSelectionPoint == null) {
        _stopSelectionDrag();
        return;
      }
      final Offset current = _lastSelectionPoint!;
      final double currentTop = 8;
      final double currentBottom = math.max(currentTop + 40, _canvasSize.height - 8);
      final bool atTop = current.dy < currentTop + edge;
      final bool atBottom = current.dy > currentBottom - edge;
      if (!atTop && !atBottom) {
        _selectionAutoScroll?.cancel();
        _selectionAutoScroll = null;
        return;
      }
      final double distance = atBottom
          ? (current.dy - (currentBottom - edge)).clamp(0.0, edge)
          : ((currentTop + edge) - current.dy).clamp(0.0, edge);
      final double speed = 1.5 + distance / 10;
      _scrollBy(Offset(0, atBottom ? -speed : speed), 1.0);
      _extendTo(_safeSelectionPoint(current));
    });
  }

  /// Moves the active selection end directly from the handle position.
  ///
  /// Avoid synthetic Shift+tap events during a handle drag. They make the
  /// editor repeat its normal hit-test and can snap the focus to a paragraph
  /// when the finger crosses a line. Resolve the finger position against the
  /// already-laid-out line instead, so the nearest logical character remains
  /// the moving end of the selection.
  void _extendTo(Offset position) {
    if (!_selectionDragActive || !mounted) return;

    final CaretEngine c = _controller.caret;
    final List<dynamic> pages = _controller.documentLaidOut.pages.toList();
    if (pages.isEmpty) return;

    final double scale = _controller.viewport.scale * _pointsToPixels;
    if (scale <= 0) return;

    final Offset origin = _controller.viewport.origin;
    final double viewW = _canvasSize.width + _editorExtra - _canvasScrollBar;
    final double canvasX = position.dx + origin.dx + _canvasGutter;
    final double canvasY = position.dy + origin.dy;

    dynamic? targetPage;
    double targetPageTop = 24.0;
    double bestPageDistance = double.infinity;

    double pageTop = 24.0;
    for (final dynamic page in pages) {
      final double pageHeight = page.height as double;
      final double pageBottom = pageTop + pageHeight * scale;

      // Prefer the page directly under the finger. Only fall back to the
      // nearest page when the finger is in the gap between two pages.
      if (canvasY >= pageTop && canvasY <= pageBottom) {
        targetPage = page;
        targetPageTop = pageTop;
        break;
      }

      final double distance =
          canvasY < pageTop ? pageTop - canvasY : canvasY - pageBottom;
      if (distance < bestPageDistance) {
        bestPageDistance = distance;
        targetPage = page;
        targetPageTop = pageTop;
      }
      pageTop = pageBottom + 24.0;
    }

    final dynamic? page = targetPage;
    if (page == null) return;

    final double pageWidth = page.width as double;
    final double pagePixelWidth = pageWidth * scale;
    final double left = viewW > pagePixelWidth + _canvasGutter * 2
        ? (viewW - pagePixelWidth) / 2
        : _canvasGutter;

    final double localY = (canvasY - targetPageTop) / scale;
    final List<LaidOutLine> lines =
        (page.lines as List<dynamic>).cast<LaidOutLine>();
    if (lines.isEmpty) return;

    LaidOutLine? targetLine;
    double bestLineDistance = double.infinity;
    for (final LaidOutLine line in lines) {
      final double distance = (localY - (line.y + line.height / 2)).abs();
      if (distance < bestLineDistance) {
        bestLineDistance = distance;
        targetLine = line;
      }
    }

    final LaidOutLine? line = targetLine;
    if (line == null) return;

    // Convert the finger's X position into the line's document coordinates.
    // Clamping to the page prevents tiny horizontal overshoots at either edge
    // from jumping the caret to another paragraph.
    final double targetX =
        ((canvasX - left) / scale).clamp(0.0, pageWidth).toDouble();
    final int paragraph = line.paragraphIndex;
    final int index = CaretEngine.hitLogicalIndex(line, targetX);

    if (c.paragraphIndex == paragraph && c.logicalIndex == index) return;

    c.paragraphIndex = paragraph;
    c.logicalIndex = index;
    _controller.refresh();
  }

  // ---- selection handles (Android style) --------------------------------

  /// Bottom-left of the first and bottom-right of the last selected box, in
  /// the coordinates of the canvas area.
  ({Offset start, Offset end, List<Rect> rects, Rect startRect, Rect endRect})?
      _selectionEnds() {
    final CaretEngine c = _controller.caret;
    if (c.isCollapsed) return null;
    try {
      final List<dynamic> pages = _controller.documentLaidOut.pages.toList();
      final double scale = _controller.viewport.scale * _pointsToPixels;
      final Offset o = _controller.viewport.origin;
      double maxW = 0;
      for (final dynamic page in pages) {
        maxW = math.max(maxW, page.width as double);
      }
      final double viewW = _canvasSize.width + _editorExtra - _canvasScrollBar;
      final double pageW = maxW * scale;
      final double left = viewW > pageW + _canvasGutter * 2
          ? (viewW - pageW) / 2
          : _canvasGutter;
      Offset? first;
      Offset? last;
      final List<Rect> boxes = <Rect>[];
      double top = 24.0;
      for (final dynamic page in pages) {
        for (final LaidOutLine line in (page.lines as List<dynamic>).cast<LaidOutLine>()) {
          final List<Rect> rects = c.selectionRectsOnLine(
            line,
            line.y,
            line.height,
            paragraph: line.paragraphIndex,
          );
          for (final Rect r in rects) {
            final double y = top - o.dy + r.bottom * scale;
            first ??= Offset(left - o.dx + r.left * scale - _canvasGutter, y);
            last = Offset(left - o.dx + r.right * scale - _canvasGutter, y);
            boxes.add(Rect.fromLTRB(
              left - o.dx + r.left * scale - _canvasGutter,
              top - o.dy + r.top * scale,
              left - o.dx + r.right * scale - _canvasGutter,
              y,
            ));
          }
        }
        top += (page.height as double) * scale + 24;
      }
      if (first == null || last == null) return null;
      return (
        start: first,
        end: last,
        rects: boxes,
        startRect: boxes.first,
        endRect: boxes.last,
      );
    } on Object {
      return null;
    }
  }

  void _handleDragStart({required bool startHandle}) {
    _beginSelect();
    final CaretEngine c = _controller.caret;
    // Make the dragged end the moving end (the "focus") of the selection.
    final bool forward = c.selectionAnchorParagraph < c.paragraphIndex ||
        (c.selectionAnchorParagraph == c.paragraphIndex &&
            c.selectionAnchor <= c.logicalIndex);
    final bool needSwap = startHandle ? forward : !forward;
    if (needSwap) {
      final int ap = c.selectionAnchorParagraph;
      final int ai = c.selectionAnchor;
      c.selectionAnchorParagraph = c.paragraphIndex;
      c.selectionAnchor = c.logicalIndex;
      c.paragraphIndex = ap;
      c.logicalIndex = ai;
    }
  }

  static const double _knob = 22;

  /// Turns a finger position on the knob into the point on the text line the
  /// knob belongs to (the knob hangs below its line, so aim up and onto it).
  Offset _handleTarget(Offset global, double lineHeight) {
    return _editorLocalFromGlobal(global) +
        Offset(0, -(_knob / 2 + lineHeight / 2));
  }

  /// Word-style selection handle: a thin vertical bar along the first/last
  /// selected line and a round knob hanging below it. Drag the knob up or down
  /// to grow or shrink the selection line by line.
  Widget _handle({required Rect rect, required bool startHandle}) {
    const double boxW = 64;
    const double bar = 2.5;
    final double lineH = rect.height;
    final double boxH = lineH + _knob + 30;
    final Color color = Theme.of(context).colorScheme.primary;
    final double x = startHandle ? rect.left : rect.right;
    // Knob centre (inside the box). The start knob hangs to the left of its
    // bar and the end knob to the right, like Word.
    final double knobCx = boxW / 2 + (startHandle ? -(_knob / 2 - 1) : (_knob / 2 - 1));
    final double knobCy = lineH + _knob / 2 - 1;
    return Positioned(
      left: x - boxW / 2,
      top: rect.top,
      width: boxW,
      height: boxH,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: boxW / 2 - bar / 2,
            top: 0,
            width: bar,
            height: lineH,
            child: IgnorePointer(child: ColoredBox(color: color)),
          ),
          Positioned(
            left: knobCx - _knob / 2,
            top: knobCy - _knob / 2,
            width: _knob,
            height: _knob,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(startHandle ? _knob / 2 : 0),
                    topRight: Radius.circular(startHandle ? 0 : _knob / 2),
                    bottomLeft: const Radius.circular(_knob / 2),
                    bottomRight: const Radius.circular(_knob / 2),
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(blurRadius: 2, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),
          // Large invisible touch target around the knob.
          Positioned(
            left: knobCx - 26,
            top: knobCy - 26,
            width: 52,
            height: 52,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (DragStartDetails d) {
                _handleDragStart(startHandle: startHandle);
                _startSelectionDrag(_handleTarget(d.globalPosition, lineH));
              },
              onPanUpdate: (DragUpdateDetails d) => _updateSelectionDrag(
                _handleTarget(d.globalPosition, lineH),
              ),
              onPanEnd: (_) => _stopSelectionDrag(),
              onPanCancel: _stopSelectionDrag,
            ),
          ),
        ],
      ),
    );
  }

  void _onWordPointerEnd(PointerEvent event) {
    if (_visualDragging) {
      _endVisualDrag();
      return;
    }
    if (_forwarding && !_selectDrag) return;
    _longPress?.cancel();
    if (_selectDrag) {
      _selectDrag = false;
      _stopSelectionDrag();
      _touchPositions.remove(event.pointer);
      return;
    }
    final bool wasTap = event is PointerUpEvent &&
        !_moved &&
        _touchPositions.length == 1 &&
        _downPos != null &&
        _downAt != null &&
        DateTime.now().difference(_downAt!).inMilliseconds < 450;
    if (wasTap) {
      final Offset at = _downPos!;
      _downPos = null;
      _forwardTaps(at);
    }
    _touchPositions.remove(event.pointer);
    if (_touchPositions.length < 2) {
      _lastPinchDistance = null;
      if (_pinching) {
        _pinching = false;
        if (_phoneView) _applyPhoneView(true);
      }
    }
  }

  String? _selectedWordsLabel() {
    final List<WmlParagraph> paras = _paras;
    final CaretEngine c = _controller.caret;
    if (paras.isEmpty || c.selectionAnchorParagraph != c.paragraphIndex) {
      return null;
    }
    final String text = paras[c.paragraphIndex.clamp(0, paras.length - 1)].text;
    final int a = math.min(c.selectionAnchor, c.logicalIndex).clamp(0, text.length);
    final int b = math.max(c.selectionAnchor, c.logicalIndex).clamp(0, text.length);
    final int words = text
        .substring(a, b)
        .split(RegExp(r'\s+'))
        .where((String w) => w.isNotEmpty)
        .length;
    return words == 1 ? '1 word' : '$words words';
  }

  int _wordEnd(String t, int i) {
    int k = i;
    while (k < t.length && t[k].trim().isEmpty) {
      k++;
    }
    while (k < t.length && t[k].trim().isNotEmpty) {
      k++;
    }
    return k;
  }

  int _wordStart(String t, int i) {
    int k = i;
    while (k > 0 && t[k - 1].trim().isEmpty) {
      k--;
    }
    while (k > 0 && t[k - 1].trim().isNotEmpty) {
      k--;
    }
    return k;
  }

  bool _isSentenceEnd(String ch) => '.!?\u061F\u06D4'.contains(ch);

  /// Selects the whole sentence around the caret/selection.
  void _selectSentence() {
    final List<WmlParagraph> paras = _paras;
    final CaretEngine c = _controller.caret;
    if (paras.isEmpty) return;
    final int pi = c.paragraphIndex.clamp(0, paras.length - 1);
    final String t = paras[pi].text;
    if (t.isEmpty) return;
    final int at = math.min(c.selectionAnchor, c.logicalIndex).clamp(0, t.length);
    int start = at;
    while (start > 0) {
      final String prev = t[start - 1];
      if (_isSentenceEnd(prev) && start < t.length && t[start].trim().isEmpty) {
        break;
      }
      start--;
    }
    while (start < t.length && t[start].trim().isEmpty) {
      start++;
    }
    int end = math.max(at, start);
    while (end < t.length && !_isSentenceEnd(t[end])) {
      end++;
    }
    if (end < t.length) end++; // include the full stop
    c.selectionAnchorParagraph = pi;
    c.selectionAnchor = start;
    c.logicalIndex = end;
    _controller.refresh();
  }

  /// Grows the selection by one word on the right or left side.
  void _extendSelection({required bool right}) {
    final List<WmlParagraph> paras = _paras;
    final CaretEngine c = _controller.caret;
    if (paras.isEmpty || c.selectionAnchorParagraph != c.paragraphIndex) return;
    final String text = paras[c.paragraphIndex.clamp(0, paras.length - 1)].text;
    int a = c.selectionAnchor.clamp(0, text.length);
    int f = c.logicalIndex.clamp(0, text.length);
    final bool forward = a <= f;
    if (right) {
      if (forward) {
        f = _wordEnd(text, f);
      } else {
        a = _wordEnd(text, a);
      }
    } else {
      if (forward) {
        a = _wordStart(text, a);
      } else {
        f = _wordStart(text, f);
      }
    }
    c.selectionAnchor = a;
    c.logicalIndex = f;
    _controller.refresh();
  }

  List<Widget> _handleWidgets() {
    final ({Offset start, Offset end, List<Rect> rects, Rect startRect, Rect endRect})?
        ends = _selectionEnds();
    if (ends == null) return const <Widget>[];
    bool visible(Offset p) => p.dy > 0 && p.dy < _canvasSize.height - 4 && p.dx > -20;
    return <Widget>[
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _SelectionPainter(
              ends.rects,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
        ),
      ),
      if (visible(ends.start)) _handle(rect: ends.startRect, startHandle: true),
      if (visible(ends.end)) _handle(rect: ends.endRect, startHandle: false),
    ];
  }

  Widget _viewSelectionBar() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _selectedWordsLabel() ?? 'Selected',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_outlined),
              onPressed: _controller.copyToClipboard,
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
              onPressed: () {
                _setEditing(true);
                _ensureEditing();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Compact rich-text bar shown above the keyboard while editing.
  Widget _selectionBar() {
    final int sizePt = (_sizeHalfNow / 2).round();
    final String? highlight =
        _typing.highlightSet ? _typing.highlight : _controller.activeRunProps.highlight;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(28),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _selectedWordsLabel() ?? 'Selected',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _icon(Icons.copy, _controller.copyToClipboard, tooltip: 'Copy'),
            _icon(Icons.content_cut, _controller.cutToClipboard, tooltip: 'Cut'),
            _icon(Icons.content_paste, () => _controller.pasteFromClipboard(), tooltip: 'Paste'),
            _icon(Icons.format_bold, _toggleBold, tooltip: 'Bold', active: _boldNow),
            _icon(Icons.format_italic, _toggleItalic, tooltip: 'Italic', active: _italicNow),
            _icon(Icons.format_underlined, _toggleUnderline, tooltip: 'Underline', active: _underNow),
            _icon(Icons.text_decrease, () => _stepSize(-1), tooltip: 'Smaller'),
            Text('$sizePt', style: const TextStyle(fontWeight: FontWeight.w600)),
            _icon(Icons.text_increase, () => _stepSize(1), tooltip: 'Larger'),
            _colorButton(
              tooltip: 'Text color',
              color: _hexColor(_typing.color ?? _controller.activeRunProps.color),
              onSelected: _setColor,
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
              onSelected: (int level) {
                _ensureEditing();
                _controller.applyHeading(level);
              },
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
    );
  }

  Widget _fullFormattingToolbar() {
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
            _colorButton(
              tooltip: 'Text color',
              color: _hexColor(color),
              onSelected: _setColor,
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
              onSelected: (int level) {
                _ensureEditing();
                _controller.applyHeading(level);
              },
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

  void _showMoreFormatting() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (BuildContext context, ScrollController scrollController) =>
            Material(
          color: Theme.of(context).colorScheme.surface,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: <Widget>[
              Text('More formatting', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Formatting applies to the selected text or to text typed next.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _fullFormattingToolbar(),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.format_color_fill),
                title: Text('Highlight and font color'),
                subtitle: Text('Choose colors from the controls above'),
              ),
              const ListTile(
                leading: Icon(Icons.format_list_bulleted),
                title: Text('Bullets, numbering and alignment'),
                subtitle: Text('Use the paragraph controls above'),
              ),
              const ListTile(
                leading: Icon(Icons.search),
                title: Text('Find'),
                subtitle: Text('Document search remains available from the editor'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbar() {
    final WmlRunProps run = _controller.activeRunProps;
    final String? highlight =
        _typing.highlightSet ? _typing.highlight : run.highlight;
    return Material(
      elevation: 6,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _icon(Icons.undo, _controller.undo, tooltip: 'Undo', active: _controller.canUndo),
              _icon(Icons.redo, _controller.redo, tooltip: 'Redo', active: _controller.canRedo),
              _icon(Icons.format_bold, _toggleBold, tooltip: 'Bold', active: _boldNow),
              _icon(Icons.format_italic, _toggleItalic, tooltip: 'Italic', active: _italicNow),
              _icon(Icons.format_underlined, _toggleUnderline, tooltip: 'Underline', active: _underNow),
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
              _colorButton(
                tooltip: 'Font color',
                color: _hexColor(_typing.color ?? run.color),
                onSelected: _setColor,
              ),

              IconButton(
                tooltip: 'More formatting',
                icon: const Icon(Icons.more_horiz),
                onPressed: _showMoreFormatting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorButton({
    required String tooltip,
    required Color color,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      icon: SizedBox(
        width: 28,
        height: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'A',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 1),
            Container(
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
      onSelected: onSelected,
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
                const SizedBox(width: 10),
                Text(value),
              ],
            ),
          ),
      ],
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
      final Widget canvas = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          _canvasSize = Size(c.maxWidth, c.maxHeight);
          return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: c.maxWidth + _editorExtra,
            maxWidth: c.maxWidth + _editorExtra,
            child: Transform.translate(
              offset: const Offset(-64, 0),
              child: IgnorePointer(ignoring: !_forwarding, child: editor),
            ),
          ),
          );
        },
      );
      body = Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              key: _editorStackKey,
              children: <Widget>[
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _onWordPointerDown,
                    onPointerMove: _onWordPointerMove,
                    onPointerUp: _onWordPointerEnd,
                    onPointerCancel: _onWordPointerEnd,
                    child: canvas,
                  ),
                ),
                _verticalScrollbar(),
                ..._handleWidgets(),
                if (!_editing && !_controller.caret.isCollapsed)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Center(child: _viewSelectionBar()),
                  ),
                if (_editing && !_controller.caret.isCollapsed)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Center(child: _selectionBar()),
                  ),
              ],
            ),
          ),
          if (_editing) SafeArea(top: false, child: _toolbar()),
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
    _keyboardCaretFollowTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _longPress?.cancel();
    _stopSelectionDrag();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }
}

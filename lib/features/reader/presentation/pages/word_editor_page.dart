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
    this.highlight,
  );

  final int start;
  final int end;
  final bool bold;
  final bool italic;
  final bool underline;
  final double size;
  final Color color;
  final Color? highlight;
}

class _WordPageBackground extends CustomPainter {
  const _WordPageBackground({
    required this.pageCount,
    required this.borderColor,
    required this.pageColor,
  });

  final int pageCount;
  final Color borderColor;
  final Color pageColor;

  @override
  void paint(Canvas canvas, Size size) {
    const double pageHeight = 760;
    final Paint fill = Paint()..color = pageColor;
    final Paint border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int page = 0; page < pageCount; page++) {
      final double top = page * pageHeight;
      final Rect rect = Rect.fromLTWH(0, top, size.width, pageHeight - 14);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, border);
    }
  }

  @override
  bool shouldRepaint(_WordPageBackground oldDelegate) =>
      oldDelegate.pageCount != pageCount ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.pageColor != pageColor;
}

class _RichWordEditingController extends TextEditingController {
  _RichWordEditingController({
    required this.ranges,
    required this.defaultStyle,
  });

  final List<_FormatRange> Function() ranges;
  final TextStyle defaultStyle;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final String value = text;
    if (value.isEmpty) {
      return TextSpan(text: value, style: style ?? defaultStyle);
    }

    final List<int> cuts = <int>[0, value.length];
    for (final _FormatRange range in ranges()) {
      if (range.end > 0 && range.start < value.length) {
        cuts
          ..add(range.start.clamp(0, value.length))
          ..add(range.end.clamp(0, value.length));
      }
    }
    cuts.sort();
    final List<int> uniqueCuts = <int>[];
    for (final int cut in cuts) {
      if (uniqueCuts.isEmpty || uniqueCuts.last != cut) {
        uniqueCuts.add(cut);
      }
    }

    final List<TextSpan> spans = <TextSpan>[];
    final List<_FormatRange> allRanges = ranges();
    for (int i = 0; i < uniqueCuts.length - 1; i++) {
      final int start = uniqueCuts[i];
      final int end = uniqueCuts[i + 1];
      if (start == end) continue;

      _FormatRange? format;
      for (final _FormatRange range in allRanges.reversed) {
        if (start >= range.start && start < range.end) {
          format = range;
          break;
        }
      }

      final TextStyle spanStyle = format == null
          ? (style ?? defaultStyle)
          : (style ?? defaultStyle).copyWith(
              fontSize: format.size,
              fontWeight: format.bold ? FontWeight.bold : FontWeight.normal,
              fontStyle: format.italic ? FontStyle.italic : FontStyle.normal,
              decoration:
                  format.underline ? TextDecoration.underline : TextDecoration.none,
              color: format.color,
              backgroundColor: format.highlight,
            );
      spans.add(TextSpan(text: value.substring(start, end), style: spanStyle));
    }

    return TextSpan(style: style ?? defaultStyle, children: spans);
  }
}

class _WordEditorPageState extends State<WordEditorPage> {
  late final _RichWordEditingController _text;
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
  Color? _highlight;
  TextAlign _align = TextAlign.left;
  String? _error;
  String _lastText = '';
  bool _restoringText = false;
  // A4 portrait: 210 x 297 mm. The editor uses a fixed A4 logical page and
  // keeps the document content inside Word-like margins.
  static const double _a4AspectRatio = 210 / 297;
  static const double _a4ContentHeight = 734;
  static const double _lineHeight = 1.35;
  static const int _linesPerPage = 49;
  final List<_RichWordEditingController> _pageControllers = <_RichWordEditingController>[];
  int _activePageIndex = 0;

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
    _text = _RichWordEditingController(
      ranges: () => _ranges,
      defaultStyle: const TextStyle(fontSize: 11, color: Colors.black),
    );
    _text.addListener(_recordTextChange);
    _load();
  }

  void _recordTextChange() {
    if (_restoringText || _text.text == _lastText) return;
    final String oldValue = _lastText;
    final String newValue = _text.text;

    int prefix = 0;
    while (prefix < oldValue.length &&
        prefix < newValue.length &&
        oldValue.codeUnitAt(prefix) == newValue.codeUnitAt(prefix)) {
      prefix++;
    }
    int oldSuffix = oldValue.length;
    int newSuffix = newValue.length;
    while (oldSuffix > prefix &&
        newSuffix > prefix &&
        oldValue.codeUnitAt(oldSuffix - 1) ==
            newValue.codeUnitAt(newSuffix - 1)) {
      oldSuffix--;
      newSuffix--;
    }

    final int removed = oldSuffix - prefix;
    final int inserted = newSuffix - prefix;
    final int delta = inserted - removed;

    if (removed > 0) {
      final List<_FormatRange> adjusted = <_FormatRange>[];
      for (final _FormatRange range in _ranges) {
        if (range.end <= prefix) adjusted.add(range);
        else if (range.start >= oldSuffix) adjusted.add(_copyRange(range, range.start + delta, range.end + delta));
        else {
          final int newStart = range.start < prefix ? range.start : prefix;
          final int newEnd = range.end > oldSuffix ? range.end + delta : prefix;
          if (newEnd > newStart) adjusted.add(_copyRange(range, newStart, newEnd));
        }
      }
      _ranges..clear()..addAll(_mergeAdjacentRanges(adjusted));
    } else if (delta != 0) {
      for (int i = 0; i < _ranges.length; i++) {
        final _FormatRange range = _ranges[i];
        if (range.start >= prefix) _ranges[i] = _copyRange(range, range.start + delta, range.end + delta);
      }
    }

    if (inserted > 0 &&
        (_bold ||
            _italic ||
            _underline ||
            _size != 11 ||
            _color != Colors.black)) {
      _ranges.add(
        _FormatRange(
          prefix,
          newSuffix,
          _bold,
          _italic,
          _underline,
          _size,
          _color,
          _highlight,
        ),
      );
    }

    _undoStack.add(oldValue);
    _redoStack.clear();
    _lastText = newValue;
    if (mounted) setState(() {});
  }

  List<String> _splitIntoPages([String? source]) {
    final List<String> lines = (source ?? _text.text).split('\n');
    final List<String> pages = <String>[];
    for (int i = 0; i < lines.length; i += _linesPerPage) {
      final int end = (i + _linesPerPage).clamp(0, lines.length);
      pages.add(lines.sublist(i, end).join('\n'));
    }
    return pages.isEmpty ? <String>[''] : pages;
  }

  int _pageBaseOffset(int pageIndex, [String? source]) {
    final List<String> pages = _splitIntoPages(source);
    int offset = 0;
    for (int i = 0; i < pageIndex && i < pages.length; i++) {
      offset += pages[i].length + 1;
    }
    return offset;
  }

  List<_FormatRange> _rangesForPage(int pageIndex, String pageText) {
    final int base = _pageBaseOffset(pageIndex);
    final int end = base + pageText.length;
    return <_FormatRange>[
      for (final _FormatRange range in _ranges)
        if (range.end > base && range.start < end)
          _FormatRange(
            range.start.clamp(base, end) - base,
            range.end.clamp(base, end) - base,
            range.bold,
            range.italic,
            range.underline,
            range.size,
            range.color,
            range.highlight,
          ),
    ];
  }

  void _disposePageControllers() {
    for (final _RichWordEditingController controller in _pageControllers) {
      controller.dispose();
    }
    _pageControllers.clear();
  }

  void _rebuildPageControllers({int? preferredPage}) {
    _disposePageControllers();
    final List<String> pages = _splitIntoPages();
    final int selected = (preferredPage ?? _activePageIndex).clamp(0, pages.length - 1);
    for (int i = 0; i < pages.length; i++) {
      final int pageIndex = i;
      final _RichWordEditingController controller = _RichWordEditingController(
        ranges: () => _rangesForPage(pageIndex, _pageControllers[pageIndex].text),
        defaultStyle: const TextStyle(fontSize: 11, color: Colors.black),
      );
      controller.text = pages[i];
      controller.addListener(() {
        if (!mounted) return;
        _activePageIndex = pageIndex;
        final TextSelection selection = controller.selection;
        if (selection.isValid) {
          final int base = _pageBaseOffset(pageIndex);
          _text.selection = TextSelection(
            baseOffset: (base + selection.baseOffset).clamp(0, _text.text.length),
            extentOffset: (base + selection.extentOffset).clamp(0, _text.text.length),
          );
        }
      });
      _pageControllers.add(controller);
    }
    _activePageIndex = selected;
  }

  void _onPageTextChanged(int pageIndex, String value) {
    if (pageIndex >= _pageControllers.length) return;
    final List<String> pages = _pageControllers.map((c) => c.text).toList();
    pages[pageIndex] = value;
    final String combined = pages.join('\n');
    final TextSelection localSelection = _pageControllers[pageIndex].selection;
    final int base = _pageBaseOffset(pageIndex);
    _text.value = TextEditingValue(
      text: combined,
      selection: TextSelection(
        baseOffset: (base + localSelection.baseOffset).clamp(0, combined.length),
        extentOffset: (base + localSelection.extentOffset).clamp(0, combined.length),
      ),
    );
    _activePageIndex = pageIndex;
    if (value.split('\n').length > _linesPerPage) {
      _setEditorText(combined);
      _rebuildPageControllers(preferredPage: pageIndex);
    }
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
    _rebuildPageControllers(preferredPage: _activePageIndex);
    setState(() {});
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_text.text);
    final String value = _redoStack.removeLast();
    _setEditorText(value);
    _rebuildPageControllers(preferredPage: _activePageIndex);
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

  bool _xmlToggle(String xml, String tag) {
    final RegExpMatch? match = RegExp('<w:$tag(?: [^>]*)?\\s*/?>').firstMatch(xml);
    if (match == null) return false;
    final String value = RegExp(r'w:val="([^"]+)"').firstMatch(match.group(0) ?? '')?.group(1) ?? '';
    return value.isEmpty || (value != '0' && value != 'false' && value != 'off');
  }

  double _headingSize(String style) {
    switch (style.toLowerCase()) {
      case 'heading1':
      case 'title':
        return 24;
      case 'heading2':
        return 18;
      case 'heading3':
        return 14;
      default:
        return 11;
    }
  }

  Color _docxColor(String value) {
    final String hex = value.replaceAll('#', '').trim();
    if (hex.length != 6) return Colors.black;
    final int? rgb = int.tryParse(hex, radix: 16);
    return rgb == null ? Colors.black : Color(0xFF000000 | rgb);
  }

  Color? _docxHighlight(String value) {
    const Map<String, Color> named = <String, Color>{
      'yellow': Colors.yellow,
      'green': Colors.green,
      'cyan': Colors.cyan,
      'magenta': Colors.pinkAccent,
      'red': Colors.redAccent,
      'blue': Colors.lightBlueAccent,
      'darkYellow': Colors.amber,
      'lightGray': Color(0xFFE0E0E0),
      'gray': Color(0xFFBDBDBD),
    };
    if (named.containsKey(value)) return named[value];
    final String hex = value.replaceAll('#', '').trim();
    if (hex.length == 6) {
      final int? rgb = int.tryParse(hex, radix: 16);
      if (rgb != null) return Color(0xFF000000 | rgb);
    }
    return null;
  }

  String _readDocxParagraph(String block, int baseOffset) {
    final String style = RegExp(r'<w:pStyle[^>]*w:val="([^"]+)"[^>]*/?>')
            .firstMatch(block)?.group(1) ??
        '';
    final bool heading = style.toLowerCase().startsWith('heading') ||
        style.toLowerCase() == 'title';
    final double defaultSize = _headingSize(style);
    final bool defaultBold = heading;
    final List<String> pieces = <String>[];
    int localOffset = 0;
    for (final RegExpMatch run in RegExp(r'<w:r(?: [^>]*)?>.*?</w:r>', dotAll: true).allMatches(block)) {
      final String runXml = run.group(0)!;
      final String rPr = RegExp(r'<w:rPr(?: [^>]*)?>(.*?)</w:rPr>', dotAll: true)
              .firstMatch(runXml)?.group(1) ??
          '';
      String runText = RegExp(r'<w:t(?: [^>]*)?>(.*?)</w:t>', dotAll: true)
          .allMatches(runXml)
          .map((RegExpMatch m) => _unescape(m.group(1)!))
          .join();
      if (runText.isEmpty) {
        if (runXml.contains('<w:tab')) runText = '\t';
        if (runXml.contains('<w:br')) runText = '\n';
      }
      if (runText.isEmpty) continue;
      final bool bold = rPr.contains('<w:b') ? _xmlToggle(rPr, 'b') : defaultBold;
      final bool italic = _xmlToggle(rPr, 'i');
      final bool underline = _xmlToggle(rPr, 'u');
      final RegExpMatch? sizeMatch = RegExp(r'<w:sz[^>]*w:val="([0-9]+)"').firstMatch(rPr);
      final double size = sizeMatch == null
          ? defaultSize
          : (double.tryParse(sizeMatch.group(1)!) ?? (defaultSize * 2)) / 2;
      final RegExpMatch? colorMatch = RegExp(r'<w:color[^>]*w:val="([^"]+)"').firstMatch(rPr);
      final Color color = colorMatch == null ? Colors.black : _docxColor(colorMatch.group(1)!);
      final RegExpMatch? highlightMatch = RegExp(r'<w:highlight[^>]*w:val="([^"]+)"').firstMatch(rPr);
      final RegExpMatch? shadingMatch = RegExp(r'<w:shd[^>]*w:fill="([^"]+)"').firstMatch(rPr);
      final Color? highlight = highlightMatch != null
          ? _docxHighlight(highlightMatch.group(1)!)
          : shadingMatch != null ? _docxHighlight(shadingMatch.group(1)!) : null;
      final int start = localOffset;
      final int end = start + runText.length;
      if (bold || italic || underline || size != 11 || color != Colors.black || highlight != null) {
        _ranges.add(_FormatRange(baseOffset + start, baseOffset + end, bold, italic, underline, size, color, highlight));
      }
      pieces.add(runText);
      localOffset = end;
    }
    if (pieces.isEmpty) {
      final String plain = RegExp(r'<w:t(?: [^>]*)?>(.*?)</w:t>', dotAll: true)
          .allMatches(block).map((RegExpMatch m) => _unescape(m.group(1)!)).join();
      if (plain.isNotEmpty && (defaultBold || defaultSize != 11)) {
        _ranges.add(_FormatRange(baseOffset, baseOffset + plain.length, defaultBold, false, false, defaultSize, Colors.black, null));
      }
      return plain;
    }
    return pieces.join();
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
        _ranges.clear();
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
            final int baseOffset = loadedParagraphs.join('\n').length +
                (loadedParagraphs.isEmpty ? 0 : 1);
            loadedParagraphs.add(_readDocxParagraph(content, baseOffset));
          }
        }
        _setEditorText(loadedParagraphs.join('\n'));
        _rebuildPageControllers();
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
    _rebuildPageControllers(preferredPage: _activePageIndex);
    setState(() {});
  }

  void _insertBlankPage() {
    final List<String> pages = _splitIntoPages();
    final int insertAt = (_activePageIndex + 1).clamp(0, pages.length);
    pages.insert(insertAt, List<String>.filled(_linesPerPage, '').join('\n'));
    _setEditorText(pages.join('\n'));
    _rebuildPageControllers(preferredPage: insertAt);
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

  void _applyFormat({bool? bold, bool? italic, bool? underline, double? size, Color? color, Color? highlight, bool clearHighlight = false}) {
    final TextSelection selection = _text.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final int start = selection.start;
    final int end = selection.end;
    final List<_FormatRange> next = <_FormatRange>[];
    for (final _FormatRange range in _ranges) {
      if (range.end <= start || range.start >= end) {
        next.add(range);
      } else {
        if (range.start < start) next.add(_copyRange(range, range.start, start));
        if (range.end > end) next.add(_copyRange(range, end, range.end));
      }
    }
    _FormatRange base = _FormatRange(start, end, _bold, _italic, _underline, _size, _color, _highlight);
    for (final _FormatRange range in _ranges.reversed) {
      if (range.start <= start && range.end > start) {
        base = _FormatRange(start, end, bold ?? range.bold, italic ?? range.italic, underline ?? range.underline, size ?? range.size, color ?? range.color, clearHighlight ? null : (highlight ?? range.highlight));
        break;
      }
    }
    next.add(base);
    next.sort((_FormatRange a, _FormatRange b) => a.start.compareTo(b.start));
    _ranges..clear()..addAll(_mergeAdjacentRanges(next));
    setState(() {});
  }

  _FormatRange _copyRange(_FormatRange r, int start, int end) => _FormatRange(start, end, r.bold, r.italic, r.underline, r.size, r.color, r.highlight);

  List<_FormatRange> _mergeAdjacentRanges(List<_FormatRange> ranges) {
    if (ranges.isEmpty) return <_FormatRange>[];
    final List<_FormatRange> merged = <_FormatRange>[ranges.first];
    for (final _FormatRange r in ranges.skip(1)) {
      final _FormatRange last = merged.last;
      if (last.end == r.start && last.bold == r.bold && last.italic == r.italic && last.underline == r.underline && last.size == r.size && last.color == r.color && last.highlight == r.highlight) {
        merged[merged.length - 1] = _copyRange(last, last.start, r.end);
      } else {
        merged.add(r);
      }
    }
    return merged;
  }

  String _props(_FormatRange? range) {
    if (range == null) return '';
    final String color =
        range.color.value.toRadixString(16).substring(2).toUpperCase();
    return '<w:rPr>'
        '${range.bold ? '<w:b/>' : ''}'
        '${range.italic ? '<w:i/>' : ''}'
        '${range.underline ? '<w:u w:val="single"/>' : ''}'
        '${range.highlight == null ? '' : '<w:shd w:val="clear" w:fill="' + range.highlight!.value.toRadixString(16).substring(2).toUpperCase() + '"/>'}'
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
      final Archive archive = ZipDecoder().decodeBytes(await File(_path).readAsBytes());
      final ArchiveFile? old = archive.findFile('word/document.xml');
      if (old == null) throw const FormatException('Missing document.xml');
      final List<String> pages = _splitIntoPages();
      int pageBase = 0;
      final List<String> parts = <String>[];
      for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
        final List<String> paragraphs = pages[pageIndex].split('\n');
        int paragraphBase = pageBase;
        for (final String paragraph in paragraphs) {
          final _TableModel? table = _tableForToken(paragraph);
          if (table != null) {
            parts.add(_tableXml(table));
          } else {
            final int? numId = _isBullet(paragraph) ? 1 : _isNumbered(paragraph) ? 2 : null;
            parts.add(_paragraphXml(_plainListText(paragraph), paragraphBase, number: numId));
          }
          paragraphBase += paragraph.length + 1;
        }
        pageBase += pages[pageIndex].length + 1;
        if (pageIndex < pages.length - 1) {
          parts.add('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to the same DOCX file')));
    } on Object catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save DOCX: $error')));
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
                    final bool value = !_bold;
                    setState(() => _bold = value);
                    _applyFormat(bold: value);
                  },
                  _bold,
                ),
                _tool(
                  Icons.format_italic,
                  () {
                    final bool value = !_italic;
                    setState(() => _italic = value);
                    _applyFormat(italic: value);
                  },
                  _italic,
                ),
                _tool(
                  Icons.format_underline,
                  () {
                    final bool value = !_underline;
                    setState(() => _underline = value);
                    _applyFormat(underline: value);
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
                      _applyFormat(size: size);
                    }
                  },
                ),
                PopupMenuButton<Color>(
                  tooltip: 'Text color',
                  icon: Icon(Icons.format_color_text, color: _color),
                  onSelected: (Color value) {
                    setState(() => _color = value);
                    _applyFormat(color: value);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<Color>>[
                    for (final Color value in <Color>[
                      Colors.black, Colors.red, Colors.blue, Colors.green,
                      Colors.orange, Colors.purple, Colors.teal, Colors.brown,
                    ])
                      PopupMenuItem<Color>(
                        value: value,
                        child: Row(children: <Widget>[
                          Icon(Icons.circle, color: value, size: 18),
                          const SizedBox(width: 10),
                          Text(value.toString()),
                        ]),
                      ),
                  ],
                ),
                PopupMenuButton<Color?>(
                  tooltip: 'Highlight',
                  icon: Icon(Icons.highlight, color: _highlight ?? Colors.amber),
                  onSelected: (Color? value) {
                    setState(() => _highlight = value);
                    _applyFormat(highlight: value, clearHighlight: value == null);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<Color?>>[
                    const PopupMenuItem<Color?>(value: null, child: Text('No highlight')),
                    for (final Color value in <Color>[
                      Colors.yellow, Color(0xFFFFCC80), Color(0xFFB3E5FC),
                      Color(0xFFC8E6C9), Color(0xFFE1BEE7), Color(0xFFFFCDD2),
                    ])
                      PopupMenuItem<Color?>(
                        value: value,
                        child: Row(children: <Widget>[
                          Icon(Icons.highlight, color: value),
                          const SizedBox(width: 10),
                          const Text('Highlight'),
                        ]),
                      ),
                  ],
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
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _pageControllers.length,
              itemBuilder: (BuildContext context, int pageIndex) {
                final _RichWordEditingController controller = _pageControllers[pageIndex];
                final bool active = _activePageIndex == pageIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6, right: 4),
                          child: Text(
                            'Page ' + (pageIndex + 1).toString() + ' of ' + _pageControllers.length.toString(),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                      Material(
                        color: Theme.of(context).colorScheme.surface,
                        elevation: active ? 2 : 1,
                        child: AspectRatio(
                          aspectRatio: _a4AspectRatio,
                          child: Container(
                            decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                            child: TextField(
                              controller: controller,
                              maxLines: _linesPerPage,
                              minLines: _linesPerPage,
                              scrollPhysics: const NeverScrollableScrollPhysics(),
                              onTap: () {
                              _activePageIndex = pageIndex;
                              final TextSelection selection = controller.selection;
                              if (selection.isValid) {
                                final int base = _pageBaseOffset(pageIndex);
                                _text.selection = TextSelection(
                                  baseOffset: (base + selection.baseOffset).clamp(0, _text.text.length),
                                  extentOffset: (base + selection.extentOffset).clamp(0, _text.text.length),
                                );
                              }
                              setState(() {});
                            },
                              onChanged: (String value) => _onPageTextChanged(pageIndex, value),
                              textAlign: _align,
                              style: const TextStyle(fontSize: 11, height: _lineHeight, color: Colors.black),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.fromLTRB(54, 54, 54, 54),
                                hintText: 'Start writing…',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
    _disposePageControllers();
    _text.dispose();
    super.dispose();
  }
}

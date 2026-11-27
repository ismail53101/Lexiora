import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lexiora/features/reader/data/pdf_edit_service.dart';
import 'package:path/path.dart' as p;


/// Full-screen PDF Edit Mode.
///
/// This page is intentionally separate from [ReaderPage]: the established
/// pdfrx viewer remains the Reader Mode implementation, while this editor owns
/// its own revision history and emits complete PDF bytes on save.
class PdfEditPage extends StatefulWidget {
  const PdfEditPage({
    super.key,
    required this.filePath,
    required this.title,
  });

  final String filePath;
  final String title;

  @override
  State<PdfEditPage> createState() => _PdfEditPageState();
}

class _PdfEditPageState extends State<PdfEditPage> {
  final PdfEditService _saveService = const PdfEditService();
  late final Future<Uint8List> _bytes;
  PdfEditingController? _editing;
  bool _saving = false;
  bool _didOverwrite = false;
  bool _openingTextEditor = false;
  String? _lastTextSelectionKey;

  @override
  void initState() {
    super.initState();
    _bytes = File(widget.filePath).readAsBytes();
  }

  void _ensureEditingController(Uint8List bytes) {
    if (_editing != null) return;
    final PdfEditingController editing = PdfEditingController(bytes);
    editing.addListener(_onEditingChanged);
    _editing = editing;
  }

  void _onEditingChanged() {
    final PdfEditingController? editing = _editing;
    if (!mounted || editing == null || _openingTextEditor || _saving) return;

    // Some PDFs draw every character as a separate text run. The editor
    // exposes selectedElementEditText as the whole word represented by the
    // selected glyph, so edit the word instead of moving one letter.
    if (!editing.canEditSelectedElementText) return;
    final String? text = editing.selectedElementEditText;
    final int? page = editing.selectedElementPage;
    if (text == null || page == null || text.isEmpty) return;

    final String key = '$page::$text';
    if (key == _lastTextSelectionKey) return;
    _lastTextSelectionKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _openingTextEditor || _saving) return;
      final PdfEditingController? current = _editing;
      if (current == null || !current.canEditSelectedElementText) return;
      final String? currentText = current.selectedElementEditText;
      if (currentText == null || currentText != text) return;
      unawaited(_openTextEditor(current, text));
    });
  }

  Future<void> _openTextEditor(
    PdfEditingController editing,
    String initialText,
  ) async {
    if (_openingTextEditor || !mounted) return;
    _openingTextEditor = true;

    final TextEditingController textController =
        TextEditingController(text: initialText);
    textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: textController.text.length,
    );

    try {
      final String? replacement = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (BuildContext sheetContext) {
          final double keyboardInset =
              MediaQuery.viewInsetsOf(sheetContext).bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, keyboardInset + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.edit_outlined),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Edit text',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cancel',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: textController,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 6,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Edit the selected PDF text',
                  ),
                  onSubmitted: (String value) =>
                      Navigator.of(sheetContext).pop(value),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(textController.text),
                  icon: const Icon(Icons.check),
                  label: const Text('Apply'),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted || replacement == null) return;
      if (replacement == initialText) return;
      if (!editing.canEditSelectedElementText) return;

      // Reflow preserves the PDF text flow and moves following lines when
      // the replacement changes its width/height.
      final bool changed = editing.reflowSelectedElementText(replacement);
      editing.clearElementSelection();
      if (!changed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This PDF text could not be rewritten safely.'),
          ),
        );
      }
    } finally {
      textController.dispose();
      _openingTextEditor = false;
      _lastTextSelectionKey = null;
    }
  }

  void _saveAs(Uint8List bytes) {
    if (_saving) return;
    setState(() => _saving = true);
    unawaited(_saveAsAndReport(bytes));
  }

  Future<void> _saveAsAndReport(Uint8List bytes) async {
    try {
      final Uri? outputUri = await FilePicker.saveFile(
        dialogTitle: 'Save edited PDF',
        fileName: p.basename(widget.filePath),
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      if (outputUri == null) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Edited PDF saved to $outputUri')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save PDF: $error')),
      );
    }
  }

  void _requestOverwrite(Uint8List bytes) {
    if (_saving) return;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Overwrite original PDF?'),
          content: const Text(
            'This replaces the current library file. Use Save PDF to keep '
            'the original and create a separate edited copy.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _overwrite(bytes);
              },
              child: const Text('Overwrite'),
            ),
          ],
        ),
      ),
    );
  }

  void _overwrite(Uint8List bytes) {
    if (_saving) return;
    setState(() => _saving = true);
    unawaited(_overwriteAndReport(bytes));
  }

  Future<void> _overwriteAndReport(Uint8List bytes) async {
    try {
      await _saveService.overwrite(filePath: widget.filePath, bytes: bytes);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _didOverwrite = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Original PDF overwritten and saved')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not overwrite PDF: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_saving || _openingTextEditor) return false;
        Navigator.of(context).pop(_didOverwrite);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Edit PDF: ${widget.title}',
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Close PDF editor',
            onPressed: _saving || _openingTextEditor
                ? null
                : () => Navigator.of(context).pop(_didOverwrite),
          ),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
        body: FutureBuilder<Uint8List>(
          future: _bytes,
          builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load this PDF for editing: ${snapshot.error}',
                  ),
                ),
              );
            }
            final Uint8List? bytes = snapshot.data;
            if (bytes == null) {
              return const Center(child: CircularProgressIndicator());
            }
            _ensureEditingController(bytes);
            final PdfEditingController editing = _editing!;

            return PdfEditorView(
              controller: editing,
              onSave: _saveAs,
              saveButtonLabel: 'Save PDF',
              toolbarTrailing: <PdfEditingToolbarWidgetBuilder>[
                (
                  BuildContext context,
                  PdfEditingController editing,
                  PdfViewerController viewer,
                ) => IconButton(
                  icon: const Icon(Icons.save_outlined),
                  tooltip: 'Overwrite original PDF',
                  onPressed: () => _requestOverwrite(editing.bytes),
                ),
              ],
              features: const PdfEditorFeatures(
                // Content selects real page elements. Its selected-element
                // strip exposes direct text replacement when the PDF run is
                // safely editable; freeText remains available for insertion.
                tools: <PdfEditTool>{
                  PdfEditTool.select,
                  PdfEditTool.content,
                  PdfEditTool.contentDelete,
                  PdfEditTool.freeText,
                  PdfEditTool.ink,
                },
                thumbnails: false,
                bookmarks: false,
                pageEditing: false,
                annotationSidebar: false,
                annotationLibrary: false,
                propertiesPanel: true,
                flatten: false,
                colorProcessing: false,
                reflowView: false,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _editing?.removeListener(_onEditingChanged);
    _editing?.dispose();
    super.dispose();
  }
}

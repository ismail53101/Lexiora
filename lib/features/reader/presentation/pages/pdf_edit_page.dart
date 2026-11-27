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
  PdfEditingController? _editingController;
  bool _saving = false;
  bool _didOverwrite = false;
  bool _pdfListenerAttached = false;
  bool _wasEditingText = false;
  (int, int)? _lastSelectedAnnotationSlot;
  bool _openingExistingText = false;

  @override
  void initState() {
    super.initState();
    _bytes = File(widget.filePath).readAsBytes();
  }

  Future<Uint8List?> _pickPdfImage(BuildContext context) async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (files.isEmpty) return null;
    final String? path = files.first.path;
    if (path == null || path.isEmpty) return null;
    return File(path).readAsBytes();
  }

  void _attachPdfEditingListener(PdfEditingController editing) {
    if (_pdfListenerAttached) return;
    _pdfListenerAttached = true;
    editing.addListener(() => _handlePdfEditingChanged(editing));
  }

  void _handlePdfEditingChanged(PdfEditingController editing) {
    if (!mounted || _openingExistingText) return;

    final bool editingText = editing.isEditingText;
    final (int, int)? selectedSlot = editing.selectedAnnotationSlot;

    // A text box was just committed. Return to Select so the next tap on the
    // same box selects/opens that existing box instead of creating another one.
    if (_wasEditingText && !editingText && editing.selectedFreeTextStyle != null) {
      editing.tool = PdfEditTool.select;
      _lastSelectedAnnotationSlot = selectedSlot;
      _wasEditingText = false;
      return;
    }

    _wasEditingText = editingText;
    if (editingText || editing.tool != PdfEditTool.select) {
      if (selectedSlot == null) _lastSelectedAnnotationSlot = null;
      return;
    }

    // Selection was cleared; allow the next tap on the same box to trigger
    // the inline editor again.
    if (selectedSlot == null) {
      _lastSelectedAnnotationSlot = null;
      return;
    }

    if (selectedSlot == _lastSelectedAnnotationSlot) return;
    _lastSelectedAnnotationSlot = selectedSlot;

    // Single-tap on an existing free-text box: reopen that exact box rather
    // than creating a new text box.
    if (editing.canRestyleSelectedText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            _openingExistingText ||
            editing.isEditingText ||
            editing.tool != PdfEditTool.select ||
            editing.selectedAnnotationSlot != selectedSlot ||
            !editing.canRestyleSelectedText) {
          return;
        }

        _openingExistingText = true;
        try {
          editing.requestEditSelectedTextInline();
        } finally {
          _openingExistingText = false;
        }
      });
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
        if (_saving) return false;
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
            onPressed: _saving
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
            final PdfEditingController editing =
                _editingController ??= PdfEditingController(bytes);
            _attachPdfEditingListener(editing);

            return PdfEditorView(
              controller: editing,
              onSave: _saveAs,
              imagePicker: _pickPdfImage,
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
                  PdfEditTool.image,
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
}

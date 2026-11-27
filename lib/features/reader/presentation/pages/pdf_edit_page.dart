import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:flutter/material.dart';
import 'package:lexiora/features/reader/data/pdf_edit_service.dart';

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
  bool _saving = false;
  bool _didSave = false;

  @override
  void initState() {
    super.initState();
    _bytes = File(widget.filePath).readAsBytes();
  }

  void _save(Uint8List bytes) {
    if (_saving) return;
    setState(() => _saving = true);
    unawaited(_saveAndReport(bytes));
  }

  Future<void> _saveAndReport(Uint8List bytes) async {
    try {
      await _saveService.overwrite(filePath: widget.filePath, bytes: bytes);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _didSave = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF saved')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save PDF: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_saving) return false;
        Navigator.of(context).pop(_didSave);
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
                : () => Navigator.of(context).pop(_didSave),
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
            return PdfEditorView(
              bytes: bytes,
              onSave: _save,
              saveButtonLabel: 'Save PDF',
              features: const PdfEditorFeatures(
                // Keep Edit Mode focused and compact. Select handles moving,
                // resizing, deleting, and editing inserted text annotations.
                tools: <PdfEditTool>{
                  PdfEditTool.select,
                  PdfEditTool.freeText,
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/features/library/data/services/google_drive_service.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/features/library/presentation/widgets/document_card.dart';

class DriveLibraryPage extends ConsumerStatefulWidget {
  const DriveLibraryPage({super.key});

  @override
  ConsumerState<DriveLibraryPage> createState() => _DriveLibraryPageState();
}

class _DriveLibraryPageState extends ConsumerState<DriveLibraryPage> {
  late Future<List<GoogleDrivePdf>> _files;
  String? _openingId;

  GoogleDriveService get _drive => ref.read(googleDriveServiceProvider);

  @override
  void initState() {
    super.initState();
    _files = _loadFiles();
  }

  Future<List<GoogleDrivePdf>> _loadFiles() async {
    await _drive.connect();
    return _drive.listPdfs();
  }

  void _refresh() {
    setState(() => _files = _loadFiles());
  }

  Future<void> _open(GoogleDrivePdf pdf) async {
    if (_openingId != null) return;
    setState(() => _openingId = pdf.id);
    try {
      final File cached = await _drive.downloadPdf(pdf);
      if (!mounted) return;
      final LibraryDocument temporaryDocument = LibraryDocument(
        id: 'drive_${pdf.id}',
        title: _displayTitle(pdf.name),
        fileName: pdf.name,
        filePath: cached.path,
        fileSize: pdf.size > 0 ? pdf.size : await cached.length(),
        pageCount: 0,
        isFavorite: false,
        importedAt: DateTime.now(),
        isManaged: false,
      );
      await context.push(AppRoutes.driveReader, extra: temporaryDocument);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Drive PDF unavailable: $error')),
      );
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  Future<void> _disconnect() async {
    await _drive.disconnect();
    await _drive.clearDriveCache();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Drive PDFs',
            onPressed: _openingId == null ? _refresh : null,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_off_outlined),
            tooltip: 'Disconnect Google Drive',
            onPressed: _openingId == null ? _disconnect : null,
          ),
        ],
      ),
      body: FutureBuilder<List<GoogleDrivePdf>>(
        future: _files,
        builder: (BuildContext context, AsyncSnapshot<List<GoogleDrivePdf>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DriveError(onRetry: _refresh, error: snapshot.error!);
          }
          final List<GoogleDrivePdf> files = snapshot.data ?? const <GoogleDrivePdf>[];
          if (files.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_outlined, size: 48),
                    SizedBox(height: 12),
                    Text('No PDF files found in Google Drive.'),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final Future<List<GoogleDrivePdf>> next = _loadFiles();
              setState(() => _files = next);
              await next;
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.60,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: files.length,
              itemBuilder: (BuildContext context, int index) => _DriveCard(
                pdf: files[index],
                drive: _drive,
                opening: _openingId == files[index].id,
                onOpen: () => _open(files[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  String _displayTitle(String name) =>
      name.replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '');
}

class _DriveCard extends StatefulWidget {
  const _DriveCard({
    required this.pdf,
    required this.drive,
    required this.opening,
    required this.onOpen,
  });

  final GoogleDrivePdf pdf;
  final GoogleDriveService drive;
  final bool opening;
  final VoidCallback onOpen;

  @override
  State<_DriveCard> createState() => _DriveCardState();
}

class _DriveCardState extends State<_DriveCard> {
  late Future<File?> _thumbnail;

  @override
  void initState() {
    super.initState();
    _thumbnail = widget.drive.downloadThumbnail(widget.pdf);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _thumbnail,
      builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
        final LibraryDocument document = LibraryDocument(
          id: 'drive_${widget.pdf.id}',
          title: widget.pdf.name.replaceFirst(
            RegExp(r'\.pdf$', caseSensitive: false),
            '',
          ),
          fileName: widget.pdf.name,
          filePath: '/drive_cache/${widget.pdf.id}',
          fileSize: widget.pdf.size,
          pageCount: 0,
          isFavorite: false,
          importedAt: widget.pdf.modifiedTime ?? DateTime.now(),
          coverPath: snapshot.data?.path,
          isManaged: false,
        );
        final DateTime? modified = widget.pdf.modifiedTime?.toLocal();
        final String metadata = modified == null
            ? document.readableSize
            : '${document.readableSize} · ${modified.day.toString().padLeft(2, '0')}/${modified.month.toString().padLeft(2, '0')}/${modified.year}';
        return Stack(
          fit: StackFit.expand,
          children: [
            DocumentCard(
              document: document,
              onOpen: widget.onOpen,
              metadataLabel: metadata,
              showMenu: false,
            ),
            if (widget.opening)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x88000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DriveError extends StatelessWidget {
  const _DriveError({required this.onRetry, required this.error});

  final VoidCallback onRetry;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Google Drive could not be loaded.'),
            const SizedBox(height: 8),
            Text(
              '$error',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}


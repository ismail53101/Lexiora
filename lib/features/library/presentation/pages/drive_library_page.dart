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
  DriveDownloadProgress? _downloadProgress;

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
    setState(() {
      _openingId = pdf.id;
      _downloadProgress = null;
    });
    try {
      final DrivePdfOpenResult opened = await _drive.openPdf(
        pdf,
        onProgress: (DriveDownloadProgress progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
      );
      final File cached = opened.file;
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
      if (mounted) {
        setState(() {
          _openingId = null;
          _downloadProgress = null;
        });
      }
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
                progress: _openingId == files[index].id
                    ? _downloadProgress
                    : null,
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
    required this.progress,
    required this.onOpen,
  });

  final GoogleDrivePdf pdf;
  final GoogleDriveService drive;
  final bool opening;
  final DriveDownloadProgress? progress;
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
              Positioned.fill(
                child: _DownloadOverlay(progress: widget.progress),
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


class _DownloadOverlay extends StatelessWidget {
  const _DownloadOverlay({required this.progress});

  final DriveDownloadProgress? progress;

  @override
  Widget build(BuildContext context) {
    final DriveDownloadProgress? value = progress;
    final bool cached = value?.fromCache ?? false;
    return ColoredBox(
      color: const Color(0xCC101018),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cached ? 'Opening from device…' : 'Downloading PDF…',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!cached) ...[
                const SizedBox(height: 10),
                if (value?.fraction != null)
                  Text(
                    '${((value!.fraction ?? 0) * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: value?.fraction),
                const SizedBox(height: 6),
                Text(
                  '${_formatBytes(value?.downloadedBytes ?? 0)} / ${_formatBytes(value?.totalBytes)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (value?.remainingBytes != null)
                  Text(
                    '${_formatBytes(value!.remainingBytes!)} remaining',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    final double kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final double mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }
}

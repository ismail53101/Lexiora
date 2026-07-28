import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';

/// Actions offered from a document card's overflow menu.
enum DocumentCardAction { favorite, rename, delete }

/// A premium library card showing a generated cover, title and metadata, with
/// an optional reading-progress bar and an overflow menu.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    required this.onOpen,
    this.progress,
    this.onAction,
  });

  final LibraryDocument document;
  final VoidCallback onOpen;

  /// Reading completion in 0..1, shown as a thin bar when non-null.
  final double? progress;
  final void Function(DocumentCardAction action)? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CoverImage(coverPath: document.coverPath, title: document.title),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _Menu(
                      isFavorite: document.isFavorite,
                      onAction: onAction,
                    ),
                  ),
                  if (document.isFavorite)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: Icon(Icons.star, color: Colors.amber, size: 20),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _Badge(
                      icon: Icons.description_outlined,
                      label: document.pageCount > 0
                          ? '${document.pageCount} p'
                          : 'PDF',
                    ),
                  ),
                ],
              ),
            ),
            if (progress != null && progress! > 0)
              LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    document.readableSize,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// The card's cover: the PDF's real first page when a thumbnail has been
/// generated ([LibraryDocument.coverPath]), otherwise a deterministic
/// gradient with the document's initials — the same placeholder used before
/// thumbnails existed, so older/undiscoverable documents still look
/// intentional rather than broken.
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverPath, required this.title});

  final String? coverPath;
  final String title;

  @override
  Widget build(BuildContext context) {
    final String? path = coverPath;
    if (path != null && path.isNotEmpty) {
      return ColoredBox(
        // Neutral backing behind the page so `contain` never shows the
        // card's own background bleeding through at the letterboxed edges.
        color: const Color(0xFFF3F1EC),
        child: Image.file(
          File(path),
          // `cover` was cropping most of the page away to fill the card
          // (a rendered page's aspect ratio rarely matches the card's),
          // which read as an unpleasant, overly zoomed-in thumbnail.
          // `contain` always shows the whole first page, uncropped.
          fit: BoxFit.contain,
          // The file can go missing (e.g. cleared cache, moved storage) after
          // being recorded — fall back to the placeholder rather than an error
          // icon so the card always looks finished.
          errorBuilder: (BuildContext context, Object error, StackTrace? _) =>
              _Placeholder(title: title),
        ),
      );
    }
    return _Placeholder(title: title);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _coverColors(title),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _initials(title),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _initials(String title) {
    final String t = title.trim();
    if (t.isEmpty) return '?';
    final List<String> parts = t.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  List<Color> _coverColors(String seed) {
    final int h = seed.codeUnits.fold<int>(7, (int a, int c) => a * 31 + c);
    final double hue = (h % 360).abs().toDouble();
    final HSLColor base = HSLColor.fromAHSL(1, hue, 0.55, 0.42);
    final HSLColor second =
        HSLColor.fromAHSL(1, (hue + 28) % 360, 0.55, 0.30);
    return [base.toColor(), second.toColor()];
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.isFavorite, required this.onAction});

  final bool isFavorite;
  final void Function(DocumentCardAction action)? onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<DocumentCardAction>(
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
        tooltip: 'Options',
        onSelected: onAction,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<DocumentCardAction>>[
          PopupMenuItem<DocumentCardAction>(
            value: DocumentCardAction.favorite,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isFavorite ? Icons.star : Icons.star_border,
              ),
              title: Text(isFavorite ? 'Unfavorite' : 'Favorite'),
            ),
          ),
          const PopupMenuItem<DocumentCardAction>(
            value: DocumentCardAction.rename,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined),
              title: Text('Rename'),
            ),
          ),
          const PopupMenuItem<DocumentCardAction>(
            value: DocumentCardAction.delete,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.playlist_remove_outlined),
              title: Text('Remove from library'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

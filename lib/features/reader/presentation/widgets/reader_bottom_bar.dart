import 'package:flutter/material.dart';
import 'package:lexiora/core/reader_engine/pdf_reader_controller.dart';

/// The reader's bottom control bar: page navigation, a tappable page indicator
/// (go-to-page), zoom, reading-mode toggle and the panels button.
class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({
    super.key,
    required this.controller,
    required this.pageCount,
    required this.onGoToPage,
    required this.onCycleColorMode,
    required this.onOpenPanels,
  });

  final PdfReaderController controller;
  final int pageCount;
  final VoidCallback onGoToPage;
  final VoidCallback onCycleColorMode;
  final VoidCallback onOpenPanels;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous page',
            onPressed: controller.previousPage,
          ),
          InkWell(
            onTap: onGoToPage,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ValueListenableBuilder<int>(
                valueListenable: controller.currentPage,
                builder: (BuildContext context, int page, _) => Text(
                  '$page / ${pageCount > 0 ? pageCount : '—'}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next page',
            onPressed: controller.nextPage,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom out',
            onPressed: controller.zoomOut,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom in',
            onPressed: controller.zoomIn,
          ),
          IconButton(
            icon: const Icon(Icons.contrast),
            tooltip: 'Reading mode',
            onPressed: onCycleColorMode,
          ),
          IconButton(
            icon: const Icon(Icons.menu_open),
            tooltip: 'Bookmarks, notes & highlights',
            onPressed: onOpenPanels,
          ),
        ],
      ),
    );
  }
}

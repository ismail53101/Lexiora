import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/models/normalized_rect.dart';
import 'package:lexiora/core/reader_engine/pdf_engine.dart';
import 'package:lexiora/core/reader_engine/pdf_reader_controller.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';
import 'package:lexiora/core/reader_engine/word_action.dart';
import 'package:lexiora/core/services/pdf_ocr_service.dart';
import 'package:lexiora/core/services/screen_wake_service.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/core/widgets/error_view.dart';
import 'package:lexiora/features/annotations/domain/entities/highlight.dart';
import 'package:lexiora/features/annotations/domain/usecases/annotations_usecases.dart';
import 'package:lexiora/features/annotations/presentation/providers/annotations_providers.dart';
import 'package:lexiora/features/bookmarks/domain/usecases/bookmarks_usecases.dart';
import 'package:lexiora/features/bookmarks/presentation/providers/bookmarks_providers.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/features/notes/domain/entities/note.dart';
import 'package:lexiora/features/notes/domain/usecases/notes_usecases.dart';
import 'package:lexiora/features/notes/presentation/providers/notes_providers.dart';
import 'package:lexiora/features/reader/presentation/widgets/reader_bottom_bar.dart';
import 'package:lexiora/features/reader/presentation/widgets/reader_panels.dart';
import 'package:lexiora/features/reader/presentation/widgets/reader_selection_toolbar.dart';
import 'package:lexiora/features/reading_progress/domain/usecases/reading_progress_usecases.dart';
import 'package:lexiora/features/reading_progress/presentation/providers/reading_progress_providers.dart';
import 'package:lexiora/features/settings/presentation/providers/settings_providers.dart';

/// The PDF reading screen. Loads the document and its remembered page, wires
/// highlights → overlays, selection → the selection toolbar, page changes →
/// reading progress, and hosts search + the bookmarks/notes/highlights panels.
///
/// Every state (loading, error, loaded) renders a full Scaffold with an AppBar,
/// and load failures show an explained [ErrorView] with Retry/Back — so the
/// reader can never present a blank, chromeless screen.
class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({
    super.key,
    required this.documentId,
    this.temporaryDocument,
  });

  final String documentId;

  /// Non-null for a Drive PDF opened directly from temporary app-private cache.
  /// It is intentionally never inserted into the Library database.
  final LibraryDocument? temporaryDocument;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  late final PdfReaderController _controller;
  final TextEditingController _searchField = TextEditingController();

  LibraryDocument? _document;
  String? _error;
  String? _errorDetails;
  String? _temporarySourcePath;
  bool _hasOcrCache = false;
  int _initialPage = 1;
  int _pageCount = 0;
  PdfTextSelectionData? _selection;
  bool _searching = false;
  ReaderScrollAxis _scrollAxis = ReaderScrollAxis.vertical;
  ReaderColorMode _colorMode = ReaderColorMode.day;
  List<int> _highlightColors = const <int>[0xFFFFF176];

  String get _id => widget.documentId;
  bool get _isTemporary => widget.temporaryDocument != null;

  @override
  void initState() {
    super.initState();
    _controller = sl<PdfEngine>().createController();
    _load();
  }

  Future<void> _load() async {
    AppLogger.i('Reader._load documentId=$_id');
    try {
      // Resolve the document path before loading settings or other reader
      // metadata. This lets the actual PDF viewer shell appear immediately
      // instead of showing a separate full-screen loading page.
      final LibraryDocument? doc = widget.temporaryDocument ??
          await ref.read(libraryRepositoryProvider).getById(_id);
      if (doc == null) {
        AppLogger.w('Reader: document not found ($_id)');
        if (mounted) {
          setState(() {
            _error = 'This document is no longer in your library.';
          });
        }
        return;
      }
      if (mounted) setState(() => _document = doc);

      final settings = await ref.read(settingsRepositoryProvider).getSettings();

      // Validate the backing file BEFORE handing it to the PDF engine, so a
      // missing/empty file shows a helpful error instead of a blank viewer.
      final File file = File(doc.filePath);
      final String sourcePath = doc.filePath;
      final bool exists = await file.exists();
      final int size = exists ? await file.length() : 0;
      AppLogger.i('Reader: file=${doc.filePath} exists=$exists size=$size');
      if (!exists || size == 0) {
        if (mounted) {
          setState(() {
            _loading = false;
            _document = doc;
            _error = 'The file for "${doc.title}" is missing or empty. '
                'It may have been moved or deleted — try re-importing it.';
            _errorDetails = 'path=${doc.filePath}\nexists=$exists  size=$size';
          });
        }
        return;
      }

      // Device PDFs already have a stable local path and must open directly.
      // Only the temporary Drive-reader path enters OCR preprocessing, so a
      // normal local document never gets stuck behind an unnecessary scan.
      final bool isDriveDocument = _isTemporary && doc.isFromGoogleDrive;
      final String searchablePath = isDriveDocument
          ? await sl<PdfOcrService>().makeSearchable(
              documentId: _id,
              sourcePath: sourcePath,
            )
          : sourcePath;
      if (_isTemporary) _temporarySourcePath = sourcePath;
      _hasOcrCache = isDriveDocument && searchablePath != sourcePath;
      final LibraryDocument openedDocument = searchablePath == sourcePath
          ? doc
          : LibraryDocument(
              id: doc.id,
              title: doc.title,
              fileName: doc.fileName,
              filePath: searchablePath,
              fileSize: doc.fileSize,
              pageCount: doc.pageCount,
              isFavorite: doc.isFavorite,
              importedAt: doc.importedAt,
              coverPath: doc.coverPath,
              categoryId: doc.categoryId,
              lastOpenedAt: doc.lastOpenedAt,
              isManaged: doc.isManaged,
            );
      final progress = _isTemporary
          ? null
          : await ref.read(readingProgressRepositoryProvider).getProgress(_id);
      _scrollAxis = settings.readingScrollAxis;
      _colorMode = settings.readerColorMode;
      _highlightColors = settings.highlightColors;
      _document = openedDocument;
      _pageCount = openedDocument.pageCount;
      final int maxPage = doc.pageCount > 0 ? doc.pageCount : 1000000;
      _initialPage = settings.autoResume
          ? (progress?.lastPage ?? 1).clamp(1, maxPage)
          : 1;

      // Honor the "keep screen awake" preference while reading.
      await sl<ScreenWakeService>().setKeepScreenOn(settings.keepScreenAwake);

      if (!_isTemporary) {
        await ref.read(markDocumentOpenedProvider).call(_id);
        await ref.read(logReadingSessionProvider).call(
              LogSessionParams(documentId: _id, pageNumber: _initialPage),
            );
      }
    } on Object catch (e, s) {
      AppLogger.e('Reader._load failed', error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to open this document.';
          _errorDetails = '$e';
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _errorDetails = null;
    });
    _load();
  }

  @override
  void dispose() {
    unawaited(sl<ScreenWakeService>().setKeepScreenOn(false));
    if (_isTemporary) {
      final String? temporaryPath = _temporarySourcePath ?? _document?.filePath;
      final bool persistentDriveCache =
          temporaryPath?.replaceAll('\\', '/').contains('/drive_cache/') ?? false;
      // Drive PDFs are temporary reader documents but their downloaded source
      // and OCR copy are persistent caches. Only delete truly transient files.
      if (!persistentDriveCache && _hasOcrCache) {
        unawaited(sl<PdfOcrService>().deleteSearchable(_id));
      }
      if (!persistentDriveCache && temporaryPath != null) {
        unawaited(
          File(temporaryPath).delete().catchError((Object _) => File(temporaryPath)),
        );
      }
    }
    _controller.dispose();
    _searchField.dispose();
    super.dispose();
  }

  List<ReaderOverlayRect> _overlays(List<Highlight> highlights) => highlights
      .map(
        (Highlight h) => ReaderOverlayRect(
          id: h.id,
          pageNumber: h.pageNumber,
          rects: h.rects,
          colorValue: h.colorValue,
          style: h.type == AnnotationType.underline
              ? ReaderOverlayStyle.underline
              : ReaderOverlayStyle.highlight,
        ),
      )
      .toList();

  void _onPageChanged(int page) {
    if (_isTemporary) return;
    ref.read(saveReadingProgressProvider).call(
          SaveProgressParams(
            documentId: _id,
            lastPage: page,
            totalPages: _pageCount,
          ),
        );
  }

  void _onDocLoaded(int count) {
    if (count != _pageCount && mounted) setState(() => _pageCount = count);
  }

  void _onSelectionChanged(PdfTextSelectionData sel) {
    if (!mounted) return;
    setState(() => _selection = sel.isEmpty ? null : sel);
  }

  Future<void> _addHighlight(int color, AnnotationType type) async {
    final PdfTextSelectionData? sel = _selection;
    if (sel == null) return;
    await ref.read(addHighlightProvider).call(
          AddHighlightParams(
            documentId: _id,
            selection: sel,
            colorValue: color,
            type: type,
          ),
        );
    await _clearSelection();
  }

  Future<void> _bookmarkSelection() async {
    final PdfTextSelectionData? sel = _selection;
    if (sel == null) return;
    await ref.read(addBookmarkFromSelectionProvider).call(
          BookmarkSelectionParams(documentId: _id, selection: sel),
        );
    await _clearSelection();
  }

  Future<void> _copySelection() async {
    await _controller.copySelection();
    await _clearSelection();
  }

  Future<void> _noteSelection() async {
    final PdfTextSelectionData? sel = _selection;
    if (sel == null) return;
    final int page = sel.primaryPage ?? _controller.currentPage.value;
    final List<NormalizedRect> rects =
        sel.pages.isNotEmpty ? sel.pages.first.rects : const <NormalizedRect>[];
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? text = await _promptText(title: 'Add note', hint: 'Your note');
    if (text == null || text.isEmpty) return;
    await ref.read(addNoteProvider).call(
          AddNoteParams(
            documentId: _id,
            pageNumber: page,
            content: text,
            anchor: NoteAnchor.selection,
            selectedText: sel.text,
            rects: rects,
          ),
        );
    await _clearSelection();
    messenger.showSnackBar(const SnackBar(content: Text('Note added')));
  }

  Future<void> _clearSelection() async {
    await _controller.clearSelection();
    if (mounted) setState(() => _selection = null);
  }

  /// Trims a PDF selection and strips stray leading/trailing punctuation (PDF
  /// selections frequently include ":", ",", ".", quotes) so single words are
  /// recognized — and handed to word actions — as single words.
  String _cleanSelectedText(String raw) {
    String text = raw.trim();
    text = text.replaceFirst(RegExp(r'^[^A-Za-z0-9]+'), '');
    text = text.replaceFirst(RegExp(r'[^A-Za-z0-9]+$'), '');
    return text;
  }

  /// The selected text when it is a single word (letters with optional internal
  /// hyphen/apostrophe); otherwise null. Used to classify a selection as
  /// single-word vs phrase — word actions that are not [WordAction.supportsPhrase]
  /// (e.g. dictionary "Look up") only apply to single words.
  String? _selectionSingleWord() {
    final PdfTextSelectionData? sel = _selection;
    if (sel == null) return null;
    final String text = _cleanSelectedText(sel.text.trim());
    if (text.isEmpty || text.length > 64) return null;
    if (!RegExp(r"^[A-Za-z][A-Za-z'’\-]*$").hasMatch(text)) return null;
    return text;
  }

  /// The selected text eligible for *any* word action — a single word or a
  /// multi-word phrase/sentence — or null when nothing usable is selected.
  /// Callers combine this with [_selectionSingleWord] and
  /// [WordAction.supportsPhrase] to decide which actions to offer: dictionary
  /// lookups need a single word, while translation accepts a full phrase.
  /// Single words are returned in their cleaned form so actions never see
  /// stray punctuation (e.g. "execution," → "execution").
  String? _selectionActionText() {
    final PdfTextSelectionData? sel = _selection;
    if (sel == null) return null;
    final String raw = sel.text.trim();
    if (raw.isEmpty || raw.length > 300) return null;
    return _selectionSingleWord() ?? raw;
  }

  /// Invokes a registered [WordAction] for the selected word. The reader stays
  /// decoupled from the dictionary/translation modules — it only knows the core
  /// [WordActionRegistry] abstraction, and renders whatever it contains.
  Future<void> _invokeWordAction(WordAction action, String word) async {
    final PdfTextSelectionData? sel = _selection;
    final WordActionContext ctx = WordActionContext(
      documentId: _id,
      pageNumber: sel?.primaryPage ?? _controller.currentPage.value,
      word: word,
      selection: sel,
    );
    await action.invoke(context, ctx);
    await _clearSelection();
  }

  void _cycleColorMode() {
    setState(() {
      _colorMode = ReaderColorMode
          .values[(_colorMode.index + 1) % ReaderColorMode.values.length];
    });
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchField.clear();
        _controller.clearSearch();
      }
    });
  }

  Future<void> _goToPageDialog() async {
    final String? value = await _promptText(
      title: 'Go to page',
      hint: 'Page number (1–${_pageCount > 0 ? _pageCount : '?'})',
      keyboardType: TextInputType.number,
    );
    final int? page = value == null ? null : int.tryParse(value.trim());
    if (page != null) await _controller.goToPage(page);
  }

  Future<String?> _promptText({
    required String title,
    required String hint,
    TextInputType keyboardType = TextInputType.multiline,
  }) {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          minLines: 1,
          maxLines: keyboardType == TextInputType.number ? 1 : 5,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    if (_document == null && _error == null) {
      return const Scaffold(
        body: SizedBox.expand(),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_document?.title ?? 'Reader')),
        body: ErrorView(
          title: 'Cannot open document',
          message: _error ?? 'The document could not be opened.',
          details: _errorDetails,
          onRetry: _retry,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final AsyncValue<List<Highlight>> highlightsAsync =
        ref.watch(highlightsForDocumentProvider(_id));
    final List<ReaderOverlayRect> overlays = highlightsAsync.maybeWhen(
      data: _overlays,
      orElse: () => const <ReaderOverlayRect>[],
    );

    final PdfViewConfig config = PdfViewConfig(
      filePath: _document!.filePath,
      initialPage: _initialPage,
      scrollAxis: _scrollAxis,
      colorMode: _colorMode,
      overlays: overlays,
      onPageChanged: _onPageChanged,
      onDocumentLoaded: _onDocLoaded,
      onSelectionChanged: _onSelectionChanged,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_document!.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.search_off : Icons.search),
            tooltip: 'Search in document',
            onPressed: _toggleSearch,
          ),
          _BookmarkToggle(documentId: _id, controller: _controller),
        ],
        bottom: _searching
            ? _SearchBar(field: _searchField, controller: _controller)
            : null,
      ),
      bottomNavigationBar: ReaderBottomBar(
        controller: _controller,
        pageCount: _pageCount,
        onGoToPage: _goToPageDialog,
        onCycleColorMode: _cycleColorMode,
        onOpenPanels: () => showReaderPanels(
          context,
          documentId: _id,
          controller: _controller,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: sl<PdfEngine>().buildViewer(
              controller: _controller,
              config: config,
            ),
          ),
          if (_selection != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: Center(
                child: Builder(
                  builder: (BuildContext context) {
                    final WordActionRegistry registry =
                        sl<WordActionRegistry>();
                    final String? text =
                        registry.hasActions ? _selectionActionText() : null;
                    final bool isSingleWord =
                        text != null && _selectionSingleWord() == text;
                    final List<WordAction> actions = text == null
                        ? const <WordAction>[]
                        : registry.actions
                            .where((WordAction a) =>
                                isSingleWord || a.supportsPhrase)
                            .toList(growable: false);
                    return ReaderSelectionToolbar(
                      colors: _highlightColors,
                      onHighlight: (int c) =>
                          _addHighlight(c, AnnotationType.highlight),
                      onUnderline: (int c) =>
                          _addHighlight(c, AnnotationType.underline),
                      onNote: _noteSelection,
                      onBookmark: _bookmarkSelection,
                      onCopy: _copySelection,
                      onDismiss: _clearSelection,
                      selectedWord: actions.isEmpty ? null : text,
                      wordActions: actions,
                      onWordAction: actions.isEmpty
                          ? null
                          : (WordAction a) => _invokeWordAction(a, text!),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// App-bar action that reflects and toggles the current page's bookmark state.
class _BookmarkToggle extends StatelessWidget {
  const _BookmarkToggle({required this.documentId, required this.controller});

  final String documentId;
  final PdfReaderController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: controller.currentPage,
      builder: (BuildContext context, int page, _) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final bool bookmarked = ref
                .watch(isPageBookmarkedProvider(
                    (documentId: documentId, page: page)))
                .maybeWhen(data: (bool v) => v, orElse: () => false);
            return IconButton(
              icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
              tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark page',
              onPressed: () => ref
                  .read(togglePageBookmarkProvider)
                  .call(ToggleBookmarkParams(documentId, page)),
            );
          },
        );
      },
    );
  }
}

/// Search field + match navigation, hosted in the app bar's bottom slot.
class _SearchBar extends StatelessWidget implements PreferredSizeWidget {
  const _SearchBar({required this.field, required this.controller});

  final TextEditingController field;
  final PdfReaderController controller;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: field,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search in document',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: controller.search,
            ),
          ),
          ValueListenableBuilder<PdfSearchState>(
            valueListenable: controller.searchState,
            builder: (BuildContext context, PdfSearchState s, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                s.isSearching
                    ? '…'
                    : (s.hasMatches ? '${s.currentMatch}/${s.totalMatches}' : '0/0'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            tooltip: 'Previous match',
            onPressed: controller.previousMatch,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: 'Next match',
            onPressed: controller.nextMatch,
          ),
        ],
      ),
    );
  }
}

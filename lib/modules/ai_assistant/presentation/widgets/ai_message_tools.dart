import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lexiora/core/services/browser_pdf_store.dart';
import 'package:lexiora/core/services/share_bytes.dart' as platform_share;
// PdfDocument/PdfPage exist in BOTH packages below (one is for reading an
// existing PDF's text, the other for building a new PDF) — hidden from the
// `pdf` package so pdfrx's versions (the ones actually used for reading)
// win without an ambiguous-import error.
import 'package:pdf/pdf.dart' hide PdfDocument, PdfPage;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';
// XFile itself comes from share_plus's own re-export of cross_file — no
// separate cross_file import needed (and the analyzer flags it as
// unnecessary if you add one).

/// Pulls the plain text out of an existing PDF (e.g. one the user attaches
/// to ask the assistant about) using the same `pdfrx` per-page text loader
/// already used elsewhere in the app (see `PdfOcrService`) — no extra
/// package needed just for this.
///
/// Extracts selectable text page-by-page and keeps page boundaries visible to
/// the assistant. A larger bounded context supports document summaries and
/// data inspection without allowing an enormous PDF to create an unbounded
/// request. When the limit is reached, both the beginning and ending sections
/// are retained instead of silently discarding everything after the first
/// characters.
Future<String?> extractPdfPlainText(
  String filePath, {
  int maxChars = 48000,
}) async {
  PdfDocument? document;
  try {
    final String source = kIsWeb
        ? await resolveBrowserPdf(filePath)
        : filePath;
    document = kIsWeb
        ? await PdfDocument.openUri(Uri.parse(source))
        : await PdfDocument.openFile(source);
    final List<String> pageSections = <String>[];
    for (int index = 0; index < document.pages.length; index++) {
      final PdfPage page = document.pages[index];
      try {
        // Typed dynamically, matching PdfOcrService — the precise return
        // type isn't part of pdfrx's documented static API surface.
        final dynamic pageText = await (page as dynamic).loadText();
        final String text = (pageText.fullText as String?)?.trim() ?? '';
        if (text.isNotEmpty) {
          pageSections.add('--- Page ${index + 1} ---\n$text');
        }
      } on Object {
        // Skip a single unreadable page rather than failing the whole
        // document. OCR has already handled pages without a text layer.
      }
    }
    final String out = pageSections.join('\n\n').trim();
    if (out.isEmpty) return null;
    if (out.length <= maxChars) return out;

    // Preserve both document context and conclusions for summaries. The
    // explicit marker tells the model that the middle was not transmitted.
    final int headChars = (maxChars * 0.72).floor();
    final int tailChars = maxChars - headChars;
    return '${out.substring(0, headChars).trim()}\n\n'
        '[…middle of this PDF omitted from the attachment context…]\n\n'
        '${out.substring(out.length - tailChars).trim()}';
  } on Object {
    return null;
  } finally {
    if (document != null) await document.dispose();
  }
}

/// Strips Markdown syntax down to plain, speakable/printable text — used by
/// both "Read aloud" (so the TTS engine doesn't say "asterisk asterisk") and
/// "Make PDF" (so the export isn't full of stray `#`/`**`/`|` characters).
String stripMarkdownForPlainText(String input) {
  String out = input;
  out = out.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  out = out.replaceAllMapped(RegExp(r'`([^`]*)`'), (Match m) => m.group(1) ?? '');
  out = out.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), ' ');
  out = out.replaceAllMapped(
      RegExp(r'\[([^\]]*)\]\([^)]*\)'), (Match m) => m.group(1) ?? '');
  out = out.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
  out = out.replaceAll(RegExp(r'\*\*|__|~~'), '');
  out = out.replaceAll(RegExp(r'(?<!\w)\*(?!\s)([^*]+)\*(?!\w)'), r'$1');
  out = out.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '• ');
  out = out.replaceAll(RegExp(r'^\s*\|?\s*[-:]{3,}.*\|.*$', multiLine: true), '');
  out = out.replaceAll('|', '  ');
  out = out.replaceAll(RegExp(r'[ \t]+'), ' ');
  out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return out.trim();
}

enum AiReadAloudState { idle, playing, paused }

/// Coordinates on-device text-to-speech playback for AI Assistant replies.
///
/// A single app-wide instance so starting playback on one message always
/// stops any other message that might already be speaking, and every
/// "Read aloud" button in the chat reflects the one true playing/not-playing
/// state via [activeMessageId].
class AiReadAloudController {
  AiReadAloudController._();

  static final AiReadAloudController instance = AiReadAloudController._();

  final FlutterTts _tts = FlutterTts();

  /// The id of the message currently being read aloud, or null if nothing
  /// is active. Listen to this together with [playbackState] for controls.
  final ValueNotifier<Object?> activeMessageId = ValueNotifier<Object?>(null);
  final ValueNotifier<AiReadAloudState> playbackState =
      ValueNotifier<AiReadAloudState>(AiReadAloudState.idle);
  final ValueNotifier<Duration> playbackElapsed =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> playbackDuration =
      ValueNotifier<Duration>(Duration.zero);

  Timer? _progressTimer;
  bool _configured = false;
  bool _suppressEngineCallbacks = false;
  String _activeText = '';
  int _currentChar = 0;
  int _utteranceStartChar = 0;

  /// Bumped on every user-driven state change (new message, pause, stop,
  /// seek) so an in-flight chunk loop knows it was superseded and exits.
  int _generation = 0;

  /// Generation of the chunk loop that currently "owns" engine events, or
  /// null when no loop is inside `speak`. Per-chunk completion/cancel/error
  /// callbacks must not tear the player down mid-text; a superseded loop
  /// releases ownership in its `finally`, so pausing can never leave the
  /// flag stuck and later engine events are never suppressed forever.
  int? _loopActiveGeneration;

  /// Android's TTS engine rejects utterances longer than ~4000 characters
  /// (it fails with an error code — previously surfaced as the white
  /// "engine returned code 0" banner on long replies). Long texts are
  /// spoken as consecutive chunks, split at sentence or word boundaries.
  static const int _maxChunkLength = 3800;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.awaitSpeakCompletion(true);
    // Flush the previous utterance whenever seek/resume starts a new
    // segment; queue-add would leave stale speech running behind the player.
    await _tts.setQueueMode(0);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      // While the chunk loop is driving playback it owns the state —
      // per-chunk completion events must not tear the player down mid-text.
      // Also ignore stray callbacks while paused: some Android engines
      // deliver a completion/stop event for the interrupted utterance after
      // a pause, and the paused player must stay visible and resumable.
      if (!_suppressEngineCallbacks &&
          _loopActiveGeneration == null &&
          playbackState.value == AiReadAloudState.playing) {
        _resetState();
      }
    });
    _tts.setCancelHandler(() {
      if (!_suppressEngineCallbacks &&
          _loopActiveGeneration == null &&
          playbackState.value == AiReadAloudState.playing) {
        _resetState();
      }
    });
    _tts.setPauseHandler(() {
      playbackState.value = AiReadAloudState.paused;
    });
    _tts.setContinueHandler(() {
      playbackState.value = AiReadAloudState.playing;
    });
    _tts.setProgressHandler((String _, int start, int end, String _) {
      if (_activeText.isEmpty || activeMessageId.value == null) return;
      _currentChar =
          (_utteranceStartChar + end).clamp(0, _activeText.length).toInt();
      final Duration total = playbackDuration.value;
      if (total > Duration.zero) {
        playbackElapsed.value = Duration(
          milliseconds: (total.inMilliseconds *
                  (_currentChar / _activeText.length))
              .round(),
        );
      }
    });
    _tts.setErrorHandler((dynamic _) {
      if (!_suppressEngineCallbacks &&
          _loopActiveGeneration == null &&
          playbackState.value == AiReadAloudState.playing) {
        _resetState();
      }
    });
    _configured = true;
  }

  void _resetState() {
    _stopProgressTimer();
    activeMessageId.value = null;
    playbackState.value = AiReadAloudState.idle;
    playbackElapsed.value = Duration.zero;
    playbackDuration.value = Duration.zero;
    _loopActiveGeneration = null;
    _activeText = '';
    _currentChar = 0;
    _utteranceStartChar = 0;
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _startProgressTimer() {
    _stopProgressTimer();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (playbackState.value != AiReadAloudState.playing) return;
      final Duration next = playbackElapsed.value + const Duration(seconds: 1);
      final Duration total = playbackDuration.value;
      playbackElapsed.value = total > Duration.zero && next >= total ? total : next;
      if (_activeText.isNotEmpty && total > Duration.zero) {
        _currentChar = (_activeText.length *
                (playbackElapsed.value.inMilliseconds / total.inMilliseconds))
            .round()
            .clamp(0, _activeText.length)
            .toInt();
      }
    });
  }

  void _prepareProgress(String text) {
    final int words = text.trim().split(RegExp(r'\s+')).length;
    // Flutter TTS exposes character progress, but not a total duration. This
    // estimate supplies the seekable timeline while callbacks track speech.
    final int seconds = (words / 2.25).ceil().clamp(3, 3600);
    playbackElapsed.value = Duration.zero;
    playbackDuration.value = Duration(seconds: seconds);
  }

  Future<void> seekToFraction(double fraction) async {
    final Duration total = playbackDuration.value;
    if (total <= Duration.zero || _activeText.isEmpty) return;
    final double clamped = fraction.clamp(0.0, 1.0);
    _currentChar = (_activeText.length * clamped).round();
    playbackElapsed.value = Duration(
      milliseconds: (total.inMilliseconds * clamped).round(),
    );
    if (playbackState.value == AiReadAloudState.playing) {
      _generation++; // invalidate any in-flight chunk loop
      await _speakFromCurrentChar();
    }
  }

  /// Restarts speech at the current character position and keeps speaking
  /// consecutive chunks until the text ends or playback is superseded (stop,
  /// pause, seek, or a new message). Chunks stay under [_maxChunkLength] —
  /// Android's TTS engine silently fails on longer utterances, which used to
  /// surface as the white "engine returned code 0" banner on long replies.
  Future<void> _speakFromCurrentChar() async {
    if (_activeText.isEmpty || activeMessageId.value == null) return;
    await _ensureConfigured();

    _suppressEngineCallbacks = true;
    try {
      await _tts.stop();
      // Android may deliver the old cancel callback on the next event turn.
      // Let it drain while callbacks are suppressed before starting the new
      // utterance, otherwise it can hide the still-playing compact strip.
      await Future<void>.delayed(Duration.zero);
    } finally {
      _suppressEngineCallbacks = false;
    }

    final int myGeneration = _generation;
    _loopActiveGeneration = myGeneration;
    try {
      while (true) {
        if (myGeneration != _generation ||
            activeMessageId.value == null ||
            playbackState.value != AiReadAloudState.playing) {
          return; // superseded (stop/pause/seek/new message)
        }
        final int requestedStart = _currentChar.clamp(0, _activeText.length);
        final String sourceRemainder = _activeText.substring(requestedStart);
        final String remaining = sourceRemainder.trimLeft();
        if (remaining.isEmpty) break; // finished the whole text
        _utteranceStartChar =
            requestedStart + sourceRemainder.length - remaining.length;

        final String chunk = _nextChunk(remaining);
        await _tts.setLanguage('en-US');
        await _tts.setSpeechRate(0.46);
        await _tts.setPitch(1.0);
        await _tts.setVolume(1.0);
        // awaitSpeakCompletion(true) makes this await the chunk's end.
        final Object? result = await _tts.speak(chunk);
        if (result is int && result != 1) {
          // The engine did not accept/finish the utterance. Most commonly
          // this is not an error at all: Android's flutter_tts resolves the
          // pending speak() future with 0 whenever pause or stop interrupts
          // the utterance. Only treat it as a real engine failure when this
          // loop is still the active one and playback is supposed to be
          // running; otherwise the user paused/stopped on purpose and the
          // player must stay exactly as they left it (visible, paused,
          // resumable from the same position).
          if (myGeneration != _generation ||
              activeMessageId.value == null ||
              playbackState.value != AiReadAloudState.playing) {
            return; // superseded (pause/stop/seek/new message) — keep state
          }
          // Genuine refusal (no TTS engine/voice, busy engine): quiet
          // failure of the whole playback, never a crash or error banner.
          _resetState();
          return;
        }
        _currentChar = _utteranceStartChar + chunk.length;
      }
      // Reached the end of the text normally.
      _resetState();
    } on Object {
      _resetState();
    } finally {
      // Release loop ownership only if this loop is still the registered
      // one — a newer loop (new message/seek) may already have taken over.
      if (_loopActiveGeneration == myGeneration) _loopActiveGeneration = null;
    }
  }

  /// Splits [text] into a chunk of at most [_maxChunkLength] characters,
  /// preferring the last sentence end, then word boundary, then a hard cut.
  String _nextChunk(String text) {
    if (text.length <= _maxChunkLength) return text;
    final String window = text.substring(0, _maxChunkLength);
    final int sentenceEnd = window.lastIndexOf(RegExp(r'[.!?…]\s'));
    if (sentenceEnd > _maxChunkLength ~/ 2) {
      return window.substring(0, sentenceEnd + 1);
    }
    final int spaceEnd = window.lastIndexOf(' ');
    if (spaceEnd > _maxChunkLength ~/ 2) return window.substring(0, spaceEnd);
    return window;
  }

  /// Starts reading [text] aloud for [messageId]. Tapping the same active
  /// message toggles between pause and resume. Never throws: engine failures
  /// (missing TTS engine/voice, busy engine) reset the player quietly — the
  /// UI simply returns to idle without any error banner.
  Future<void> toggle(Object messageId, String text) async {
    if (activeMessageId.value == messageId) {
      if (playbackState.value == AiReadAloudState.playing) {
        _generation++;
        await _tts.pause();
        _stopProgressTimer();
        playbackState.value = AiReadAloudState.paused;
      } else if (playbackState.value == AiReadAloudState.paused) {
        playbackState.value = AiReadAloudState.playing;
        _startProgressTimer();
        await _speakFromCurrentChar();
      }
      return;
    }

    final String clean = stripMarkdownForPlainText(text);
    if (clean.isEmpty) return;

    // Publish the state before any asynchronous engine setup so the button
    // immediately shows that playback is starting, even on a cold TTS engine.
    _generation++;
    activeMessageId.value = messageId;
    playbackState.value = AiReadAloudState.playing;
    _activeText = clean;
    _currentChar = 0;
    _prepareProgress(clean);
    _startProgressTimer();
    await _speakFromCurrentChar();
  }

  Future<void> stop() async {
    _generation++;
    await _tts.stop();
    _resetState();
  }
}

/// Loads the bundled Urdu/Arabic font for PDF export, if one has been added
/// to the project — see the note on [exportMessageAsPdf] for exactly what
/// to add and where. Returns null (never throws) if it isn't there yet, so
/// PDF export keeps working normally — just without Urdu glyphs — until the
/// font is added.
Future<pw.Font?> _loadUrduPdfFont() async {
  try {
    final ByteData data =
        await rootBundle.load('assets/fonts/NotoNastaliqUrdu-Regular.ttf');
    return pw.Font.ttf(data);
  } on Object {
    return null;
  }
}

/// Builds a simple PDF from an assistant reply's text and opens the native
/// share sheet (Save to Files / Drive / WhatsApp / print, etc.) — one tap
/// from message to a shareable PDF.
///
/// Urdu/Arabic support: this looks for a bundled font at
/// `assets/fonts/NotoNastaliqUrdu-Regular.ttf` (declared under `assets:` in
/// pubspec.yaml) and, if present, uses it as a fallback so Urdu/Arabic
/// glyphs render correctly alongside Latin text. Until that font file is
/// actually added to the project, Urdu characters will show as missing
/// glyphs in the exported PDF — English text is unaffected either way.
Future<void> exportMessageAsPdf(
  BuildContext context, {
  required String text,
  String title = 'Sapiora AI Assistant',
}) async {
  final String clean = stripMarkdownForPlainText(text);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  if (clean.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nothing here to turn into a PDF yet.')),
    );
    return;
  }

  try {
    final pw.Font? urduFont = await _loadUrduPdfFont();
    final List<pw.Font> fallback =
        urduFont == null ? <pw.Font>[] : <pw.Font>[urduFont];

    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 36),
        theme: pw.ThemeData.withFont(fontFallback: fallback),
        header: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                fontFallback: fallback,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 0.6),
          ],
        ),
        footer: (pw.Context ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (pw.Context ctx) => <pw.Widget>[
          pw.SizedBox(height: 12),
          pw.Text(
            clean,
            style: pw.TextStyle(
              fontSize: 11.5,
              lineSpacing: 3,
              fontFallback: fallback,
            ),
          ),
        ],
      ),
    );

    final String filename =
        'sapiora-reply-${DateTime.now().millisecondsSinceEpoch}.pdf';
    await platform_share.shareBytes(
      await doc.save(),
      filename,
      'application/pdf',
    );
  } on Object catch (e, st) {
    // Logged for `flutter run`/`adb logcat` visibility, and shown in the
    // snackbar too — the generic "please try again" message before this
    // gave no way to tell what actually failed.
    debugPrint('exportMessageAsPdf failed: $e\n$st');
    messenger.showSnackBar(
      SnackBar(content: Text('Could not create the PDF: $e')),
    );
  }
}

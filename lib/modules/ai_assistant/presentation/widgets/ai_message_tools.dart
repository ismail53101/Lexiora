import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:share_plus/share_plus.dart';

/// Pulls the plain text out of an existing PDF (e.g. one the user attaches
/// to ask the assistant about) using the same `pdfrx` per-page text loader
/// already used elsewhere in the app (see `PdfOcrService`) — no extra
/// package needed just for this.
///
/// Capped at [maxChars] so an enormous PDF doesn't blow up the request to
/// the assistant; returns null if the file couldn't be opened or had no
/// extractable text at all (e.g. a purely scanned PDF with no OCR layer).
Future<String?> extractPdfPlainText(
  String filePath, {
  int maxChars = 12000,
}) async {
  PdfDocument? document;
  try {
    document = await PdfDocument.openFile(filePath);
    final StringBuffer buffer = StringBuffer();
    for (final PdfPage page in document.pages) {
      if (buffer.length >= maxChars) break;
      try {
        // Typed dynamically, matching PdfOcrService — the precise return
        // type isn't part of pdfrx's documented static API surface.
        final dynamic pageText = await (page as dynamic).loadText();
        final String text = (pageText.fullText as String?)?.trim() ?? '';
        if (text.isNotEmpty) {
          buffer.writeln(text);
          buffer.writeln();
        }
      } on Object {
        // Skip a single unreadable page rather than failing the whole
        // document.
      }
    }
    String out = buffer.toString().trim();
    if (out.isEmpty) return null;
    if (out.length > maxChars) {
      out =
          '${out.substring(0, maxChars).trim()}\n\n[…truncated — this PDF continues beyond what was attached here…]';
    }
    return out;
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

  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setQueueMode(1);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(_resetState);
    _tts.setCancelHandler(_resetState);
    _tts.setPauseHandler(() {
      playbackState.value = AiReadAloudState.paused;
    });
    _tts.setContinueHandler(() {
      playbackState.value = AiReadAloudState.playing;
    });
    _tts.setErrorHandler((dynamic _) => _resetState());
    _configured = true;
  }

  void _resetState() {
    activeMessageId.value = null;
    playbackState.value = AiReadAloudState.idle;
  }

  /// Starts reading [text] aloud for [messageId]. Tapping the same active
  /// message toggles between pause and resume.
  ///
  /// Throws on failure (e.g. no TTS engine/voice installed on the device)
  /// so the caller can show the real error instead of the tap silently
  /// doing nothing.
  Future<void> toggle(Object messageId, String text) async {
    if (activeMessageId.value == messageId) {
      if (playbackState.value == AiReadAloudState.playing) {
        await _tts.pause();
        playbackState.value = AiReadAloudState.paused;
      } else if (playbackState.value == AiReadAloudState.paused) {
        // flutter_tts exposes pause but not a cross-platform resume method.
        // Speaking the retained text again provides a reliable resume action
        // on Android and iOS instead of leaving the control unresponsive.
        final String clean = stripMarkdownForPlainText(text);
        playbackState.value = AiReadAloudState.playing;
        await _tts.speak(clean);
      }
      return;
    }

    final String clean = stripMarkdownForPlainText(text);
    if (clean.isEmpty) return;

    // Publish the state before any asynchronous engine setup so the button
    // immediately shows that playback is starting, even on a cold TTS engine.
    activeMessageId.value = messageId;
    playbackState.value = AiReadAloudState.playing;
    try {
      await _ensureConfigured();
      await _tts.stop();
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      final Object? result = await _tts.speak(clean);
      // On Android/iOS flutter_tts returns 1 for success; surface anything
      // else as a real failure instead of silently doing nothing.
      if (result is int && result != 1) {
        _resetState();
        throw StateError('Text-to-speech engine returned code $result.');
      }
    } on Object {
      _resetState();
      rethrow;
    }
  }

  Future<void> stop() async {
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

    final Directory dir = await getTemporaryDirectory();
    final String path =
        '${dir.path}/sapiora-reply-${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File(path);
    await file.writeAsBytes(await doc.save());

    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(path)], text: title),
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

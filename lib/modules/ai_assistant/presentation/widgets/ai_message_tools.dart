import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';
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
  /// is playing. Listen to this to drive a per-message play/stop icon.
  final ValueNotifier<Object?> activeMessageId = ValueNotifier<Object?>(null);

  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.awaitSpeakCompletion(false);
    _tts.setCompletionHandler(() => activeMessageId.value = null);
    _tts.setCancelHandler(() => activeMessageId.value = null);
    _tts.setErrorHandler((Object _) => activeMessageId.value = null);
    _configured = true;
  }

  /// Starts reading [text] aloud for [messageId], or stops it if that same
  /// message is already the one playing (tap-to-toggle).
  Future<void> toggle(Object messageId, String text) async {
    await _ensureConfigured();
    if (activeMessageId.value == messageId) {
      await _tts.stop();
      activeMessageId.value = null;
      return;
    }
    await _tts.stop();
    final String clean = stripMarkdownForPlainText(text);
    if (clean.isEmpty) return;
    activeMessageId.value = messageId;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.0);
    await _tts.speak(clean);
  }

  Future<void> stop() async {
    await _tts.stop();
    activeMessageId.value = null;
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
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not create the PDF. Please try again.')),
    );
  }
}

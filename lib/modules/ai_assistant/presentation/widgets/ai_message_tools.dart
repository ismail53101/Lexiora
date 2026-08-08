import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

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

/// Builds a simple PDF from an assistant reply's text and opens the native
/// share sheet (Save to Files / Drive / WhatsApp / print, etc.) — one tap
/// from message to a shareable PDF.
///
/// Note: this uses the `pdf` package's built-in Latin font, so plain
/// English renders perfectly; Urdu/Arabic script in the same message will
/// currently show as missing glyphs in the PDF (a Unicode font would need
/// to be bundled with the app to render those correctly) — English text
/// around it is unaffected.
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
    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 36),
        header: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
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
          pw.Text(clean, style: const pw.TextStyle(fontSize: 11.5, lineSpacing: 3)),
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

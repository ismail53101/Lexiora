import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// DOCX story parts that can carry floating text boxes: the body plus
/// headers, footers and notes.
final RegExp _storyPart = RegExp(
  r'^word/(document|header\d*|footer\d*|footnotes|endnotes)\.xml$',
);

/// `mc:Fallback` branch of an `mc:AlternateContent`, any namespace prefix.
/// Word stores a VML copy of every DrawingML text box here; importing both
/// branches renders the same text twice.
final RegExp _selfClosingFallback = RegExp(
  r'<[A-Za-z][\w.-]*:Fallback(?:\s[^>]*)?/>',
);
final RegExp _pairedFallback = RegExp(
  r'<(?:[A-Za-z][\w.-]*:)?Fallback(?:\s[^>]*)?>[\s\S]*?'
  r'</(?:[A-Za-z][\w.-]*:)?Fallback>',
);

/// A whole `wp:anchor` element (anchors never nest in DrawingML).
final RegExp _anchorElement = RegExp(
  r'<(?:[A-Za-z][\w.-]*:)?anchor(?:\s[^>]*)?>[\s\S]*?'
  r'</(?:[A-Za-z][\w.-]*:)?anchor>',
);

/// `relativeFrom` values that the Quds importer reads as page-absolute even
/// though Word measures them from the text area. `page` and `margin` are left
/// untouched: `page` really is page-absolute and `margin` is already handled.
final RegExp _areaRelativeFrom = RegExp(
  r'relativeFrom="(?:column|paragraph|line|character|topMargin|bottomMargin'
  r'|leftMargin|rightMargin|insideMargin|outsideMargin)"',
);

/// Rewrites the parts of a DOCX package that the editor renders incorrectly
/// for Word pages composed from floating text boxes, before the bytes reach
/// the office engine:
///
///  * every `mc:Fallback` branch is removed so a text box that Word stores
///    twice (DrawingML + VML) is imported exactly once;
///  * inside `wp:anchor`, area-relative `positionH`/`positionV` offsets
///    (column, paragraph, line, ...) are rewritten to `margin`, which the
///    engine positions from the page's text area instead of the page corner,
///    so cover text boxes keep their authored offsets and stop stacking on
///    top of each other.
///
/// Page size, margins, page breaks, runs, tables and all other XML are left
/// byte-identical. If nothing needs changing (or the package is not a ZIP),
/// the original bytes are returned unchanged.
Uint8List sanitizeDocxForEditor(Uint8List bytes) {
  Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object {
    return bytes;
  }

  var changed = false;
  for (final ArchiveFile file in archive.files.toList()) {
    if (!file.isFile || !_storyPart.hasMatch(file.name)) {
      continue;
    }
    final String xml = utf8.decode(file.content, allowMalformed: true);
    final String cleaned = _sanitizeStoryXml(xml);
    if (cleaned == xml) {
      continue;
    }
    final Uint8List cleanedBytes = Uint8List.fromList(utf8.encode(cleaned));
    final CompressionType? compression = file.compression;
    archive.removeFile(file);
    final ArchiveFile replacement = ArchiveFile(
      file.name,
      cleanedBytes.length,
      cleanedBytes,
    )..compression = compression;
    archive.addFile(replacement);
    changed = true;
  }

  if (!changed) {
    return bytes;
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

String _sanitizeStoryXml(String xml) {
  var out = xml.replaceAll(_selfClosingFallback, '');
  out = out.replaceAll(_pairedFallback, '');
  out = out.replaceAllMapped(_anchorElement, (final Match match) {
    final String anchor = match.group(0)!;
    return anchor.replaceAll(_areaRelativeFrom, 'relativeFrom="margin"');
  });
  return out;
}

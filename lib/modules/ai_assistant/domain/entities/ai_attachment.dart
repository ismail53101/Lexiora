import 'dart:convert';

/// How image and PDF attachments are carried inside [AiMessage.content].
///
/// No database column exists for attachments, so attachment metadata is stored
/// in hidden control lines before the user-visible message text. The parser
/// removes those lines before rendering a message, while the AI service can
/// still use extracted PDF context when constructing the request.
class AiAttachment {
  const AiAttachment._({
    required this.imagePath,
    required this.pdfPath,
    required this.pdfName,
    required this.pdfText,
    required this.text,
  });

  final String? imagePath;
  final String? pdfPath;
  final String? pdfName;
  final String? pdfText;
  final String text;

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasPdf => pdfPath != null && pdfPath!.isNotEmpty;

  static const String _imagePrefix = '\u0001ai_image:';
  static const String _pdfPrefix = '\u0001ai_pdf:';
  static const String _pdfNamePrefix = '\u0001ai_pdf_name:';
  static const String _pdfTextPrefix = '\u0001ai_pdf_text:';

  static String encode({
    required String? imagePath,
    String? pdfPath,
    String? pdfName,
    String? pdfText,
    required String text,
  }) {
    final List<String> headers = <String>[];
    if (imagePath != null && imagePath.isNotEmpty) {
      headers.add('$_imagePrefix$imagePath');
    }
    if (pdfPath != null && pdfPath.isNotEmpty) {
      headers.add('$_pdfPrefix$pdfPath');
      if (pdfName != null && pdfName.isNotEmpty) {
        headers.add('$_pdfNamePrefix$pdfName');
      }
      if (pdfText != null && pdfText.isNotEmpty) {
        headers.add('$_pdfTextPrefix${base64UrlEncode(utf8.encode(pdfText))}');
      }
    }
    if (headers.isEmpty) return text;
    return '${headers.join('\n')}\n$text';
  }

  static AiAttachment parse(String content) {
    String? imagePath;
    String? pdfPath;
    String? pdfName;
    String? pdfText;
    final List<String> lines = content.split('\n');
    int firstVisibleLine = 0;

    while (firstVisibleLine < lines.length) {
      final String line = lines[firstVisibleLine];
      if (line.startsWith(_imagePrefix)) {
        imagePath = line.substring(_imagePrefix.length);
      } else if (line.startsWith(_pdfPrefix)) {
        pdfPath = line.substring(_pdfPrefix.length);
      } else if (line.startsWith(_pdfNamePrefix)) {
        pdfName = line.substring(_pdfNamePrefix.length);
      } else if (line.startsWith(_pdfTextPrefix)) {
        try {
          pdfText = utf8.decode(
            base64Url.decode(line.substring(_pdfTextPrefix.length)),
          );
        } on FormatException {
          pdfText = null;
        }
      } else {
        break;
      }
      firstVisibleLine++;
    }

    return AiAttachment._(
      imagePath: imagePath,
      pdfPath: pdfPath,
      pdfName: pdfName,
      pdfText: pdfText,
      text: lines.skip(firstVisibleLine).join('\n'),
    );
  }
}

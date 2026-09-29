import 'dart:html' as html;
import 'dart:typed_data';

Future<void> shareBytes(List<int> bytes, String filename, String mime) async {
  final html.Blob blob = html.Blob(<Object>[Uint8List.fromList(bytes)], mime);
  final String url = html.Url.createObjectUrlFromBlob(blob);
  final html.AnchorElement anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

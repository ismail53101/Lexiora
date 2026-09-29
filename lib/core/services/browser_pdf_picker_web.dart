import 'dart:html' as html;

import 'browser_pdf_store.dart';
import 'pdf_discovery_service.dart';

Future<List<DeviceFile>> pickBrowserPdfs() async {
  final html.FileUploadInputElement input = html.FileUploadInputElement()
    ..accept = '.pdf,application/pdf'
    ..multiple = true;
  input.click();
  await input.onChange.first;

  final List<html.File> files = input.files ?? const <html.File>[];
  final List<DeviceFile> saved = <DeviceFile>[];
  for (final html.File file in files) {
    saved.add(await storeBrowserPdf(file));
  }
  return saved;
}

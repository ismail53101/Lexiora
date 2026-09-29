import 'pdf_discovery_service.dart';

Future<DeviceFile> storeBrowserPdf(Object file) async =>
    throw UnsupportedError('Browser PDF storage is only available on Web.');

Future<String> resolveBrowserPdf(String path) async => path;
Future<List<int>> readBrowserPdfBytes(String path) async =>
    throw UnsupportedError('Browser PDF storage is only available on Web.');
Future<void> deleteBrowserPdf(String path) async {}
Future<void> releaseBrowserPdf(String path) async {}

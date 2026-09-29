import 'pdf_discovery_service.dart';

Future<DeviceFile> storeBrowserPdf(Object file) async =>
    throw UnsupportedError('Browser PDF storage is only available on Web.');

Future<String> resolveBrowserPdf(String path) async => path;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/features/reader/data/pdf_edit_service.dart';

void main() {
  test('overwrites the selected PDF path with editor bytes', () async {
    final Directory directory =
        await Directory.systemTemp.createTemp('lexiora_pdf_edit_');
    addTearDown(() => directory.delete(recursive: true));
    final File file = File('${directory.path}/document.pdf');
    await file.writeAsBytes(<int>[1, 2, 3]);

    await const PdfEditService().overwrite(
      filePath: file.path,
      bytes: Uint8List.fromList(<int>[37, 80, 68, 70]),
    );

    expect(await file.readAsBytes(), <int>[37, 80, 68, 70]);
  });
}

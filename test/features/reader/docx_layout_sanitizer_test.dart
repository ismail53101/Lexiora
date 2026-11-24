import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/features/reader/data/docx_layout_sanitizer.dart';

const String _documentXml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="w" xmlns:mc="mc" xmlns:wp="wp" xmlns:v="v" xmlns:wps="wps" xmlns:a="a">
<w:body>
<w:p><w:pPr><w:jc w:val="center"/></w:pPr>
<w:r><mc:AlternateContent>
<mc:Choice Requires="wps"><w:drawing><wp:anchor behindDoc="0">
<wp:positionH relativeFrom="column"><wp:posOffset>1000000</wp:posOffset></wp:positionH>
<wp:positionV relativeFrom="paragraph"><wp:posOffset>2000000</wp:posOffset></wp:positionV>
<wp:extent cx="3000000" cy="400000"/>
<a:graphic><a:graphicData><wps:wsp><wps:txbx><w:txbxContent>
<w:p><w:r><w:t>Ms. Tahira Hayat</w:t></w:r></w:p>
</w:txbxContent></wps:txbx></wps:wsp></a:graphicData></a:graphic>
</wp:anchor></w:drawing></mc:Choice>
<mc:Fallback><w:pict><v:shape><v:textbox><w:txbxContent>
<w:p><w:r><w:t>Ms. Tahira Hayat</w:t></w:r></w:p>
</w:txbxContent></v:textbox></v:shape></w:pict></mc:Fallback>
</mc:AlternateContent></w:r></w:p>
<w:p><w:r><w:drawing><wp:anchor behindDoc="1">
<wp:positionH relativeFrom="page"><wp:posOffset>500000</wp:posOffset></wp:positionH>
<wp:positionV relativeFrom="page"><wp:posOffset>600000</wp:posOffset></wp:positionV>
<wp:extent cx="1000000" cy="200000"/>
<a:graphic><a:graphicData><wps:wsp><wps:txbx><w:txbxContent>
<w:p><w:r><w:t>Date 05-08-2026</w:t></w:r></w:p>
</w:txbxContent></wps:txbx></wps:wsp></a:graphicData></a:graphic>
</wp:anchor></w:drawing></w:r></w:p>
<w:p><w:r><w:t>981; &#1593;&#1608;&#1585;&#1605;&#1583;</w:t></w:r><w:br w:type="page"/></w:p>
<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:left="1440" w:bottom="1440" w:right="1440"/></w:sectPr>
</w:body></w:document>''';

Uint8List _buildDocx({String documentXml = _documentXml}) {
  final Archive archive = Archive();
  final Uint8List xmlBytes = Uint8List.fromList(utf8.encode(documentXml));
  archive.addFile(ArchiveFile('word/document.xml', xmlBytes.length, xmlBytes));
  const String other = '<styles>mc:Fallback stays here</styles>';
  final Uint8List otherBytes = Uint8List.fromList(utf8.encode(other));
  archive.addFile(ArchiveFile('word/styles.xml', otherBytes.length, otherBytes));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

String _readDocument(Uint8List bytes) {
  final Archive archive = ZipDecoder().decodeBytes(bytes);
  final ArchiveFile? file = archive.findFile('word/document.xml');
  expect(file, isNotNull);
  return utf8.decode(file!.content);
}

void main() {
  group('sanitizeDocxForEditor', () {
    test('removes every mc:Fallback branch so text boxes render once', () {
      final Uint8List out = sanitizeDocxForEditor(_buildDocx());
      final String xml = _readDocument(out);
      expect(xml, isNot(contains('Fallback')));
      expect(xml, isNot(contains('w:pict')));
      expect(xml, contains('mc:Choice'));
      expect(xml.split('Ms. Tahira Hayat').length - 1, 1,
          reason: 'text box content must appear exactly once');
    });

    test('rewrites area-relative anchor offsets to margin, keeps page', () {
      final Uint8List out = sanitizeDocxForEditor(_buildDocx());
      final String xml = _readDocument(out);
      expect(xml, isNot(contains('relativeFrom="column"')));
      expect(xml, isNot(contains('relativeFrom="paragraph"')));
      expect(xml, contains('relativeFrom="margin"'));
      expect(xml, contains('relativeFrom="page"'),
          reason: 'true page-absolute anchors must stay untouched');
      expect(xml, contains('<wp:posOffset>1000000</wp:posOffset>'));
    });

    test('preserves page size, margins, page breaks and non-latin text', () {
      final Uint8List out = sanitizeDocxForEditor(_buildDocx());
      final String xml = _readDocument(out);
      expect(xml, contains('<w:pgSz w:w="11906" w:h="16838"/>'));
      expect(xml, contains('<w:pgMar w:top="1440"'));
      expect(xml, contains('<w:br w:type="page"/>'));
      expect(xml, contains('&#1593;&#1608;&#1585;&#1605;&#1583;'));
    });

    test('leaves non-story parts untouched', () {
      final Uint8List out = sanitizeDocxForEditor(_buildDocx());
      final Archive archive = ZipDecoder().decodeBytes(out);
      final ArchiveFile? styles = archive.findFile('word/styles.xml');
      expect(styles, isNotNull);
      expect(utf8.decode(styles!.content), contains('mc:Fallback stays here'));
    });

    test('returns the original bytes when nothing needs changing', () {
      const String plain = '<w:document><w:body><w:p><w:r><w:t>Hi</w:t></w:r></w:p>'
          '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/></w:sectPr></w:body></w:document>';
      final Uint8List input = _buildDocx(documentXml: plain);
      expect(sanitizeDocxForEditor(input), equals(input));
    });

    test('returns non-zip input unchanged', () {
      final Uint8List input = Uint8List.fromList(utf8.encode('not a zip'));
      expect(sanitizeDocxForEditor(input), equals(input));
    });
  });
}

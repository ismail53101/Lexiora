import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';

LibraryDocument _doc({int size = 0}) => LibraryDocument(
      id: 'i',
      title: 't',
      fileName: 'f',
      filePath: 'p',
      fileSize: size,
      pageCount: 0,
      isFavorite: false,
      importedAt: DateTime(2026),
    );

void main() {
  group('LibraryDocument.readableSize', () {
    test('formats byte counts into human-readable units', () {
      expect(_doc().readableSize, '—');
      expect(_doc(size: 512).readableSize, '512 B');
      expect(_doc(size: 2048).readableSize, '2.0 KB');
      expect(_doc(size: 5 * 1024 * 1024).readableSize, '5.0 MB');
    });
  });

  test('LibraryEntry exposes a rounded percent label', () {
    final LibraryEntry entry = LibraryEntry(
      document: _doc(),
      lastPage: 5,
      totalPages: 10,
      percent: 0.5,
    );
    expect(entry.percentLabel, 50);
  });
}

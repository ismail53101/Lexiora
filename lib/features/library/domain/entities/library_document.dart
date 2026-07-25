import 'package:equatable/equatable.dart';

/// Canonical de-dup key for a document, based on its immutable original file
/// name (without extension, lowercased) and byte size. Shared by automatic
/// discovery and manual import so the same file is never indexed twice — and
/// stable across renames, which only change the display title.
String libraryDedupKey(String fileName, int fileSize) =>
    '${fileName.trim().toLowerCase()}|$fileSize';

/// A PDF in the user's library, with its metadata.
class LibraryDocument extends Equatable {
  const LibraryDocument({
    required this.id,
    required this.title,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.pageCount,
    required this.isFavorite,
    required this.importedAt,
    this.coverPath,
    this.categoryId,
    this.lastOpenedAt,
    this.isManaged = false,
  });

  final String id;
  final String title;
  final String fileName;
  final String filePath;
  final int fileSize;
  final int pageCount;
  final bool isFavorite;
  final DateTime importedAt;
  final String? coverPath;
  final String? categoryId;
  final DateTime? lastOpenedAt;

  /// True when [filePath] is a private copy the app made during manual import
  /// (so it is deleted with the document). False for in-place discovered files.
  final bool isManaged;

  /// Human-friendly file size, e.g. "2.4 MB".
  String get readableSize {
    if (fileSize <= 0) return '—';
    const List<String> units = ['B', 'KB', 'MB', 'GB'];
    double size = fileSize.toDouble();
    int unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        fileName,
        filePath,
        fileSize,
        pageCount,
        isFavorite,
        importedAt,
        coverPath,
        categoryId,
        lastOpenedAt,
        isManaged,
      ];
}

/// A library document paired with its reading progress — used by the Home
/// "Continue reading" row. Decoupled from the reading_progress entity so the
/// two features stay independent.
class LibraryEntry extends Equatable {
  const LibraryEntry({
    required this.document,
    required this.lastPage,
    required this.totalPages,
    required this.percent,
  });

  final LibraryDocument document;
  final int lastPage;
  final int totalPages;
  final double percent;

  int get percentLabel => (percent * 100).round();

  @override
  List<Object?> get props => [document, lastPage, totalPages, percent];
}

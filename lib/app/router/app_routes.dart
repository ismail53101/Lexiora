/// Centralized route paths and names.
///
/// Keeping these as constants (rather than scattering string literals) means a
/// route can be referenced type-safely from anywhere, and future modules add
/// their own constants here without touching existing routes.
abstract final class AppRoutes {
  // Core / Phase 1
  static const String home = '/';
  static const String library = '/library';
  static const String settings = '/settings';

  static const String readerName = 'reader';
  static const String readerPattern = '/reader/:id';
  static String reader(String documentId) => '/reader/$documentId';

  static const String bookmarksName = 'bookmarks';
  static const String bookmarksPattern = '/documents/:id/bookmarks';
  static String bookmarks(String documentId) => '/documents/$documentId/bookmarks';

  static const String notesName = 'notes';
  static const String notesPattern = '/documents/:id/notes';
  static String notes(String documentId) => '/documents/$documentId/notes';

  static const String highlightsName = 'highlights';
  static const String highlightsPattern = '/documents/:id/highlights';
  static String highlights(String documentId) =>
      '/documents/$documentId/highlights';
}

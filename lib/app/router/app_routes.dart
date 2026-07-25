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

  // Dictionary (Phase 2.1)
  static const String dictionary = '/dictionary';
  static const String dictionaryWordName = 'dictionaryWord';
  static const String dictionaryWordPattern = '/dictionary/word/:word';
  static String dictionaryWord(String word) =>
      '/dictionary/word/${Uri.encodeComponent(word)}';

  // Grammar (Phase v0.4.0 / hierarchy v0.5.0)
  static const String grammar = '/grammar';
  static const String grammarTopicName = 'grammarTopic';
  static const String grammarTopicPattern = '/grammar/topic/:id';
  static String grammarTopic(String id) =>
      '/grammar/topic/${Uri.encodeComponent(id)}';
  static const String grammarLessonName = 'grammarLesson';
  static const String grammarLessonPattern = '/grammar/lesson/:id';
  static String grammarLesson(String id) =>
      '/grammar/lesson/${Uri.encodeComponent(id)}';

  // Vocabulary (Phase v0.6.0)
  static const String vocabulary = '/vocabulary';
  static const String vocabularyListName = 'vocabularyList';
  static const String vocabularyListPattern = '/vocabulary/list/:id';
  static String vocabularyList(String id) =>
      '/vocabulary/list/${Uri.encodeComponent(id)}';

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

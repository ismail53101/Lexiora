/// Centralized route paths and names.
///
/// Keeping these as constants (rather than scattering string literals) means a
/// route can be referenced type-safely from anywhere, and future modules add
/// their own constants here without touching existing routes.
abstract final class AppRoutes {
  // Core / Phase 1
  static const String splash = '/splash';
  static const String home = '/';
  static const String library = '/library';
  static const String settings = '/settings';
  static const String admin = '/admin';
  static const String profile = '/profile';

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

  // Study Hub (Phase v0.7.0 / v0.7.1)
  static const String studyHub = '/study-hub';
  static const String studyHubDaily = '/study-hub/daily';
  static const String studyHubWeekly = '/study-hub/weekly';
  static const String studyHubMonthly = '/study-hub/monthly';
  static const String studyHubTemplates = '/study-hub/templates';
  static const String studyHubSearch = '/study-hub/search';
  static const String studyHubSubjects = '/study-hub/subjects';
  static const String studyHubExport = '/study-hub/export';

  // Flashcards (Phase v0.8.0)
  static const String flashcards = '/flashcards';
  static const String flashcardsDecks = '/flashcards/decks';
  static const String flashcardsDeckName = 'flashcardsDeck';
  static const String flashcardsDeckPattern = '/flashcards/deck/:id';
  static String flashcardsDeck(String id) =>
      '/flashcards/deck/${Uri.encodeComponent(id)}';
  static const String flashcardsStudy = '/flashcards/study';
  static const String flashcardsSearch = '/flashcards/search';
  static const String flashcardsStats = '/flashcards/stats';
  static const String flashcardsImport = '/flashcards/import';
  static const String flashcardsExport = '/flashcards/export';

  // Quiz Engine (Phase v0.9.0 / subject-first v0.9.1)
  static const String quiz = '/quiz';
  static const String quizMcqs = '/quiz/mcqs';
  static const String quizStages = '/quiz/stages';
  static const String quizMcqBrowseName = 'quizMcqBrowse';
  static const String quizMcqBrowsePattern = '/quiz/mcqs/browse/:subjectId';
  static String quizMcqBrowse(String subjectId) =>
      '/quiz/mcqs/browse/${Uri.encodeComponent(subjectId)}';
  static const String quizSubjectName = 'quizSubject';
  static const String quizSubjectPattern = '/quiz/subject/:id';
  static String quizSubject(String id) =>
      '/quiz/subject/${Uri.encodeComponent(id)}';
  static const String quizTopicName = 'quizTopic';
  static const String quizTopicPattern = '/quiz/topic/:id';
  static String quizTopic(String id) => '/quiz/topic/${Uri.encodeComponent(id)}';
  static const String quizPlayer = '/quiz/play';
  static const String quizAnalytics = '/quiz/analytics';
  static const String quizWrong = '/quiz/wrong';
  static const String quizBookmarks = '/quiz/bookmarks';
  static const String quizSearch = '/quiz/search';
  static const String quizSettings = '/quiz/settings';

  // Staged Quiz (Phase v0.11.0)
  static const String quizStageMapName = 'quizStageMap';
  static const String quizStageMapPattern = '/quiz/stage-map/:subjectId';
  static String quizStageMap(String subjectId) =>
      '/quiz/stage-map/${Uri.encodeComponent(subjectId)}';
  static const String quizStagePlay = '/quiz/stage-play';

  // AI Assistant (Phase v0.10.0)
  static const String aiAssistant = '/ai';
  static const String notesHome = '/notes';

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

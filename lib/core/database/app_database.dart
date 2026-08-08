import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:lexiora/core/constants/db_constants.dart';
// converters.dart + normalized_rect.dart are imported so the generated part
// (app_database.g.dart) can resolve the NormalizedRectListConverter and
// NormalizedRect types used by the highlight/note rect columns.
import 'package:lexiora/core/database/converters.dart';
import 'package:lexiora/core/database/tables.dart';
import 'package:lexiora/core/models/normalized_rect.dart';

part 'app_database.g.dart';

/// The single Drift database for Lexiora.
///
/// All features share one SQLite database (one file, one source of truth) while
/// each feature's repository owns its own queries. New tables for future
/// modules are added here with a bumped [schemaVersion] and a migration step —
/// existing tables are never rewritten.
@DriftDatabase(
  tables: [
    Documents,
    Categories,
    Bookmarks,
    Highlights,
    Notes,
    ReadingProgress,
    ReadingSessions,
    Settings,
    DictionaryEntries,
    DictionaryFavorites,
    DictionaryExamEntries,
    DictionarySearchHistory,
    TranslationEntries,
    TranslationCache,
    GrammarLessons,
    GrammarProgress,
    GrammarFavorites,
    GrammarTopics,
    VocabularyLists,
    VocabularyWords,
    StudyTasks,
    StudyGoals,
    StudySessions,
    StudyTemplates,
    StudyTemplateItems,
    StudySubjects,
    Decks,
    Flashcards,
    ReviewLogs,
    QuizBanks,
    QuizQuestions,
    QuizAttempts,
    QuizAttemptAnswers,
    QuizWrongAnswers,
    QuizSettingsRows,
    QuizSubjects,
    QuizTopics,
    QuizStageProgress,
    AiConversations,
    AiMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database. A custom [executor] can be injected for
  /// tests (e.g. an in-memory database).
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => DbConstants.schemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v1 → v2: introduce the offline Dictionary tables. Purely additive —
          // existing tables and their data are left untouched.
          if (from < 2) {
            await m.createTable(dictionaryEntries);
            await m.createTable(dictionaryFavorites);
          }
          // v2 → v3: add the managed-file flag to documents. Additive; existing
          // rows default to false (in-place, never auto-deleted).
          if (from < 3) {
            await m.addColumn(documents, documents.managedFile);
          }
          // v3 → v4: add the offline translation table. Additive.
          if (from < 4) {
            await m.createTable(translationEntries);
          }
          // v4 → v5: add the offline Grammar tables. Purely additive —
          // existing tables and their data are left untouched.
          if (from < 5) {
            await m.createTable(grammarLessons);
            await m.createTable(grammarProgress);
            await m.createTable(grammarFavorites);
          }
          // v5 → v6: add the online-translation cache. Additive; the bundled
          // translation table and all existing data are untouched.
          if (from < 6) {
            await m.createTable(translationCache);
          }
          // v6 → v7: Dictionary v2 — curated exam word pack + search history.
          // Additive; existing dictionary tables and data are untouched.
          if (from < 7) {
            await m.createTable(dictionaryExamEntries);
            await m.createTable(dictionarySearchHistory);
          }
          // v7 → v8: Grammar hierarchy tree. Additive; grammar_progress and
          // grammar_favorites are reused (keyed by leaf id).
          if (from < 8) {
            await m.createTable(grammarTopics);
          }
          // v8 → v9: Vocabulary module (A–Z learning lists). Purely additive —
          // existing tables and their data are left untouched.
          if (from < 9) {
            await m.createTable(vocabularyLists);
            await m.createTable(vocabularyWords);
          }
          // v9 → v10: Study Hub (personal dashboard). Purely additive.
          if (from < 10) {
            await m.createTable(studyTasks);
            await m.createTable(studyGoals);
            await m.createTable(studySessions);
          }
          // v10 → v11: Study Hub → Academic Planning System. Additive columns
          // on study_tasks + template tables. Existing rows remain valid.
          if (from < 11) {
            await m.addColumn(studyTasks, studyTasks.topic);
            await m.addColumn(studyTasks, studyTasks.notes);
            await m.addColumn(studyTasks, studyTasks.status);
            await m.addColumn(studyTasks, studyTasks.durationMinutes);
            await m.addColumn(studyTasks, studyTasks.kind);
            await m.createTable(studyTemplates);
            await m.createTable(studyTemplateItems);
          }
          // v11 → v12: Study Hub productivity — subject colours. Additive.
          if (from < 12) {
            await m.createTable(studySubjects);
          }
          // v12 → v13: Flashcards module. Purely additive.
          if (from < 13) {
            await m.createTable(decks);
            await m.createTable(flashcards);
            await m.createTable(reviewLogs);
          }
          // v13 → v14: Quiz Engine module. Purely additive; ships empty.
          if (from < 14) {
            await m.createTable(quizBanks);
            await m.createTable(quizQuestions);
            await m.createTable(quizAttempts);
            await m.createTable(quizAttemptAnswers);
            await m.createTable(quizWrongAnswers);
            await m.createTable(quizSettingsRows);
          }
          // v14 → v15: Quiz subject-first hierarchy. Additive tables + columns.
          if (from < 15) {
            await m.createTable(quizSubjects);
            await m.createTable(quizTopics);
            await m.addColumn(quizBanks, quizBanks.subjectId);
            await m.addColumn(quizBanks, quizBanks.topicId);
            await m.addColumn(quizBanks, quizBanks.orderIndex);
            await m.addColumn(quizQuestions, quizQuestions.subjectId);
            await m.addColumn(quizQuestions, quizQuestions.topicId);
          }
          // v15 → v16: AI Assistant chat persistence. Purely additive.
          if (from < 16) {
            await m.createTable(aiConversations);
            await m.createTable(aiMessages);
          }
          // v16 → v17: Staged Quiz progress. Purely additive.
          if (from < 17) {
            await m.createTable(quizStageProgress);
          }
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Search-critical indexes. Created idempotently on every open so they
          // exist on both fresh installs and upgrades without special-casing.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_dictionary_word_lower '
            'ON dictionary_entries (word_lower)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_dictionary_word_lower_id '
            'ON dictionary_entries (word_lower, id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_translation_lang_word '
            'ON translation_entries (lang_code, word_lower)',
          );
          // Grammar: fast category+order listing and substring search.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_grammar_category_order '
            'ON grammar_lessons (category, order_index)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_grammar_search '
            'ON grammar_lessons (search_text)',
          );
          // Grammar tree: fast children lookups and leaf search.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_grammar_topics_parent '
            'ON grammar_topics (parent_id, order_index)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_grammar_topics_search '
            'ON grammar_topics (search_text)',
          );
          // Vocabulary: fast A–Z listing per list, headword lookup, and search.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_vocab_words_list_letter_order '
            'ON vocabulary_words (list_id, letter, order_index)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_vocab_words_lower '
            'ON vocabulary_words (word_lower)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_vocab_words_search '
            'ON vocabulary_words (search_text)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_vocab_lists_order '
            'ON vocabulary_lists (order_index)',
          );
          // Study Hub: fast per-day and per-range queries.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_study_tasks_day '
            'ON study_tasks (day)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_study_goals_day '
            'ON study_goals (day)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_study_sessions_day '
            'ON study_sessions (day)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_study_template_items_template '
            'ON study_template_items (template_id, order_index)',
          );
          // Study Hub v0.7.2: fast search/filter over sessions + subject lookup.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_study_tasks_subject '
            'ON study_tasks (subject)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_study_tasks_status '
            'ON study_tasks (status)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_study_tasks_priority '
            'ON study_tasks (priority)',
          );
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_study_subjects_name '
            'ON study_subjects (name_lower)',
          );
          // Flashcards: fast per-deck listing, queue, search & stats at scale.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_flashcards_deck '
            'ON flashcards (deck_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_flashcards_due '
            'ON flashcards (review_state, due_at)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_flashcards_flags '
            'ON flashcards (bookmarked, favorite)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_flashcards_subject '
            'ON flashcards (subject)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_review_logs_day '
            'ON review_logs (day)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_decks_archived '
            'ON decks (archived)',
          );
          // Quiz Engine: fast per-bank listing, search & filters at 100k+ scale.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_questions_bank '
            'ON quiz_questions (bank_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_questions_type '
            'ON quiz_questions (type)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_questions_flags '
            'ON quiz_questions (bookmarked)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_questions_subject '
            'ON quiz_questions (subject)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_questions_search '
            'ON quiz_questions (search_text)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_banks_archived '
            'ON quiz_banks (archived)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_attempts_day '
            'ON quiz_attempts (day)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_attempt_answers_attempt '
            'ON quiz_attempt_answers (attempt_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_wrong_subject '
            'ON quiz_wrong_answers (subject)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_stage_progress_subject '
            'ON quiz_stage_progress (subject_id)',
          );
          // Quiz subject-first hierarchy (v0.9.1).
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_questions_subject_id '
            'ON quiz_questions (subject_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_questions_topic_id '
            'ON quiz_questions (topic_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_banks_subject_topic '
            'ON quiz_banks (subject_id, topic_id, order_index)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_subjects_order '
            'ON quiz_subjects (order_index)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_quiz_topics_subject '
            'ON quiz_topics (subject_id, order_index)',
          );
          // AI Assistant (v0.10.0): fast per-conversation message paging + recency.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation '
            'ON ai_messages (conversation_id, order_index)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_ai_conversations_updated '
            'ON ai_conversations (updated_at)',
          );
        },
      );

  static QueryExecutor _openConnection() =>
      driftDatabase(name: DbConstants.databaseName);
}

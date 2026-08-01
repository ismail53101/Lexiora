import 'package:lexiora/core/config/build_flags.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/features/annotations/annotations_module.dart';
import 'package:lexiora/features/bookmarks/bookmarks_module.dart';
import 'package:lexiora/features/home/home_module.dart';
import 'package:lexiora/features/library/library_module.dart';
import 'package:lexiora/features/notes/notes_module.dart';
import 'package:lexiora/features/reader/reader_module.dart';
import 'package:lexiora/features/reading_progress/reading_progress_module.dart';
import 'package:lexiora/features/settings/settings_module.dart';
import 'package:lexiora/modules/admin/admin_module.dart';
import 'package:lexiora/modules/ai_assistant/ai_assistant_module.dart';
import 'package:lexiora/modules/cloud_sync/cloud_sync_module.dart';
import 'package:lexiora/modules/dictionary/dictionary_module.dart';
import 'package:lexiora/modules/flashcards/flashcards_module.dart';
import 'package:lexiora/modules/grammar/grammar_module.dart';
import 'package:lexiora/modules/quiz/quiz_module.dart';
import 'package:lexiora/modules/study_hub/study_hub_module.dart';
import 'package:lexiora/modules/translation/translation_module.dart';
import 'package:lexiora/modules/vocabulary/vocabulary_module.dart';

/// THE single source of truth for which modules the app is composed of.
///
/// To add a new feature/module, implement [FeatureModule] and append it here —
/// nothing else needs to change. DI registration, routing and Home tiles are
/// all derived from this list during bootstrap. This is the Open/Closed
/// Principle applied at the app-composition level.
///
/// Phase 1 ships the active features plus compiling placeholder scaffolds for
/// the nine planned future modules (which currently do nothing).
final List<FeatureModule> appModules = <FeatureModule>[
  // Active Phase 1 features.
  HomeModule(),
  LibraryModule(),
  ReaderModule(),
  SettingsModule(),
  ReadingProgressModule(),
  AnnotationsModule(),
  NotesModule(),
  BookmarksModule(),

  // Active Phase 2.1 feature — the offline Dictionary engine.
  DictionaryModule(),

  // Active Phase 2.2 feature — offline Translate (reader word action).
  TranslationModule(),

  // Active Phase v0.4.0 feature — the offline Grammar learning module.
  GrammarModule(),

  // Active Phase v0.6.0 feature — the offline Vocabulary module.
  VocabularyModule(),

  // Active Phase v0.7.0 feature — the Study Hub dashboard.
  StudyHubModule(),

  // Active Phase v0.8.0 feature — the Flashcards Learning Engine.
  FlashcardsModule(),

  // Active Phase v0.9.0 feature — the Quiz Engine (ships empty; content later).
  QuizModule(),

  // Active Phase v0.10.0 feature — the AI Assistant.
  AiAssistantModule(),

  // Personal-use only — see BuildFlags.enableAdmin. Excluded from the public build.
  if (BuildFlags.enableAdmin) AdminModule(),

  // Future modules — placeholder scaffolds only (no behavior yet).
  CloudSyncModule(),
];

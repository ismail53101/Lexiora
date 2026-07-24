import 'package:flutter/widgets.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';

/// Context handed to a [WordAction] when the user interacts with a word.
@immutable
class WordActionContext {
  const WordActionContext({
    required this.documentId,
    required this.pageNumber,
    required this.word,
    this.selection,
  });

  final String documentId;
  final int pageNumber;
  final String word;
  final PdfTextSelectionData? selection;
}

/// A contextual action attachable to a word in the reader's tap-on-word popup.
///
/// PHASE 1 STATUS: this is a **defined but intentionally unused** extension
/// point. No actions are registered yet, so the reader shows no word popup.
///
/// Future phases implement [WordAction] inside their modules and register them
/// with the shared [WordActionRegistry] at startup. Planned actions include
/// Dictionary (define), Translation, Synonyms, Antonyms, Pronunciation,
/// Grammar, Copy, Highlight and Save-to-Vocabulary. Because the reader reads
/// only this abstraction, none of that requires touching the reader code.
abstract interface class WordAction {
  /// Stable id, e.g. `dictionary.define`.
  String get id;

  /// Short label shown in the popup.
  String get label;

  /// Leading icon shown in the popup.
  IconData get icon;

  /// Ordering within the popup; lower comes first.
  int get priority;

  /// Runs the action. Implementations own their own navigation/UI.
  Future<void> invoke(BuildContext context, WordActionContext ctx);
}

/// Registry of [WordAction]s contributed by modules.
///
/// Registered as a singleton in the injector so any module can add actions and
/// the reader can read them. Empty in Phase 1 by design.
class WordActionRegistry {
  WordActionRegistry();

  final List<WordAction> _actions = <WordAction>[];

  /// Adds an action (idempotent by [WordAction.id]) and keeps the list ordered.
  void register(WordAction action) {
    if (_actions.any((WordAction a) => a.id == action.id)) return;
    _actions
      ..add(action)
      ..sort((WordAction a, WordAction b) => a.priority.compareTo(b.priority));
  }

  /// The currently registered actions, ordered by priority.
  List<WordAction> get actions => List<WordAction>.unmodifiable(_actions);

  /// Whether any action is available (false in Phase 1).
  bool get hasActions => _actions.isNotEmpty;
}

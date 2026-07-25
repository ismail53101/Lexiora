import 'package:flutter/material.dart';
import 'package:lexiora/core/reader_engine/word_action.dart';
import 'package:lexiora/modules/translation/presentation/widgets/translation_popup.dart';

/// The Translation module's contribution to the reader's tap-on-word extension
/// point. Sits beside the dictionary "Look up" action; selecting a single word
/// and choosing "Translate" opens the lightweight translation popup.
///
/// Priority 20 places it just after "Look up" (priority 10). The reader depends
/// only on the core [WordAction] abstraction, so this stays fully decoupled.
class TranslateWordAction implements WordAction {
  const TranslateWordAction();

  @override
  String get id => 'translation.translate';

  @override
  String get label => 'Translate';

  @override
  IconData get icon => Icons.translate;

  @override
  int get priority => 20;

  @override
  Future<void> invoke(BuildContext context, WordActionContext ctx) =>
      showTranslationPopup(context, ctx.word);
}

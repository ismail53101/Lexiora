import 'package:flutter/material.dart';
import 'package:lexiora/core/reader_engine/word_action.dart';
import 'package:lexiora/modules/dictionary/presentation/widgets/word_lookup_popup.dart';

/// The Dictionary module's contribution to the reader's tap-on-word extension
/// point. Selecting a single word in the reader and choosing "Look up" shows
/// the lightweight dictionary popup.
///
/// The reader depends only on the core [WordAction]/[WordActionRegistry]
/// abstraction, so this keeps the reader fully decoupled from the dictionary.
class DefineWordAction implements WordAction {
  const DefineWordAction();

  @override
  String get id => 'dictionary.define';

  @override
  String get label => 'Look up';

  @override
  IconData get icon => Icons.menu_book_outlined;

  @override
  int get priority => 10;

  // Dictionary lookups are single-word only by design (default: false).
  @override
  bool get supportsPhrase => false;

  @override
  Future<void> invoke(BuildContext context, WordActionContext ctx) =>
      showWordLookup(context, ctx.word);
}

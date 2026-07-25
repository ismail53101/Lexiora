import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/constants/translation_languages.dart';
import 'package:lexiora/features/settings/presentation/providers/settings_providers.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';
import 'package:lexiora/modules/translation/domain/entities/translation.dart';
import 'package:lexiora/modules/translation/presentation/providers/translation_providers.dart';

/// Shows the lightweight reader translation popup for a single selected word.
///
/// Contents (per product spec): the original word, its translated meaning in
/// the user's selected language (when available), a Copy button, and — only
/// when a translation exists — a Save to Vocabulary button.
Future<void> showTranslationPopup(BuildContext context, String selectedWord) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) =>
        _TranslationSheet(selectedWord: selectedWord),
  );
}

class _TranslationSheet extends ConsumerWidget {
  const _TranslationSheet({required this.selectedWord});

  final String selectedWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String word = selectedWord.trim();

    // Target language comes from the user's setting (offline data only).
    final String langCode = ref.watch(settingsProvider).maybeWhen(
          data: (s) => s.translationLanguage,
          orElse: () => kDefaultTranslationLanguage,
        );
    final TranslationLanguage language = translationLanguageByCode(langCode);

    final AsyncValue<Translation?> result = word.isEmpty
        ? const AsyncData<Translation?>(null)
        : ref.watch(translationProvider((word: word.toLowerCase(), lang: language.code)));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original word + target language.
            Row(
              children: [
                Flexible(
                  child: Text(
                    word.isEmpty ? 'No word selected' : word,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                _LanguageChip(language: language),
              ],
            ),
            const SizedBox(height: 14),
            result.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _Unavailable(language: language),
              data: (Translation? t) => t == null
                  ? _Unavailable(language: language)
                  : _Available(word: word, translation: t),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.language});
  final TranslationLanguage language;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.translate,
              size: 14, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(
            language.nativeName,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}

class _Available extends StatelessWidget {
  const _Available({required this.word, required this.translation});

  final String word;
  final Translation translation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          translation.text,
          style: theme.textTheme.titleLarge?.copyWith(height: 1.3),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy'),
              onPressed: () => _copy(context, translation.text),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SaveToVocabularyButton(
                word: word,
                meaning: translation.text,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied translation')));
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.language});
  final TranslationLanguage language;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'No offline translation available in ${language.englishName}.',
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          'You can change the translation language in Settings.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Saves the translated word into the shared vocabulary (the Dictionary
/// favorites store) via its public repository — the Dictionary module is used,
/// not modified. Toggles, reflecting the current saved state.
class _SaveToVocabularyButton extends StatefulWidget {
  const _SaveToVocabularyButton({required this.word, required this.meaning});

  final String word;
  final String meaning;

  @override
  State<_SaveToVocabularyButton> createState() =>
      _SaveToVocabularyButtonState();
}

class _SaveToVocabularyButtonState extends State<_SaveToVocabularyButton> {
  final DictionaryRepository _vocab = sl<DictionaryRepository>();
  bool _saved = false;
  bool _busy = true;

  String get _key => widget.word.toLowerCase();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bool saved = await _vocab.isFavorite(_key);
    if (mounted) {
      setState(() {
        _saved = saved;
        _busy = false;
      });
    }
  }

  Future<void> _toggle() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    if (_saved) {
      await _vocab.removeFavorite(_key);
    } else {
      await _vocab.addFavorite(
        wordLower: _key,
        word: widget.word,
        meaning: widget.meaning,
      );
    }
    if (!mounted) return;
    setState(() {
      _saved = !_saved;
      _busy = false;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(_saved
            ? 'Saved “${widget.word}” to vocabulary'
            : 'Removed “${widget.word}” from vocabulary'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: Icon(_saved ? Icons.star : Icons.star_border, size: 18),
      label: Text(_saved ? 'Saved to Vocabulary' : 'Save to Vocabulary'),
      onPressed: _busy ? null : _toggle,
    );
  }
}

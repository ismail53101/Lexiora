import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/constants/translation_languages.dart';
import 'package:lexiora/features/settings/presentation/providers/settings_providers.dart';
import 'package:lexiora/modules/dictionary/data/services/online_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';
import 'package:lexiora/modules/translation/domain/entities/translation.dart';
import 'package:lexiora/modules/translation/domain/entities/translation_outcome.dart';
import 'package:lexiora/modules/translation/presentation/providers/translation_providers.dart';
import 'package:lexiora/modules/vocabulary/presentation/widgets/vocab_pronunciation_button.dart';

/// Shows the lightweight reader translation popup for a single selected word.
///
/// Hybrid behaviour: it shows an offline translation instantly when one exists;
/// otherwise, if the device is online, it fetches an English→target translation
/// from the configurable provider, saves it for offline reuse, and labels the
/// source. When offline with no local result, it explains how to fetch it.
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

    final String langCode = ref.watch(settingsProvider).maybeWhen(
          data: (s) => s.translationLanguage,
          orElse: () => kDefaultTranslationLanguage,
        );
    final TranslationLanguage language = translationLanguageByCode(langCode);
    final TranslateKey key = (word: word.toLowerCase(), lang: language.code);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    word.isEmpty ? 'No word selected' : word,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (word.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 4),
                  VocabPronunciationButton(text: word),
                ],
                const SizedBox(width: 10),
                _LanguageChip(language: language),
              ],
            ),
            const SizedBox(height: 14),
            if (word.isEmpty)
              Text(
                'Select a word, phrase, or sentence in the reader to translate it.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              ref.watch(hybridTranslationProvider(key)).when(
                    loading: () => const _Loading(),
                    error: (_, _) => _NeedsInternet(
                      language: language,
                      onRetry: () =>
                          ref.invalidate(hybridTranslationProvider(key)),
                      isError: true,
                    ),
                    data: (TranslationOutcome outcome) => _Outcome(
                      word: word,
                      language: language,
                      outcome: outcome,
                      onRetry: () =>
                          ref.invalidate(hybridTranslationProvider(key)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 16),
          Text(
            'Translating…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Routes an outcome to the right view.
class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.word,
    required this.language,
    required this.outcome,
    required this.onRetry,
  });

  final String word;
  final TranslationLanguage language;
  final TranslationOutcome outcome;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (outcome.status) {
      case TranslationOutcomeStatus.offline:
      case TranslationOutcomeStatus.online:
        return _Available(
          word: word,
          language: language,
          translation: outcome.translation!,
        );
      case TranslationOutcomeStatus.unavailableOffline:
        return _NeedsInternet(language: language, onRetry: onRetry);
      case TranslationOutcomeStatus.notFound:
        return _NotFound(language: language, onRetry: onRetry);
      case TranslationOutcomeStatus.error:
        return _NeedsInternet(
          language: language,
          onRetry: onRetry,
          isError: true,
        );
    }
  }
}

/// Maps a translation target's 2-letter code to a full TTS locale — the
/// pronunciation service checks device voice availability per locale and
/// simply hides its button when one isn't installed, so an unmapped/missing
/// voice degrades gracefully rather than breaking anything.
String _ttsLocaleFor(String languageCode) => switch (languageCode) {
      'ur' => 'ur-PK',
      'ar' => 'ar-SA',
      'hi' => 'hi-IN',
      'fr' => 'fr-FR',
      'pt' => 'pt-PT',
      _ => 'en-US',
    };

class _Available extends StatelessWidget {
  const _Available({
    required this.word,
    required this.language,
    required this.translation,
  });

  final String word;
  final TranslationLanguage language;
  final Translation translation;

  bool get _isRtl => language.code == 'ur' || language.code == 'ar';

  /// Only a single word has a dictionary *definition* — a phrase or sentence
  /// doesn't, so the English-meaning block is single-word only. Mirrors the
  /// exact rule the reader itself uses to gate the "Look up" action.
  bool get _isSingleWord =>
      RegExp(r"^[A-Za-z][A-Za-z'’\-]*$").hasMatch(word);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool online = translation.source == TranslationSource.online;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_isSingleWord) ...<Widget>[
          _EnglishMeaning(word: word),
          const SizedBox(height: 16),
        ],
        Text(
          language.englishName.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Directionality(
                textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: Text(
                  translation.text,
                  style: theme.textTheme.titleLarge?.copyWith(height: 1.35),
                ),
              ),
            ),
            const SizedBox(width: 4),
            VocabPronunciationButton(
              text: translation.text,
              languageCode: _ttsLocaleFor(language.code),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SourceBadge(online: online),
        if (online) ...<Widget>[
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Icon(Icons.download_done,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Saved for offline use.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
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

/// A single word's real English dictionary definition (not just the word
/// itself echoed back) — looked up from the same offline dictionary the
/// "Look up" reader action uses. Renders nothing when the word isn't in the
/// dictionary, rather than showing an empty/misleading section.
class _EnglishMeaning extends StatefulWidget {
  const _EnglishMeaning({required this.word});
  final String word;

  @override
  State<_EnglishMeaning> createState() => _EnglishMeaningState();
}

class _EnglishMeaningState extends State<_EnglishMeaning> {
  final DictionaryRepository _dictionary = sl<DictionaryRepository>();
  final OnlineDictionaryService _online = OnlineDictionaryService();

  String? _meaning;
  String? _partOfSpeech;
  bool _fromOnline = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final DictionaryResult? local =
        await _dictionary.lookup(widget.word.toLowerCase());
    // Words the Translation module has auto-registered into the dictionary's
    // search index (so they're findable later) store whatever text the
    // translation produced — which may be Urdu/Arabic, not an English
    // definition. Only trust entries whose meaning is actually in Latin
    // script as a real English meaning.
    final bool localIsEnglish = local != null &&
        !RegExp(r'[\u0600-\u06FF\u0750-\u077F]').hasMatch(local.meaning);

    if (localIsEnglish) {
      if (mounted) {
        setState(() {
          _meaning = local.meaning;
          _partOfSpeech = local.partOfSpeech;
          _fromOnline = false;
          _loading = false;
        });
      }
      return;
    }

    // Not in the offline dictionary (or only as a non-English stand-in) —
    // fall back to a free, keyless online lookup, the same "offline-first,
    // online-fallback" shape the Urdu translation already uses.
    final OnlineDefinition? online = await _online.define(widget.word);
    if (mounted) {
      setState(() {
        _meaning = online?.meaning;
        _partOfSpeech = online?.partOfSpeech;
        _fromOnline = online != null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: Padding(
          padding: EdgeInsets.only(top: 2),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final String? meaning = _meaning;
    if (meaning == null) return const SizedBox.shrink(); // no English meaning found

    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'ENGLISH MEANING',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            if (_fromOnline) ...<Widget>[
              const SizedBox(width: 6),
              Icon(Icons.cloud_outlined,
                  size: 13, color: theme.colorScheme.onSurfaceVariant),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          meaning,
          style: theme.textTheme.titleMedium?.copyWith(height: 1.3),
        ),
        if (_partOfSpeech != null && _partOfSpeech!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            _partOfSpeech!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

/// The "Source: Offline / Online" pill.
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color bg = online
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.secondaryContainer;
    final Color fg = online
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(online ? Icons.cloud_done_outlined : Icons.offline_bolt_outlined,
              size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            online ? 'Source: Online' : 'Source: Offline',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// No offline result and either offline, or the online attempt failed.
class _NeedsInternet extends StatelessWidget {
  const _NeedsInternet({
    required this.language,
    required this.onRetry,
    this.isError = false,
  });

  final TranslationLanguage language;
  final VoidCallback onRetry;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'No offline translation found.',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          isError
              ? 'Couldn’t reach the translation service. Check your connection '
                  'and try again.'
              : 'Connect to the internet to fetch and save this translation in '
                  '${language.englishName}.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

/// The online provider was reached but had no translation for this word.
class _NotFound extends StatelessWidget {
  const _NotFound({required this.language, required this.onRetry});

  final TranslationLanguage language;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'No translation found.',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'The online dictionary has no ${language.englishName} translation for '
          'this word yet.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Try again'),
        ),
      ],
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
        children: <Widget>[
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

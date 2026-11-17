import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/cloze.dart';
import 'package:lexiora/modules/flashcards/domain/logic/csv_codec.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/fc_repository.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_content.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/card_editor_utils.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';

/// Opens the card editor; resolves to true when something was saved.
Future<bool?> openCardEditor(BuildContext context, {required String deckId, String? cardId}) =>
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext c) => FcCardEditorPage(deckId: deckId, cardId: cardId),
      ),
    );

/// Create or edit one card (basic, cloze or type-the-answer) with a live preview.
class _VoiceListeningSheet extends StatefulWidget {
  const _VoiceListeningSheet({
    required this.transcript,
    required this.onStop,
  });

  final ValueNotifier<String> transcript;
  final Future<void> Function() onStop;

  @override
  State<_VoiceListeningSheet> createState() => _VoiceListeningSheetState();
}

class _VoiceListeningSheetState extends State<_VoiceListeningSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: <BoxShadow>[
            BoxShadow(
              blurRadius: 28,
              spreadRadius: 2,
              color: Colors.black.withValues(alpha: 0.16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: _pulse,
              builder: (BuildContext context, Widget? child) {
                final double scale = 1 + (_pulse.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer,
                    ),
                    child: Icon(Icons.mic_rounded, size: 34, color: cs.primary),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text('Listening…', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            ValueListenableBuilder<String>(
              valueListenable: widget.transcript,
              builder: (BuildContext context, String value, Widget? child) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44, maxHeight: 88),
                  child: SingleChildScrollView(
                    child: Text(
                      value.isEmpty ? 'Speak now' : value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: value.isEmpty ? cs.onSurfaceVariant : cs.onSurface,
                          ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: widget.onStop,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.cloze,
    required this.onCloze,
    required this.onMic,
    required this.onImage,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onClear,
    required this.boldActive,
    required this.italicActive,
    required this.underlineActive,
    required this.listening,
  });

  final bool cloze;
  final VoidCallback onCloze;
  final VoidCallback onMic;
  final VoidCallback onImage;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onClear;
  final bool boldActive;
  final bool italicActive;
  final bool underlineActive;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 2,
      children: <Widget>[
        IconButton(tooltip: 'Cloze mode', icon: const Icon(Icons.crop_free), color: cloze ? cs.primary : null, onPressed: onCloze),
        IconButton(tooltip: 'Voice input', icon: Icon(listening ? Icons.mic : Icons.mic_none), color: listening ? cs.primary : null, onPressed: onMic),
        IconButton(tooltip: 'Insert image', icon: const Icon(Icons.image_outlined), onPressed: onImage),
        IconButton(tooltip: 'Bold', icon: const Icon(Icons.format_bold), color: boldActive ? cs.primary : null, onPressed: onBold),
        IconButton(tooltip: 'Italic', icon: const Icon(Icons.format_italic), color: italicActive ? cs.primary : null, onPressed: onItalic),
        IconButton(tooltip: 'Underline', icon: const Icon(Icons.format_underlined), color: underlineActive ? cs.primary : null, onPressed: onUnderline),
        IconButton(tooltip: 'Clear formatting', icon: const Icon(Icons.format_clear), onPressed: onClear),
      ],
    );
  }
}

class FcCardEditorPage extends ConsumerStatefulWidget {
  const FcCardEditorPage({super.key, required this.deckId, this.cardId});

  final String deckId;
  final String? cardId;

  @override
  ConsumerState<FcCardEditorPage> createState() => _FcCardEditorPageState();
}

class _FcCardEditorPageState extends ConsumerState<FcCardEditorPage> {
  final FcRichTextController _front = FcRichTextController();
  final FcRichTextController _back = FcRichTextController();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _tagInput = TextEditingController();
  final FocusNode _frontFocus = FocusNode();

  FcCardType _type = FcCardType.basic;
  final List<String> _tags = <String>[];
  bool _reversed = false;
  bool _perDeletion = true;
  bool _showAnswer = false;
  bool _multipleAnswers = false;
  bool _advancedOpen = false;
  FcRichTextController? _activeController;
  TextSelection _frontSelection = const TextSelection.collapsed(offset: 0);
  TextSelection _backSelection = const TextSelection.collapsed(offset: 0);
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  int? _previewClozeIndex;
  bool _loading = true;
  bool _saving = false;
  int _addedCount = 0;
  FcCard? _existing;
  FcDeck? _deck;

  bool get _editing => widget.cardId != null;

  @override
  void initState() {
    super.initState();
    _load();
    _front.addListener(_handleFrontChanged);
    _back.addListener(_handleBackChanged);
  }

  void _handleFrontChanged() {
    _frontSelection = _front.selection;
    if (mounted) setState(() {});
  }

  void _handleBackChanged() {
    _backSelection = _back.selection;
    if (mounted) setState(() {});
  }


  Future<void> _voiceInput() async {
    final FcRichTextController c = _editorController;
    if (_speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() {});
      return;
    }

    try {
      final PermissionStatus permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        if (mounted) {
          fcToast(
            context,
            permission.isPermanentlyDenied
                ? 'Microphone permission is blocked. Allow it in Android Settings.'
                : 'Microphone permission is required for voice input.',
          );
        }
        return;
      }

      final ValueNotifier<String> liveText = ValueNotifier<String>('');
      BuildContext? sheetContext;
      bool closed = false;

      Future<void> closeSheet() async {
        if (closed) return;
        closed = true;
        if (sheetContext != null && sheetContext!.mounted) {
          Navigator.of(sheetContext!).pop();
        }
      }

      if (!_speechReady) {
        final bool ready = await _speech.initialize(
          onStatus: (String status) {
            if ((status == 'done' || status == 'notListening') &&
                sheetContext != null) {
              closeSheet();
            }
            if (mounted) setState(() {});
          },
          onError: (SpeechRecognitionError error) {
            if (mounted) {
              fcToast(context, 'Voice input error: ${error.errorMsg}');
              setState(() {});
            }
            closeSheet();
          },
        );
        _speechReady = ready;
      }

      if (!_speechReady) {
        liveText.dispose();
        if (mounted) {
          fcToast(context, 'Speech recognition is not available on this device.');
        }
        return;
      }

      TextSelection insertionSelection =
          identical(c, _front) ? _frontSelection : _backSelection;
      if (!insertionSelection.isValid) {
        insertionSelection = TextSelection.collapsed(offset: c.text.length);
      }

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          liveText.value = result.recognizedWords;
          if (!result.finalResult) {
            if (mounted) setState(() {});
            return;
          }

          final String spoken = result.recognizedWords.trim();
          if (spoken.isEmpty) return;

          c.value = insertSpeechText(
            TextEditingValue(text: c.text, selection: insertionSelection),
            spoken,
          );
          insertionSelection = c.selection;
          if (identical(c, _front)) {
            _frontSelection = c.selection;
          } else {
            _backSelection = c.selection;
          }
          if (mounted) setState(() {});
        },
      );

      if (!_speech.isListening) {
        liveText.dispose();
        if (mounted) fcToast(context, 'Could not start speech recognition.');
        return;
      }

      if (mounted) setState(() {});
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext ctx) {
          sheetContext = ctx;
          return _VoiceListeningSheet(
            transcript: liveText,
            onStop: () async {
              await _speech.stop();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          );
        },
      );

      if (_speech.isListening) {
        await _speech.stop();
      }
      liveText.dispose();
      if (mounted) setState(() {});
    } catch (_) {
      await _speech.stop();
      if (mounted) {
        setState(() {});
        fcToast(context, 'Voice input is unavailable right now.');
      }
    }
  }

  Future<void> _load() async {
    final FcRepository repo = ref.read(fcRepositoryProvider);
    _deck = await repo.deck(widget.deckId);
    if (widget.cardId != null) {
      final FcCard? c = await repo.card(widget.cardId!);
      if (c != null) {
        _existing = c;
        _type = c.type;
        _front.loadMarkup(c.front);
        _back.loadMarkup(c.back);
        _notes.text = c.notes ?? '';
        _tags.addAll(c.tags);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _speech.stop();
    _front.removeListener(_handleFrontChanged);
    _back.removeListener(_handleBackChanged);
    _front.dispose();
    _back.dispose();
    _notes.dispose();
    _tagInput.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  FcRichTextController get _editorController => _activeController ?? _front;

  void _insertCloze() {
    if (_type != FcCardType.cloze) {
      setState(() {
        _type = FcCardType.cloze;
        _showAnswer = false;
      });
    }
    final FcRichTextController c = _front;
    final TextSelection sel = c.selection;
    if (sel.isValid && !sel.isCollapsed) {
      _wrapSelection(sameNumber: false);
      return;
    }
    final int index = nextClozeIndex(c.text);
    final int pos = sel.isValid ? sel.baseOffset : c.text.length;
    final String marker = '{{c' + index.toString() + '::}}';
    c.value = TextEditingValue(
      text: c.text.replaceRange(pos, pos, marker),
      selection: TextSelection.collapsed(offset: pos + marker.length - 2),
    );
    setState(() => _previewClozeIndex = index);
    _frontFocus.requestFocus();
  }

  Future<void> _pickImage() async {
    final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    final Directory root = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${root.path}/flashcards_media');
    if (!await dir.exists()) await dir.create(recursive: true);
    final String target = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}_${file.name}';
    await File(file.path).copy(target);
    final FcRichTextController c = _editorController;
    final int pos = c.selection.isValid ? c.selection.baseOffset : c.text.length;
    final String token = '[img:' + target + ']';
    c.value = TextEditingValue(
      text: c.text.replaceRange(pos, pos, token),
      selection: TextSelection.collapsed(offset: pos + token.length),
    );
    setState(() {});
  }

  void _swapFrontBack() {
    final String a = _front.text;
    _front.text = _back.text;
    _back.text = a;
    setState(() {});
  }

  TextSelection _selectionFor(FcRichTextController c) =>
      identical(c, _front) ? _frontSelection : _backSelection;

  void _format(String tag) {
    final FcRichTextController c = _editorController;
    c.toggleFormat(tag, _selectionFor(c));
    setState(() {});
  }

  void _clearFormatting() {
    final FcRichTextController c = _editorController;
    final TextSelection selection = _selectionFor(c);
    c.clearFormatting();
    c.value = c.value.copyWith(selection: selection);
    setState(() {});
  }

  Future<void> _translateBack() async {
    final TextSelection selection = _front.selection;
    String word = selection.isValid && !selection.isCollapsed
        ? _front.text.substring(selection.start, selection.end)
        : _front.text;

    word = word
        .replaceAll(RegExp(r'\[(?:b|i|u)\]'), '')
        .replaceAll(RegExp(r'\[/(?:b|i|u)\]'), '')
        .replaceAll(RegExp(r'\{\{c\d+::'), '')
        .replaceAll('}}', '')
        .trim();

    if (word.contains(RegExp(r'\s'))) {
      fcToast(context, 'Select one word in Front to translate.');
      return;
    }
    if (word.isEmpty) {
      fcToast(context, 'Enter or select a word first.');
      return;
    }

    try {
      final profile = await ref.read(wordProfileProvider(word.toLowerCase()).future);
      final List<String> offlineUrdu = profile.exam?.urduMeanings ?? const <String>[];
      if (offlineUrdu.isNotEmpty) {
        _back.text = offlineUrdu.take(3).join('، ');
        setState(() {});
        return;
      }

      final ai = await ref.read(wordAiEnrichmentProvider(word.toLowerCase()).future);
      final List<String> aiUrdu = ai?.urduMeanings ?? const <String>[];
      if (aiUrdu.isNotEmpty) {
        _back.text = aiUrdu.take(3).join('، ');
        setState(() {});
        return;
      }

      final result = await ref.read(lookUpWordProvider).call(word.toLowerCase());
      result.fold(
        (_) => fcToast(context, 'Translation not found for “$word”.'),
        (value) {
          final String meaning = value?.meaning.trim() ?? '';
          if (meaning.isEmpty) {
            fcToast(context, 'Translation not found for “$word”.');
            return;
          }
          _back.text = meaning;
          setState(() {});
        },
      );
    } catch (_) {
      fcToast(context, 'Translation unavailable right now.');
    }
  }

  void _addTag(String raw) {
    final String t = raw.trim().replaceAll(',', '');
    if (t.isNotEmpty && !_tags.any((String e) => e.toLowerCase() == t.toLowerCase())) {
      setState(() => _tags.add(t));
    }
    _tagInput.clear();
  }

  void _wrapSelection({required bool sameNumber}) {
    final TextSelection sel = _front.selection;
    if (!sel.isValid || sel.isCollapsed) {
      fcToast(context, 'Select the text to hide first');
      return;
    }
    final List<int> existing = clozeIndices(_front.text);
    final int index = sameNumber && existing.isNotEmpty ? existing.last : nextClozeIndex(_front.text);
    final ({String text, int caret}) r =
        wrapSelectionAsCloze(_front.text, sel.start, sel.end, index);
    _front.value = TextEditingValue(
      text: r.text,
      selection: TextSelection.collapsed(offset: r.caret),
    );
    setState(() => _previewClozeIndex = index);
    _frontFocus.requestFocus();
  }

  String? _validate() {
    final String front = _front.text.trim();
    if (front.isEmpty) return 'The front can’t be empty';
    if (_type == FcCardType.cloze) {
      if (!hasCloze(front)) return 'Hide some text with the “Hide selection” button';
    } else if (_back.text.trim().isEmpty) {
      return 'The back can’t be empty';
    }
    return null;
  }

  Future<void> _save({required bool addAnother}) async {
    final String? err = _validate();
    if (err != null) {
      fcToast(context, err);
      return;
    }
    setState(() => _saving = true);
    final FcRepository repo = ref.read(fcRepositoryProvider);
    final String? notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    try {
      if (_editing && _existing != null) {
        final FcCard c = _existing!;
        final List<int> idx = clozeIndices(_front.text);
        await repo.updateCard(c.copyWith(
          front: _front.markupText.trim(),
          back: _back.markupText.trim(),
          type: _type,
          clozeIndex: () => (_type == FcCardType.cloze && c.clozeIndex != null && idx.contains(c.clozeIndex)) ? c.clozeIndex : null,
          tags: List<String>.of(_tags),
          notes: () => notes,
        ));
        if (mounted) Navigator.pop(context, true);
        return;
      }
      final AddCardsResult r = await repo.addCards(
        widget.deckId,
        <CardDraft>[
          CardDraft(
            front: _front.markupText.trim(),
            back: _back.markupText.trim(),
            type: _type,
            tags: List<String>.of(_tags),
            notes: notes,
          ),
        ],
        reversed: _reversed && _type == FcCardType.basic,
        clozePerDeletion: _perDeletion,
        subject: _deck?.subject,
        topic: _deck?.topic,
      );
      _addedCount += r.created;
      if (!mounted) return;
      if (addAnother) {
        _front.clear();
        _back.clear();
        _notes.clear();
        setState(() {
          _saving = false;
          _showAnswer = false;
        });
        _frontFocus.requestFocus();
        fcToast(context, r.created == 1 ? 'Card added' : '${r.created} cards added');
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        fcToast(context, 'Couldn’t save: $e');
      }
    }
  }

  FcCard _previewCard() {
    final DateTime now = DateTime.now();
    final List<int> idx = clozeIndices(_front.text);
    final int? previewIndex = _previewClozeIndex != null && idx.contains(_previewClozeIndex)
        ? _previewClozeIndex
        : (idx.isEmpty ? null : idx.first);
    return FcCard(
      id: 'preview',
      deckId: widget.deckId,
      front: _front.markupText,
      back: _back.markupText,
      type: _type,
      clozeIndex: _type == FcCardType.cloze ? previewIndex : null,
      createdAt: now,
      updatedAt: now,
      fsrs: _existing?.fsrs ?? FsrsCard.fresh(now),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> tagSuggestions =
        ref.watch(fcTagSuggestionsProvider).asData?.value ?? const <String>[];
    final bool cloze = _type == FcCardType.cloze;

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? _) {
        if (!didPop) Navigator.pop(context, _addedCount > 0 ? true : null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Edit card' : 'New card'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, _addedCount > 0 ? true : null),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: _saving || _loading ? null : () => _save(addAnother: false),
              child: const Text('Save'),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: <Widget>[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _front,
                    focusNode: _frontFocus,
                    onTap: () {
                      _activeController = _front;
                      _frontSelection = _front.selection;
                    },
                    onChanged: (_) => _activeController = _front,
                    autofocus: !_editing,
                    minLines: 3,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: cloze ? 'Text' : 'Front',
                      hintText: cloze ? 'The {{c1::heart}} pumps blood' : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _EditorToolbar(
                    cloze: cloze,
                    onCloze: _insertCloze,
                    onMic: _voiceInput,
                    onImage: _pickImage,
                    onBold: () => _format('b'),
                    onItalic: () => _format('i'),
                    onUnderline: () => _format('u'),
                    onClear: _clearFormatting,
                    boldActive: _editorController.isBoldActive,
                    italicActive: _editorController.isItalicActive,
                    underlineActive: _editorController.isUnderlineActive,
                    listening: _speech.isListening,
                  ),
                  if (cloze) ...<Widget>[
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        FilledButton.tonalIcon(
                          onPressed: () => _wrapSelection(sameNumber: false),
                          icon: const Icon(Icons.visibility_off_outlined, size: 18),
                          label: const Text('Hide selection'),
                        ),
                        if (clozeIndices(_front.text).isNotEmpty)
                          OutlinedButton(
                            onPressed: () => _wrapSelection(sameNumber: true),
                            child: Text('Same blank (c${clozeIndices(_front.text).last})'),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: _back,
                    onTap: () {
                      _activeController = _back;
                      _backSelection = _back.selection;
                    },
                    minLines: cloze ? 1 : 3,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: cloze ? 'Extra info (optional)' : 'Back',
                      helperText: cloze ? 'Optional — Cloze cards can be saved without a back.' : null,
                      border: const OutlineInputBorder(),
                      suffixIcon: cloze ? null : IconButton(
                        tooltip: 'Translate from dictionary',
                        icon: const Icon(Icons.translate),
                        onPressed: _translateBack,
                      ),
                    ),
                  ),
                  if (!cloze) ...<Widget>[
                    const SizedBox(height: 8),
                    _EditorToolbar(
                      cloze: false,
                      onCloze: _insertCloze,
                      onMic: _voiceInput,
                      onImage: _pickImage,
                      onBold: () => _format('b'),
                      onItalic: () => _format('i'),
                      onUnderline: () => _format('u'),
                      onClear: _clearFormatting,
                      boldActive: _editorController.isBoldActive,
                      italicActive: _editorController.isItalicActive,
                      underlineActive: _editorController.isUnderlineActive,
                      listening: _speech.isListening,
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (cloze && clozeIndices(_front.text).length > 1) ...<Widget>[
                    Row(
                      children: <Widget>[
                        Text('Preview blank', style: theme.textTheme.titleSmall),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: <Widget>[
                                for (final int i in clozeIndices(_front.text))
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text('c$i'),
                                      selected: (_previewClozeIndex ?? clozeIndices(_front.text).first) == i,
                                      onSelected: (_) => setState(() => _previewClozeIndex = i),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: <Widget>[
                      Text('Preview', style: theme.textTheme.titleSmall),
                      const Spacer(),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(visualDensity: VisualDensity.compact),
                        segments: const <ButtonSegment<bool>>[
                          ButtonSegment<bool>(value: false, label: Text('Question')),
                          ButtonSegment<bool>(value: true, label: Text('Answer')),
                        ],
                        selected: <bool>{_showAnswer},
                        onSelectionChanged: (Set<bool> s) => setState(() => _showAnswer = s.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(minHeight: 110),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: _front.text.trim().isEmpty
                        ? Text('Start typing to see the card',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                        : FcCardFaceText(
                            card: _previewCard(),
                            face: _showAnswer ? FcFace.answer : FcFace.question,
                            fontSize: 20,
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text('Tags', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: <Widget>[
                      for (final String t in _tags)
                        InputChip(label: Text(t), onDeleted: () => setState(() => _tags.remove(t))),
                    ],
                  ),
                  TextField(
                    controller: _tagInput,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Add a tag and press done',
                      prefixIcon: Icon(Icons.sell_outlined),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _addTag,
                    onChanged: (String v) {
                      if (v.endsWith(',')) _addTag(v);
                    },
                  ),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      for (final String t in tagSuggestions.where((String s) => !_tags.contains(s)).take(6))
                        ActionChip(label: Text('#$t'), onPressed: () => _addTag(t)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notes,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes (shown after the answer)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: _advancedOpen,
                    onExpansionChanged: (bool v) => setState(() => _advancedOpen = v),
                    title: const Text('Advanced'),
                    children: <Widget>[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Multiple answers'),
                        subtitle: const Text('Separate accepted answers with |'),
                        value: _multipleAnswers,
                        onChanged: (bool v) => setState(() => _multipleAnswers = v),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Flip front and back'),
                        leading: const Icon(Icons.swap_vert),
                        onTap: _swapFrontBack,
                      ),
                    ],
                  ),
                  if (!_editing) ...<Widget>[
                    const SizedBox(height: 8),
                    if (_type == FcCardType.basic)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Also create the reverse card'),
                        subtitle: const Text('Adds back → front as a second card'),
                        value: _reversed,
                        onChanged: (bool v) => setState(() => _reversed = v),
                      ),
                    if (cloze && clozeIndices(_front.text).length > 1)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('One card per blank'),
                        subtitle: Text('Creates ${clozeIndices(_front.text).length} cards, each hiding one number'),
                        value: _perDeletion,
                        onChanged: (bool v) => setState(() => _perDeletion = v),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _save(addAnother: true),
                        icon: const Icon(Icons.add),
                        label: const Text('Save and add another'),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

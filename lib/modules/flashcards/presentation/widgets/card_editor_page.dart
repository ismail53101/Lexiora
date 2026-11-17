import 'package:flutter/material.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
  });

  final bool cloze;
  final VoidCallback onCloze;
  final VoidCallback onMic;
  final VoidCallback onImage;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 2,
      children: <Widget>[
        IconButton(tooltip: 'Cloze', icon: const Icon(Icons.crop_free), color: cloze ? cs.primary : null, onPressed: onCloze),
        IconButton(tooltip: 'Voice input', icon: const Icon(Icons.mic_none), onPressed: onMic),
        IconButton(tooltip: 'Insert image', icon: const Icon(Icons.image_outlined), onPressed: onImage),
        IconButton(tooltip: 'Bold', icon: const Icon(Icons.format_bold), onPressed: onBold),
        IconButton(tooltip: 'Italic', icon: const Icon(Icons.format_italic), onPressed: onItalic),
        IconButton(tooltip: 'Underline', icon: const Icon(Icons.format_underlined), onPressed: onUnderline),
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
  final TextEditingController _front = TextEditingController();
  final TextEditingController _back = TextEditingController();
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
  TextEditingController? _activeController;
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
    _initSpeech();
    _front.addListener(() => setState(() {}));
    _back.addListener(() => setState(() {}));
  }

  Future<void> _initSpeech() async {
    try {
      final bool ready = await _speech.initialize();
      if (mounted) setState(() => _speechReady = ready);
    } catch (_) {
      if (mounted) setState(() => _speechReady = false);
    }
  }

  Future<void> _voiceInput() async {
    final TextEditingController c = _editorController;
    if (!_speechReady) {
      fcToast(context, 'Voice input is not available on this device');
      return;
    }
    if (_speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() {});
      return;
    }
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        final String spoken = result.recognizedWords;
        if (spoken.isEmpty) return;
        final TextSelection s = c.selection;
        final int pos = s.isValid ? s.baseOffset : c.text.length;
        final String suffix = s.isCollapsed ? ' ' : '';
        final String next = c.text.replaceRange(pos, pos, spoken + suffix);
        final int caret = pos + spoken.length + suffix.length;
        c.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: caret));
        if (mounted) setState(() {});
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final FcRepository repo = ref.read(fcRepositoryProvider);
    _deck = await repo.deck(widget.deckId);
    if (widget.cardId != null) {
      final FcCard? c = await repo.card(widget.cardId!);
      if (c != null) {
        _existing = c;
        _type = c.type;
        _front.text = c.front;
        _back.text = c.back;
        _notes.text = c.notes ?? '';
        _tags.addAll(c.tags);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _speech.stop();
    _front.dispose();
    _back.dispose();
    _notes.dispose();
    _tagInput.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  TextEditingController get _editorController => _activeController ?? _front;

  void _insertCloze() {
    final TextEditingController c = _front;
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
    final TextEditingController c = _editorController;
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

  void _format(String tag) {
    final TextEditingController c = _editorController;
    final TextSelection s = c.selection;
    if (!s.isValid || s.isCollapsed) {
      fcToast(context, 'Select text first');
      return;
    }
    c.value = TextEditingValue(
      text: fcApplyMarkup(c.text, s.start, s.end, tag),
      selection: TextSelection.collapsed(offset: s.end + (tag.length * 2) + 5),
    );
    setState(() {});
  }

  void _clearFormatting() {
    final TextEditingController c = _editorController;
    final int pos = c.selection.isValid ? c.selection.baseOffset : c.text.length;
    c.text = fcClearFormatting(c.text);
    c.selection = TextSelection.collapsed(offset: pos.clamp(0, c.text.length));
    setState(() {});
  }

  Future<void> _translateBack() async {
    final String word = _front.text.trim();
    if (word.isEmpty) {
      fcToast(context, 'Enter a word or phrase first');
      return;
    }
    try {
      final result = await ref.read(lookUpWordProvider).call(word.toLowerCase());
      result.fold(
        (failure) => fcToast(context, 'Translation not found'),
        (value) {
          final String meaning = value?.meaning.trim() ?? '';
          if (meaning.isEmpty) {
            fcToast(context, 'Translation not found');
            return;
          }
          _back.text = meaning;
          setState(() {});
        },
      );
    } catch (_) {
      fcToast(context, 'Translation unavailable');
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
          front: _front.text.trim(),
          back: _back.text.trim(),
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
            front: _front.text.trim(),
            back: _type == FcCardType.cloze ? _back.text.trim() : _back.text.trim(),
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
      front: _front.text,
      back: _back.text,
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
                  SegmentedButton<FcCardType>(
                    segments: const <ButtonSegment<FcCardType>>[
                      ButtonSegment<FcCardType>(value: FcCardType.basic, label: Text('Basic'), icon: Icon(Icons.flip)),
                      ButtonSegment<FcCardType>(value: FcCardType.cloze, label: Text('Cloze'), icon: Icon(Icons.format_underlined)),
                      ButtonSegment<FcCardType>(value: FcCardType.typed, label: Text('Type'), icon: Icon(Icons.keyboard)),
                    ],
                    selected: <FcCardType>{_type},
                    onSelectionChanged: (Set<FcCardType> s) => setState(() {
                      _type = s.first;
                      _showAnswer = false;
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    switch (_type) {
                      FcCardType.basic => 'Question on the front, answer on the back.',
                      FcCardType.cloze => 'Write a sentence and hide the key words. Each hidden part is tested.',
                      FcCardType.typed => 'You type the answer and it is checked against the back.',
                    },
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _front,
                    focusNode: _frontFocus,
                    onTap: () => _activeController = _front,
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
                    onTap: () => _activeController = _back,
                    minLines: cloze ? 1 : 3,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: cloze ? 'Extra info (optional)' : 'Back',
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
                      onMic: () => fcToast(context, 'Voice input uses the keyboard microphone on this device.'),
                      onImage: _pickImage,
                      onBold: () => _format('b'),
                      onItalic: () => _format('i'),
                      onUnderline: () => _format('u'),
                      onClear: _clearFormatting,
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

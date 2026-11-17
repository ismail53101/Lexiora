import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/cloze.dart';
import 'package:lexiora/modules/flashcards/domain/logic/csv_codec.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/fc_repository.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';

/// Opens the card editor; resolves to true when something was saved.
Future<bool?> openCardEditor(BuildContext context, {required String deckId, String? cardId}) =>
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext c) => FcCardEditorPage(deckId: deckId, cardId: cardId),
      ),
    );

/// Create or edit one card (basic, cloze or type-the-answer) with a live preview.
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
    for (final TextEditingController c in <TextEditingController>[_front, _back]) {
      c.addListener(() => setState(() {}));
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
    _front.dispose();
    _back.dispose();
    _notes.dispose();
    _tagInput.dispose();
    _frontFocus.dispose();
    super.dispose();
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
                  if (cloze) ...<Widget>[
                    const SizedBox(height: 8),
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
                    minLines: cloze ? 1 : 3,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: cloze ? 'Extra info (optional)' : 'Back',
                      border: const OutlineInputBorder(),
                    ),
                  ),
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

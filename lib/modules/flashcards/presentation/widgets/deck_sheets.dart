import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';

/// Create (deck == null) or edit a deck.
Future<FcDeck?> showDeckEditor(BuildContext context, {FcDeck? deck}) =>
    showModalBottomSheet<FcDeck>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext c) => _DeckEditor(deck: deck),
    );

class _DeckEditor extends ConsumerStatefulWidget {
  const _DeckEditor({this.deck});
  final FcDeck? deck;

  @override
  ConsumerState<_DeckEditor> createState() => _DeckEditorState();
}

class _DeckEditorState extends ConsumerState<_DeckEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.deck?.name ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.deck?.description ?? '');
  late final TextEditingController _subject =
      TextEditingController(text: widget.deck?.subject ?? '');
  late int? _color = widget.deck?.color;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _subject.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      fcToast(context, 'Give the deck a name');
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(fcRepositoryProvider);
    String? clean(String s) => s.trim().isEmpty ? null : s.trim();
    final FcDeck result;
    if (widget.deck == null) {
      result = await repo.createDeck(
        name: name,
        description: clean(_description.text),
        subject: clean(_subject.text),
        color: _color,
      );
    } else {
      result = widget.deck!.copyWith(
        name: name,
        description: () => clean(_description.text),
        subject: () => clean(_subject.text),
        color: () => _color,
      );
      await repo.updateDeck(result);
    }
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> suggestions =
        ref.watch(fcSubjectSuggestionsProvider).asData?.value ?? const <String>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.deck == null ? 'New deck' : 'Edit deck',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: widget.deck == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subject,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Subject (optional)', border: OutlineInputBorder()),
            ),
            if (suggestions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final String s in suggestions.take(8))
                    ActionChip(label: Text(s), onPressed: () => setState(() => _subject.text = s)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text('Colour', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Auto'),
                  selected: _color == null,
                  onSelected: (_) => setState(() => _color = null),
                ),
                for (final int c in kDeckPalette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c ? theme.colorScheme.onSurface : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(widget.deck == null ? 'Create deck' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daily limits and memory target for a deck.
Future<void> showDeckSettings(BuildContext context, String deckId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext c) => _DeckSettingsSheet(deckId: deckId),
    );

class _DeckSettingsSheet extends ConsumerStatefulWidget {
  const _DeckSettingsSheet({required this.deckId});
  final String deckId;

  @override
  ConsumerState<_DeckSettingsSheet> createState() => _DeckSettingsSheetState();
}

class _DeckSettingsSheetState extends ConsumerState<_DeckSettingsSheet> {
  DeckSettings? _s;

  @override
  void initState() {
    super.initState();
    ref.read(fcRepositoryProvider).deckSettings(widget.deckId).then((DeckSettings v) {
      if (mounted) setState(() => _s = v);
    });
  }

  Future<void> _save() async {
    await ref.read(fcRepositoryProvider).saveDeckSettings(widget.deckId, _s!);
    if (mounted) Navigator.pop(context);
  }

  Widget _stepper(String label, String help, int value, int step, int max, ValueChanged<int> onChanged) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.titleSmall),
                Text(help, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.remove),
            onPressed: value <= 0 ? null : () => onChanged((value - step).clamp(0, max)),
          ),
          SizedBox(
            width: 52,
            child: Text('$value', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.add),
            onPressed: value >= max ? null : () => onChanged((value + step).clamp(0, max)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DeckSettings? s = _s;
    if (s == null) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    final int pct = (s.desiredRetention * 100).round();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Study settings', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _stepper('New cards per day', 'Unseen cards introduced each day', s.newPerDay, 5, 500,
                (int v) => setState(() => _s = s.copyWith(newPerDay: v))),
            _stepper('Reviews per day', 'Maximum due reviews each day', s.reviewsPerDay, 25, 2000,
                (int v) => setState(() => _s = s.copyWith(reviewsPerDay: v))),
            const Divider(height: 28),
            Text('Target memory: $pct%', style: theme.textTheme.titleSmall),
            Slider(
              min: 0.70,
              max: 0.97,
              divisions: 27,
              value: s.desiredRetention.clamp(0.70, 0.97).toDouble(),
              label: '$pct%',
              onChanged: (double v) => setState(() => _s = s.copyWith(desiredRetention: v)),
            ),
            Text(
              'How likely you want to remember a card when it comes up. Higher '
              'means shorter gaps and more daily reviews; 90% is a good balance.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Shuffle new cards'),
              subtitle: const Text('Otherwise they appear in the order you added them'),
              value: s.shuffleNew,
              onChanged: (bool v) => setState(() => _s = s.copyWith(shuffleNew: v)),
            ),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _save, child: const Text('Save'))),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/domain/entities/deck.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:uuid/uuid.dart';

const List<int> _palette = <int>[
  0xFF1E88E5, 0xFF43A047, 0xFFFB8C00, 0xFF8E24AA, 0xFFE53935,
  0xFF00ACC1, 0xFF3949AB, 0xFF7CB342, 0xFFF4511E, 0xFFD81B60,
  0xFF00897B, 0xFF6D4C41, 0xFF546E7A, 0xFF5E35B1,
];

/// Add/edit a deck.
Future<void> showDeckEditor(BuildContext context, {Deck? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _DeckEditor(existing: existing),
  );
}

class _DeckEditor extends ConsumerStatefulWidget {
  const _DeckEditor({this.existing});
  final Deck? existing;

  @override
  ConsumerState<_DeckEditor> createState() => _DeckEditorState();
}

class _DeckEditorState extends ConsumerState<_DeckEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _desc =
      TextEditingController(text: widget.existing?.description ?? '');
  late final TextEditingController _subject =
      TextEditingController(text: widget.existing?.subject ?? '');
  late final TextEditingController _topic =
      TextEditingController(text: widget.existing?.topic ?? '');
  late int? _color = widget.existing?.color;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _subject.dispose();
    _topic.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return;
    final DateTime now = DateTime.now();
    final Deck base = widget.existing ??
        Deck(id: const Uuid().v4(), name: name, createdAt: now, updatedAt: now);
    final Deck deck = base.copyWith(
      name: name,
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      subject: _subject.text.trim().isEmpty ? null : _subject.text.trim(),
      topic: _topic.text.trim().isEmpty ? null : _topic.text.trim(),
      color: _color,
      updatedAt: now,
      clearDescription: _desc.text.trim().isEmpty,
      clearSubject: _subject.text.trim().isEmpty,
      clearTopic: _topic.text.trim().isEmpty,
      clearColor: _color == null,
    );
    await ref.read(flashcardRepositoryProvider).saveDeck(deck);
    ref.read(fcRevisionProvider.notifier).bump();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.existing == null ? 'New deck' : 'Edit deck',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Deck name', hintText: 'e.g. Pakistan Affairs'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _subject,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _topic,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Topic'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Colour', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _swatch(null, theme),
                for (final int c in _palette) _swatch(c, theme),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                if (widget.existing != null)
                  TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(flashcardRepositoryProvider)
                          .deleteDeck(widget.existing!.id);
                      ref.read(fcRevisionProvider.notifier).bump();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    label: Text('Delete',
                        style: TextStyle(color: theme.colorScheme.error)),
                  ),
                const Spacer(),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(int? c, ThemeData theme) {
    final bool selected = _color == c;
    return InkWell(
      onTap: () => setState(() => _color = c),
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c == null ? theme.colorScheme.surfaceContainerHighest : Color(c),
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: theme.colorScheme.onSurface, width: 3)
              : null,
        ),
        child: c == null
            ? Icon(Icons.block, size: 18, color: theme.colorScheme.onSurfaceVariant)
            : (selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null),
      ),
    );
  }
}

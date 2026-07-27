import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:uuid/uuid.dart';

/// Add/edit a flashcard. Front & back are free text (rich-text ready).
Future<void> showCardEditor(
  BuildContext context, {
  required String deckId,
  Flashcard? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _CardEditor(deckId: deckId, existing: existing),
  );
}

class _CardEditor extends ConsumerStatefulWidget {
  const _CardEditor({required this.deckId, this.existing});
  final String deckId;
  final Flashcard? existing;

  @override
  ConsumerState<_CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends ConsumerState<_CardEditor> {
  late final TextEditingController _front =
      TextEditingController(text: widget.existing?.front ?? '');
  late final TextEditingController _back =
      TextEditingController(text: widget.existing?.back ?? '');
  late final TextEditingController _subject =
      TextEditingController(text: widget.existing?.subject ?? '');
  late final TextEditingController _topic =
      TextEditingController(text: widget.existing?.topic ?? '');
  late final TextEditingController _tags =
      TextEditingController(text: widget.existing?.tags ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.existing?.notes ?? '');
  late CardDifficulty _difficulty =
      widget.existing?.difficulty ?? CardDifficulty.none;
  late bool _bookmarked = widget.existing?.bookmarked ?? false;
  late bool _favorite = widget.existing?.favorite ?? false;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _front, _back, _subject, _topic, _tags, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final String front = _front.text.trim();
    final String back = _back.text.trim();
    if (front.isEmpty || back.isEmpty) return;
    final DateTime now = DateTime.now();
    final Flashcard base = widget.existing ??
        Flashcard(
          id: const Uuid().v4(),
          deckId: widget.deckId,
          front: front,
          back: back,
          createdAt: now,
          updatedAt: now,
        );
    final Flashcard card = base.copyWith(
      front: front,
      back: back,
      subject: _subject.text.trim().isEmpty ? null : _subject.text.trim(),
      topic: _topic.text.trim().isEmpty ? null : _topic.text.trim(),
      tags: _tags.text.trim().isEmpty ? null : _tags.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      difficulty: _difficulty,
      bookmarked: _bookmarked,
      favorite: _favorite,
      updatedAt: now,
      clearSubject: _subject.text.trim().isEmpty,
      clearTopic: _topic.text.trim().isEmpty,
      clearTags: _tags.text.trim().isEmpty,
      clearNotes: _notes.text.trim().isEmpty,
    );
    await ref.read(flashcardRepositoryProvider).saveCard(card);
    ref.read(fcRevisionProvider.notifier).bump();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> subjects = ref.watch(fcSubjectSuggestionsProvider).maybeWhen(
          data: (List<String> s) => s,
          orElse: () => const <String>[],
        );
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.existing == null ? 'New card' : 'Edit card',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _front,
              autofocus: widget.existing == null,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Front', hintText: 'e.g. What is inflation?'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _back,
              minLines: 1,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Back', hintText: 'The answer…'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subject,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Subject (optional)'),
            ),
            if (subjects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: -4,
                  children: <Widget>[
                    for (final String s in subjects.take(8))
                      ActionChip(
                        label: Text(s),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _subject.text = s,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _topic,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Topic'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tags,
                    decoration: const InputDecoration(
                        labelText: 'Tags', hintText: 'comma,separated'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 16),
            Text('Difficulty', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final CardDifficulty d in CardDifficulty.values)
                  ChoiceChip(
                    label: Text(d.label),
                    selected: _difficulty == d,
                    onSelected: (_) => setState(() => _difficulty = d),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                FilterChip(
                  avatar: const Icon(Icons.bookmark_border, size: 18),
                  label: const Text('Bookmark'),
                  selected: _bookmarked,
                  onSelected: (bool v) => setState(() => _bookmarked = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.favorite_border, size: 18),
                  label: const Text('Favourite'),
                  selected: _favorite,
                  onSelected: (bool v) => setState(() => _favorite = v),
                ),
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
                          .deleteCard(widget.existing!.id);
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
}

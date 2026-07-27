import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';

/// A study session: flip, swipe, and grade cards (Again/Hard/Good/Easy).
class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key, this.deckId, required this.mode});

  final String? deckId;
  final StudyMode mode;

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  List<Flashcard> _cards = <Flashcard>[];
  int _index = 0;
  bool _flipped = false;
  bool _loading = true;
  int _reviewed = 0;
  DateTime _shownAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({StudyMode? mode}) async {
    final List<Flashcard> cards = await ref
        .read(flashcardRepositoryProvider)
        .buildStudySession(deckId: widget.deckId, mode: mode ?? widget.mode);
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _index = 0;
      _flipped = false;
      _loading = false;
      _shownAt = DateTime.now();
    });
  }

  /// Restart immediately, without waiting for cards to become due. Studying a
  /// specific deck always replays the whole deck; the global queue re-runs itself.
  void _restart() {
    setState(() {
      _loading = true;
      _reviewed = 0;
    });
    _load(mode: widget.deckId != null ? StudyMode.all : widget.mode);
  }

  Future<void> _rate(CardRating rating) async {
    final Flashcard card = _cards[_index];
    final int durationMs = DateTime.now().difference(_shownAt).inMilliseconds;
    await ref
        .read(flashcardRepositoryProvider)
        .recordReview(card.id, rating, durationMs: durationMs);
    _reviewed++;
    _next();
  }

  void _next() {
    if (_index < _cards.length - 1) {
      setState(() {
        _index++;
        _flipped = false;
        _shownAt = DateTime.now();
      });
    } else {
      setState(() => _index = _cards.length); // finished
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() {
        _index--;
        _flipped = false;
        _shownAt = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mode.label)),
        body: const Center(child: Text('No cards to study here.')),
      );
    }
    if (_index >= _cards.length) return _summary(theme);

    final Flashcard card = _cards[_index];
    ref.watch(fcSubjectColorsProvider); // keep colours warm

    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1} / ${_cards.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_index + 1) / _cards.length),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(card.bookmarked ? Icons.bookmark : Icons.bookmark_border),
            tooltip: 'Bookmark',
            onPressed: () async {
              await ref
                  .read(flashcardRepositoryProvider)
                  .setBookmarked(card.id, !card.bookmarked);
              setState(() =>
                  _cards[_index] = card.copyWith(bookmarked: !card.bookmarked));
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              onHorizontalDragEnd: (DragEndDetails d) {
                final double v = d.primaryVelocity ?? 0;
                if (v < -200) {
                  _next();
                } else if (v > 200) {
                  _prev();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _face(theme, card, _flipped),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              _flipped ? 'Tap to flip · swipe to move' : 'Tap to reveal answer',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          if (_flipped)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Row(
                children: <Widget>[
                  _rateBtn('Again', CardRating.again, theme.colorScheme.error),
                  _rateBtn('Hard', CardRating.hard, theme.colorScheme.tertiary),
                  _rateBtn('Good', CardRating.good, theme.colorScheme.primary),
                  _rateBtn('Easy', CardRating.easy, theme.colorScheme.secondary),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: FilledButton(
                onPressed: () => setState(() => _flipped = true),
                child: const Text('Show answer'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _face(ThemeData theme, Flashcard card, bool back) {
    return Card(
      key: ValueKey<bool>(back),
      color: back ? theme.colorScheme.surfaceContainerHighest : null,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(back ? 'ANSWER' : 'QUESTION',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Text(back ? card.back : card.front,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall),
              if (back && card.notes != null && card.notes!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text(card.notes!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _rateBtn(String label, CardRating rating, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton.tonal(
          onPressed: () => _rate(rating),
          style: FilledButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.18),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _summary(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session complete')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.celebration_outlined,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Reviewed $_reviewed card${_reviewed == 1 ? '' : 's'}',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Review this deck again anytime — no need to wait.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.replay),
                  label: const Text('Study again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

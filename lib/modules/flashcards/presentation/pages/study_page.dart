import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/services/pronunciation_service.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/cloze.dart';
import 'package:lexiora/modules/flashcards/domain/logic/fc_time.dart';
import 'package:lexiora/modules/flashcards/domain/logic/study_session.dart';
import 'package:lexiora/modules/flashcards/domain/logic/typed_answer.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/fc_repository.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/card_editor_page.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';

/// The study screen: flip cards, rate them, undo, and see a summary at the end.
class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key, this.deckId, this.mode = StudyMode.due});

  final String? deckId;
  final StudyMode mode;

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _Answered {
  const _Answered(this.rating, this.ms);
  final FsrsRating rating;
  final int ms;
}

class _StudyPageState extends ConsumerState<StudyPage> {
  StudySession? _session;
  Object? _error;
  bool _revealed = false;
  bool _busy = false;
  int _cardKey = 0;
  final Stopwatch _shown = Stopwatch();
  final TextEditingController _typed = TextEditingController();
  final FocusNode _keys = FocusNode();
  TypedResult? _typedResult;

  final List<String> _logIds = <String>[];
  final List<_Answered> _answers = <_Answered>[];

  bool get _practice => widget.mode.isPractice;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _typed.dispose();
    _keys.dispose();
    ref.read(fcPronunciationProvider).stop();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final StudySession s = await ref
          .read(fcRepositoryProvider)
          .startSession(deckId: widget.deckId, mode: widget.mode);
      if (!mounted) return;
      setState(() => _session = s);
      _shown.start();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  FcRepository get _repo => ref.read(fcRepositoryProvider);

  void _reveal() {
    final FcCard? c = _session?.current;
    if (c == null || _revealed) return;
    if (c.type == FcCardType.typed) {
      _typedResult = checkTypedAnswer(_typed.text, c.back);
    }
    unawaited(HapticFeedback.selectionClick());
    setState(() => _revealed = true);
  }

  Future<void> _answer(FsrsRating rating) async {
    final StudySession? s = _session;
    if (s == null || s.current == null || !_revealed || _busy) return;
    _busy = true;
    final int ms = _shown.elapsedMilliseconds.clamp(0, 60000);
    try {
      final AnswerOutcome o = s.answer(rating, DateTime.now());
      String logId = '';
      if (!_practice) logId = await _repo.recordAnswer(o, durationMs: ms);
      _logIds.add(logId);
      _answers.add(_Answered(rating, ms));
      unawaited(HapticFeedback.lightImpact());
      if (o.becameLeech && mounted) {
        fcToast(context, 'Suspended: you’ve forgotten this card ${FcCard.leechThreshold} times. Find it under “Leeches”.');
      }
      _nextCard();
    } catch (e) {
      if (mounted) fcToast(context, 'Couldn’t save that answer: $e');
    } finally {
      _busy = false;
    }
  }

  void _nextCard() {
    if (!mounted) return;
    setState(() {
      _revealed = false;
      _typedResult = null;
      _typed.clear();
      _cardKey++;
    });
    _shown
      ..reset()
      ..start();
    unawaited(ref.read(fcPronunciationProvider).stop());
  }

  Future<void> _undo() async {
    final StudySession? s = _session;
    if (s == null || !s.canUndo || _busy) return;
    _busy = true;
    try {
      final ({FcCard before, FcCard after})? u = s.undo(DateTime.now());
      if (u != null) {
        final String logId = _logIds.removeLast();
        _answers.removeLast();
        if (!_practice && logId.isNotEmpty) await _repo.undoAnswer(u.before, logId);
        _nextCard();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _speak() async {
    final FcCard? c = _session?.current;
    if (c == null) return;
    final String rawText = _revealed
        ? (c.type == FcCardType.cloze ? clozePlainText(c.front) : c.back)
        : (c.type == FcCardType.cloze
            ? clozeQuestionText(c.front, activeIndex: c.clozeIndex)
            : c.front);
    final String text = fcPlainText(rawText);
    if (text.isEmpty) return;
    final PronunciationService tts = ref.read(fcPronunciationProvider);
    final String lang = detectTextDirection(text) == TextDirection.rtl ? 'ur-PK' : 'en-US';
    if (!await tts.isAvailable(lang)) {
      if (mounted) fcToast(context, 'No voice installed for this language.');
      return;
    }
    await tts.speak(text, languageCode: lang);
  }

  Future<void> _menu(String action) async {
    final StudySession s = _session!;
    final FcCard? c = s.current;
    if (c == null) return;
    final DateTime now = DateTime.now();
    switch (action) {
      case 'undo':
        await _undo();
      case 'edit':
        final bool? saved = await openCardEditor(context, deckId: c.deckId, cardId: c.id);
        if (saved == true) {
          final FcCard? fresh = await _repo.card(c.id);
          if (fresh != null && mounted) setState(() => s.replaceCurrent(fresh));
        }
      case 'star':
        await _repo.setStarred(c.id, !c.bookmarked);
        if (mounted) setState(() => s.replaceCurrent(c.copyWith(bookmarked: !c.bookmarked)));
      case 'suspend':
        await _repo.setSuspended(c.id, true);
        if (!mounted) return;
        fcToast(context, 'Card suspended');
        s.removeCurrent(now);
        _nextCard();
      case 'bury':
        await _repo.buryUntilTomorrow(c.id);
        if (!mounted) return;
        fcToast(context, 'Hidden until tomorrow');
        s.removeCurrent(now);
        _nextCard();
      case 'delete':
        final bool ok = await fcConfirm(context, title: 'Delete this card?', message: 'Its review history is deleted too.');
        if (!ok) return;
        await _repo.deleteCards(<String>[c.id]);
        if (!mounted) return;
        s.removeCurrent(now);
        _nextCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final StudySession? s = _session;

    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text('Couldn’t start: $_error')));
    }
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (s.isFinished) return _Summary(answers: _answers, practice: _practice, deckId: widget.deckId, mode: widget.mode);

    final FcCard card = s.current!;
    final Map<FsrsRating, Duration> intervals = s.intervals(DateTime.now());
    final StudyCounts counts = s.counts;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): () => _revealed ? _answer(FsrsRating.good) : _reveal(),
        const SingleActivator(LogicalKeyboardKey.enter): () => _revealed ? _answer(FsrsRating.good) : _reveal(),
        const SingleActivator(LogicalKeyboardKey.digit1): () => _answer(FsrsRating.again),
        const SingleActivator(LogicalKeyboardKey.digit2): () => _answer(FsrsRating.hard),
        const SingleActivator(LogicalKeyboardKey.digit3): () => _answer(FsrsRating.good),
        const SingleActivator(LogicalKeyboardKey.digit4): () => _answer(FsrsRating.easy),
        const SingleActivator(LogicalKeyboardKey.keyZ): _undo,
      },
      child: Focus(
        focusNode: _keys,
        autofocus: card.type != FcCardType.typed,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: <Widget>[
                _TopBar(
                  progress: s.progress,
                  counts: counts,
                  current: card,
                  canUndo: s.canUndo,
                  starred: card.bookmarked,
                  onClose: () => Navigator.maybePop(context),
                  onMenu: _menu,
                ),
                if (_practice)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Practice mode · your schedule is not changed',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
                  ),
                Expanded(
                  child: _CardArea(
                    key: ValueKey<String>('${card.id}#$_cardKey'),
                    card: card,
                    revealed: _revealed,
                    typedResult: _typedResult,
                    typedText: _typed.text,
                    onTap: _reveal,
                    onSwipe: (FsrsRating r) => _answer(r),
                    onSpeak: _speak,
                  ),
                ),
                _Controls(
                  card: card,
                  revealed: _revealed,
                  practice: _practice,
                  intervals: intervals,
                  typed: _typed,
                  typedResult: _typedResult,
                  onReveal: _reveal,
                  onAnswer: _answer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.progress,
    required this.counts,
    required this.current,
    required this.canUndo,
    required this.starred,
    required this.onClose,
    required this.onMenu,
  });

  final double progress;
  final StudyCounts counts;
  final FcCard current;
  final bool canUndo;
  final bool starred;
  final VoidCallback onClose;
  final ValueChanged<String> onMenu;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    Widget count(int n, Color color, bool active) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text('$n',
              style: TextStyle(
                color: color,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                decoration: active ? TextDecoration.underline : null,
                decorationColor: color,
                fontSize: 15,
              )),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: <Widget>[
          IconButton(icon: const Icon(Icons.close), tooltip: 'End session', onPressed: onClose),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (BuildContext c, double v, Widget? _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          count(counts.newCount, cs.fcNew, current.isNew),
          count(counts.learningCount, cs.fcLearning, current.isLearning),
          count(counts.reviewCount, cs.fcReview, !current.isNew && !current.isLearning),
          PopupMenuButton<String>(
            onSelected: onMenu,
            itemBuilder: (BuildContext c) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'undo', enabled: canUndo, child: const Text('Undo last answer')),
              const PopupMenuItem<String>(value: 'edit', child: Text('Edit card')),
              PopupMenuItem<String>(value: 'star', child: Text(starred ? 'Remove star' : 'Star card')),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'bury', child: Text('Hide until tomorrow')),
              const PopupMenuItem<String>(value: 'suspend', child: Text('Suspend card')),
              const PopupMenuItem<String>(value: 'delete', child: Text('Delete card')),
            ],
          ),
        ],
      ),
    );
  }
}

// ── card ─────────────────────────────────────────────────────────────────────

class _CardArea extends StatefulWidget {
  const _CardArea({
    super.key,
    required this.card,
    required this.revealed,
    required this.typedResult,
    required this.typedText,
    required this.onTap,
    required this.onSwipe,
    required this.onSpeak,
  });

  final FcCard card;
  final bool revealed;
  final TypedResult? typedResult;
  final String typedText;
  final VoidCallback onTap;
  final ValueChanged<FsrsRating> onSwipe;
  final VoidCallback onSpeak;

  @override
  State<_CardArea> createState() => _CardAreaState();
}

class _CardAreaState extends State<_CardArea> {
  double _dx = 0;
  double _dy = 0;

  void _end(DragEndDetails d) {
    if (!widget.revealed) {
      setState(() {
        _dx = 0;
        _dy = 0;
      });
      return;
    }
    FsrsRating? r;
    if (_dy < -90) {
      r = FsrsRating.easy;
    } else if (_dx > 90) {
      r = FsrsRating.good;
    } else if (_dx < -90) {
      r = FsrsRating.again;
    }
    setState(() {
      _dx = 0;
      _dy = 0;
    });
    if (r != null) widget.onSwipe(r);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final FcCard card = widget.card;

    Widget face(Widget child, {required bool back}) => Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          decoration: BoxDecoration(
            color: back ? cs.secondaryContainer.withValues(alpha: 0.45) : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: child,
        );

    final Widget front = face(
      Stack(
        children: <Widget>[
          Center(child: SingleChildScrollView(child: FcCardFaceText(card: card, face: FcFace.question))),
          Positioned(top: -6, right: -6, child: IconButton(icon: const Icon(Icons.volume_up_outlined), tooltip: 'Read aloud', onPressed: widget.onSpeak)),
          Positioned(
            bottom: -4,
            left: 0,
            right: 0,
            child: Text(widget.revealed ? '' : 'Tap the card to flip',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
      back: false,
    );

    final Widget back = face(
      Stack(
        children: <Widget>[
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (card.type != FcCardType.cloze) ...<Widget>[
                    Text(card.front,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textDirection: detectTextDirection(card.front),
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const Divider(height: 28),
                  ],
                  FcCardFaceText(card: card, face: FcFace.answer),
                  if (card.type == FcCardType.typed && widget.typedResult != null) ...<Widget>[
                    const SizedBox(height: 16),
                    _TypedBadge(result: widget.typedResult!, typed: widget.typedText),
                  ],
                  if ((card.notes ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 18),
                    Text(card.notes!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ),
          Positioned(top: -6, right: -6, child: IconButton(icon: const Icon(Icons.volume_up_outlined), tooltip: 'Read aloud', onPressed: widget.onSpeak)),
        ],
      ),
      back: true,
    );

    // Swipe hint colour while dragging a revealed card.
    Color? hint;
    if (widget.revealed) {
      if (_dy < -30) {
        hint = Colors.blue;
      } else if (_dx > 30) {
        hint = Colors.green;
      } else if (_dx < -30) {
        hint = cs.error;
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.revealed ? null : widget.onTap,
      onPanUpdate: (DragUpdateDetails d) => setState(() {
        _dx += d.delta.dx;
        _dy += d.delta.dy;
      }),
      onPanEnd: _end,
      child: Transform.translate(
        offset: widget.revealed ? Offset(_dx * 0.5, math.min(0, _dy) * 0.5) : Offset.zero,
        child: Transform.rotate(
          angle: widget.revealed ? (_dx / 1200) : 0,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: hint?.withValues(alpha: 0.10),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: widget.revealed ? 1 : 0),
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeInOutCubic,
              builder: (BuildContext context, double v, Widget? _) {
                final bool showBack = v >= 0.5;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(math.pi * v),
                  child: showBack
                      ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: back)
                      : front,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TypedBadge extends StatelessWidget {
  const _TypedBadge({required this.result, required this.typed});
  final TypedResult result;
  final String typed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final (Color color, IconData icon, String label) = switch (result) {
      TypedResult.correct => (Colors.green, Icons.check_circle, 'Correct'),
      TypedResult.close => (Colors.orange, Icons.change_circle_outlined, 'Almost'),
      TypedResult.wrong => (cs.error, Icons.cancel_outlined, 'Not quite'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(typed.trim().isEmpty ? label : '$label · you typed “${typed.trim()}”',
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── bottom controls ──────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  const _Controls({
    required this.card,
    required this.revealed,
    required this.practice,
    required this.intervals,
    required this.typed,
    required this.typedResult,
    required this.onReveal,
    required this.onAnswer,
  });

  final FcCard card;
  final bool revealed;
  final bool practice;
  final Map<FsrsRating, Duration> intervals;
  final TextEditingController typed;
  final TypedResult? typedResult;
  final VoidCallback onReveal;
  final ValueChanged<FsrsRating> onAnswer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: revealed ? _rating(context, cs) : _reveal(context),
      ),
    );
  }

  Widget _reveal(BuildContext context) {
    if (card.type == FcCardType.typed) {
      return Row(
        key: const ValueKey<String>('typed'),
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: typed,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onReveal(),
              decoration: const InputDecoration(
                hintText: 'Type your answer',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(onPressed: onReveal, child: const Text('Check')),
        ],
      );
    }
    return SizedBox(
      key: const ValueKey<String>('reveal'),
      width: double.infinity,
      height: 52,
      child: FilledButton(onPressed: onReveal, child: const Text('Show answer')),
    );
  }

  Widget _rating(BuildContext context, ColorScheme cs) {
    final TypedResult? tr = typedResult;
    final FsrsRating? suggested = card.type == FcCardType.typed && tr != null
        ? switch (tr) {
            TypedResult.correct => FsrsRating.good,
            TypedResult.close => FsrsRating.hard,
            TypedResult.wrong => FsrsRating.again,
          }
        : null;
    Widget button(FsrsRating r, String label, Color color) {
      final Duration? d = intervals[r];
      final bool hint = suggested == r;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: color.withValues(alpha: hint ? 0.38 : 0.18),
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: hint ? BorderSide(color: color, width: 2) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => onAnswer(r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(d == null ? '' : formatInterval(d), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      key: const ValueKey<String>('rating'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            button(FsrsRating.again, 'Again', cs.error),
            button(FsrsRating.hard, 'Hard', const Color(0xFFEF6C00)),
            button(FsrsRating.good, 'Good', const Color(0xFF2E7D32)),
            button(FsrsRating.easy, 'Easy', const Color(0xFF1565C0)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Swipe the card: ← Again · → Good · ↑ Easy',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ── summary ──────────────────────────────────────────────────────────────────

class _Summary extends ConsumerWidget {
  const _Summary({required this.answers, required this.practice, required this.deckId, required this.mode});

  final List<_Answered> answers;
  final bool practice;
  final String? deckId;
  final StudyMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final int total = answers.length;
    final int again = answers.where((_Answered a) => a.rating == FsrsRating.again).length;
    final int ms = answers.fold(0, (int s, _Answered a) => s + a.ms);
    final int accuracy = total == 0 ? 0 : (((total - again) * 100) / total).round();
    final int streak = ref.watch(fcDashboardProvider).asData?.value.streak ?? 0;
    final String time = ms < 60000 ? '${(ms / 1000).round()}s' : '${(ms / 60000).round()} min';

    Widget stat(String value, String label, Color color) => Expanded(
          child: Column(
            children: <Widget>[
              Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: color)),
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (BuildContext c, double v, Widget? w) => Transform.scale(scale: v, child: w),
                  child: Icon(total == 0 ? Icons.hourglass_empty : Icons.emoji_events_rounded,
                      size: 84, color: total == 0 ? cs.outline : Colors.amber.shade700),
                ),
                const SizedBox(height: 16),
                Text(total == 0 ? 'Nothing to study right now' : (practice ? 'Practice complete' : 'Session complete'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  total == 0
                      ? 'Everything is scheduled. Come back later, or practise without changing your schedule.'
                      : 'Great job — keep the streak going.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (total > 0) ...<Widget>[
                  const SizedBox(height: 28),
                  Row(children: <Widget>[
                    stat('$total', total == 1 ? 'card' : 'cards', cs.primary),
                    stat('$accuracy%', 'remembered', Colors.green),
                    stat(time, 'time', cs.tertiary),
                  ]),
                  if (!practice && streak > 0) ...<Widget>[
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.local_fire_department_rounded, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text('$streak-day streak', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: () => Navigator.maybePop(context), child: const Text('Done'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

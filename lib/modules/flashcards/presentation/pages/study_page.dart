import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';

class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key, this.deckId, required this.mode, this.practiceMode});
  final String? deckId;
  final StudyMode mode;
  final PracticeMode? practiceMode;
  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _answer = TextEditingController();
  final math.Random _random = math.Random();
  List<Flashcard> _cards = <Flashcard>[];
  int _index = 0;
  int _reviewed = 0;
  bool _loading = true;
  bool _flipped = false;
  bool _checked = false;
  bool _showAnswer = false;
  DateTime _shownAt = DateTime.now();
  PracticeMode _mode = PracticeMode.basicReview;
  PracticeOptions _options = const PracticeOptions();
  final List<Offset> _ink = <Offset>[];
  List<_Tile> _tiles = <_Tile>[];
  final Set<int> _matched = <int>{};
  int? _firstTile;
  List<int> _matchOrder = <int>[];
  int? _termPick;
  int? _defPick;

  @override
  void initState() {
    super.initState();
    _mode = widget.practiceMode ?? PracticeMode.basicReview;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tts.stop();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final List<Flashcard> cards = await ref.read(flashcardRepositoryProvider)
        .buildStudySession(deckId: widget.deckId, mode: widget.mode);
    if (_options.difficultFirst) {
      cards.sort((Flashcard a, Flashcard b) =>
          b.difficulty.index.compareTo(a.difficulty.index));
    }
    if (_options.cardLimit > 0 && cards.length > _options.cardLimit) {
      cards.removeRange(_options.cardLimit, cards.length);
    }
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _index = 0;
      _reviewed = 0;
      _loading = false;
      _reset();
    });
    if (_currentMode == PracticeMode.audioReview && cards.isNotEmpty) {
      _speak(cards.first);
    }
  }

  PracticeMode get _currentMode {
    if (_mode != PracticeMode.combinedReview) return _mode;
    const List<PracticeMode> modes = <PracticeMode>[
      PracticeMode.basicReview,
      PracticeMode.writingReview,
      PracticeMode.multipleAnswers,
      PracticeMode.audioReview,
      PracticeMode.whiteboardReview,
    ];
    return modes[_index % modes.length];
  }

  void _reset() {
    _flipped = !_options.termFirst;
    _checked = false;
    _showAnswer = false;
    _answer.clear();
    _ink.clear();
    _matched.clear();
    _firstTile = null;
    _termPick = null;
    _defPick = null;
    if (_currentMode == PracticeMode.matchCards) {
      _matchOrder = List<int>.generate(_cards.length, (int i) => i)..shuffle(_random);
    }
    if (_currentMode == PracticeMode.memoryGame) {
      _tiles = <_Tile>[
        for (int i = 0; i < _cards.length; i++) ...<_Tile>[
          _Tile(i, _cards[i].front, true),
          _Tile(i, _cards[i].back, false),
        ],
      ]..shuffle(_random);
    }
  }

  Future<void> _rate(CardRating rating) async {
    if (_index >= _cards.length) return;
    final Flashcard card = _cards[_index];
    await ref.read(flashcardRepositoryProvider).recordReview(
      card.id, rating,
      durationMs: DateTime.now().difference(_shownAt).inMilliseconds,
    );
    if (!mounted) return;
    _reviewed++;
    _next();
  }

  void _next() {
    if (_index >= _cards.length - 1) {
      setState(() => _index = _cards.length);
      return;
    }
    setState(() {
      _index++;
      _shownAt = DateTime.now();
      _reset();
    });
    if (_currentMode == PracticeMode.audioReview) _speak(_cards[_index]);
  }

  Future<void> _speak(Flashcard card) async {
    await _tts.setSpeechRate(0.45);
    await _tts.speak(_options.termFirst ? card.front : card.back);
  }

  Future<void> _pickMode() async {
    final PracticeMode? value = await showModalBottomSheet<PracticeMode>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            const ListTile(title: Text('Practice mode')),
            for (final PracticeMode mode in PracticeMode.values)
              ListTile(
                leading: Icon(_icon(mode)),
                title: Text(mode.label),
                subtitle: Text(mode.description),
                trailing: mode == _currentMode ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, mode),
              ),
          ],
        ),
      ),
    );
    if (value == null || !mounted) return;
    setState(() {
      _mode = value;
      _reset();
    });
  }

  Future<void> _optionsSheet() async {
    PracticeOptions draft = _options;
    final PracticeOptions? value = await showModalBottomSheet<PracticeOptions>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text('Study options', style: Theme.of(context).textTheme.headlineSmall),
              SwitchListTile(
                title: const Text('Difficult cards first'),
                value: draft.difficultFirst,
                onChanged: (bool v) => setSheet(() => draft = PracticeOptions(
                  difficultFirst: v, termFirst: draft.termFirst,
                  writeTerm: draft.writeTerm, cardLimit: draft.cardLimit,
                )),
              ),
              SwitchListTile(
                title: const Text('Term first'),
                value: draft.termFirst,
                onChanged: (bool v) => setSheet(() => draft = PracticeOptions(
                  difficultFirst: draft.difficultFirst, termFirst: v,
                  writeTerm: draft.writeTerm, cardLimit: draft.cardLimit,
                )),
              ),
              SwitchListTile(
                title: const Text('Write term'),
                value: draft.writeTerm,
                onChanged: (bool v) => setSheet(() => draft = PracticeOptions(
                  difficultFirst: draft.difficultFirst, termFirst: draft.termFirst,
                  writeTerm: v, cardLimit: draft.cardLimit,
                )),
              ),
              DropdownButtonFormField<int>(
                value: draft.cardLimit,
                decoration: const InputDecoration(labelText: 'Cards to practice'),
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 20, child: Text('20')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                  DropdownMenuItem(value: 100, child: Text('100')),
                  DropdownMenuItem(value: 0, child: Text('All')),
                ],
                onChanged: (int? v) => setSheet(() => draft = PracticeOptions(
                  difficultFirst: draft.difficultFirst, termFirst: draft.termFirst,
                  writeTerm: draft.writeTerm, cardLimit: v ?? draft.cardLimit,
                )),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context, draft),
                child: const SizedBox(width: double.infinity, child: Center(child: Text('Apply'))),
              ),
            ]),
          ),
        ),
      ),
    );
    if (value == null || !mounted) return;
    setState(() {
      _options = value;
      _loading = true;
    });
    await _load();
  }

  IconData _icon(PracticeMode mode) => switch (mode) {
    PracticeMode.basicReview => Icons.style_outlined,
    PracticeMode.multipleAnswers => Icons.checklist,
    PracticeMode.matchCards => Icons.compare_arrows,
    PracticeMode.writingReview => Icons.edit_note,
    PracticeMode.audioReview => Icons.volume_up_outlined,
    PracticeMode.whiteboardReview => Icons.draw_outlined,
    PracticeMode.memoryGame => Icons.grid_view_rounded,
    PracticeMode.combinedReview => Icons.shuffle,
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_cards.isEmpty) return Scaffold(
      appBar: AppBar(title: Text(_currentMode.label)),
      body: const Center(child: Text('No cards to study here.')),
    );
    if (_index >= _cards.length) return _summary(theme);
    final Flashcard card = _cards[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text((_index + 1).toString() + ' / ' + _cards.length.toString()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_index + 1) / _cards.length),
        ),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.tune), onPressed: _pickMode),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: _optionsSheet),
          IconButton(
            icon: Icon(card.bookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () async {
              await ref.read(flashcardRepositoryProvider)
                  .setBookmarked(card.id, !card.bookmarked);
              setState(() => _cards[_index] =
                  card.copyWith(bookmarked: !card.bookmarked));
            },
          ),
        ],
      ),
      body: _body(theme, card),
    );
  }

  Widget _body(ThemeData theme, Flashcard card) {
    switch (_currentMode) {
      case PracticeMode.basicReview:
        return _basic(theme, card);
      case PracticeMode.audioReview:
        return _basic(theme, card, audio: true);
      case PracticeMode.writingReview:
        return _writing(theme, card, false);
      case PracticeMode.multipleAnswers:
        return _writing(theme, card, true);
      case PracticeMode.matchCards:
        return _match(theme);
      case PracticeMode.whiteboardReview:
        return _whiteboard(theme, card);
      case PracticeMode.memoryGame:
        return _memory(theme);
      case PracticeMode.combinedReview:
        return _basic(theme, card);
    }
  }

  Widget _basic(ThemeData theme, Flashcard card, {bool audio = false}) => Column(
    children: <Widget>[
      if (audio) FilledButton.tonalIcon(
        onPressed: () => _speak(card),
        icon: const Icon(Icons.volume_up),
        label: const Text('Play audio'),
      ),
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _flipped = !_flipped),
          onHorizontalDragEnd: (DragEndDetails d) {
            final double v = d.primaryVelocity ?? 0;
            if (v < -200) _next();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _face(theme, card, _flipped),
            ),
          ),
        ),
      ),
      if (_flipped) _ratings(theme)
      else Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: FilledButton(
          onPressed: () => setState(() => _flipped = true),
          child: const SizedBox(width: double.infinity, child: Center(child: Text('Show answer'))),
        ),
      ),
    ],
  );

  Widget _writing(ThemeData theme, Flashcard card, bool multiple) {
    final bool askTerm = _options.writeTerm;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Chip(label: Text(multiple ? 'Multiple Answers' : 'Writing Review')),
        const SizedBox(height: 12),
        _prompt(theme, askTerm ? 'DEFINITION' : 'TERM', askTerm ? card.back : card.front),
        const SizedBox(height: 12),
        TextField(
          controller: _answer,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: askTerm ? 'Write the term' : 'Write the answer',
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() => _checked = false),
        ),
        const SizedBox(height: 12),
        if (!_checked) FilledButton(
          onPressed: () => setState(() => _checked = true),
          child: const Text('Check answer'),
        ) else ...<Widget>[
          Text(_answerMatches(card) ? 'Correct' : 'Compare your answer'),
          const SizedBox(height: 10),
          _prompt(theme, 'ANSWER', card.back),
          _ratings(theme),
        ],
      ],
    );
  }

  bool _answerMatches(Flashcard card) {
    final String typed = _answer.text.trim().toLowerCase();
    final List<String> accepted = card.back.split(RegExp(r'[\n|;]+'))
      .map((String s) => s.trim().toLowerCase())
      .where((String s) => s.isNotEmpty).toList();
    return typed.isNotEmpty && accepted.any((String s) => typed == s);
  }

  Widget _match(ThemeData theme) => ListView(
    padding: const EdgeInsets.all(16),
    children: <Widget>[
      const Chip(label: Text('Match Cards')),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Expanded(child: _matchColumn(theme, List<int>.generate(_cards.length, (int i) => i), true)),
        const SizedBox(width: 8),
        Expanded(child: _matchColumn(theme, _matchOrder, false)),
      ]),
      Text(_matched.length.toString() + ' / ' + _cards.length.toString() + ' matched', textAlign: TextAlign.center),
      if (_matched.length == _cards.length)
        FilledButton(onPressed: () => _rate(CardRating.good), child: const Text('Finish · Good')),
    ],
  );

  Widget _matchColumn(ThemeData theme, List<int> ids, bool term) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text(term ? 'Terms' : 'Definitions', style: theme.textTheme.titleMedium),
      for (final int id in ids)
        if (!_matched.contains(id)) Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: OutlinedButton(
            onPressed: () => setState(() {
              if (term) _termPick = id; else _defPick = id;
              if (_termPick != null && _defPick != null) {
                if (_termPick == _defPick) _matched.add(id);
                _termPick = null;
                _defPick = null;
              }
            }),
            child: Text(term ? _cards[id].front : _cards[id].back),
          ),
        ),
    ],
  );

  Widget _whiteboard(ThemeData theme, Flashcard card) => Column(
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.all(16),
        child: _prompt(theme, _options.termFirst ? 'TERM' : 'DEFINITION',
            _options.termFirst ? card.front : card.back),
      ),
      Expanded(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(20),
          ),
          child: GestureDetector(
            onPanStart: (DragStartDetails d) => setState(() => _ink.add(d.localPosition)),
            onPanUpdate: (DragUpdateDetails d) => setState(() => _ink.add(d.localPosition)),
            onPanEnd: (_) => setState(() => _ink.add(Offset.infinite)),
            child: CustomPaint(painter: _Painter(_ink), child: const SizedBox.expand()),
          ),
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        TextButton.icon(onPressed: () => setState(_ink.clear), icon: const Icon(Icons.delete_outline), label: const Text('Clear')),
        TextButton.icon(onPressed: () => setState(() => _showAnswer = true), icon: const Icon(Icons.visibility_outlined), label: const Text('Show answer')),
      ]),
      if (_showAnswer) _prompt(theme, 'ANSWER', card.back),
      if (_showAnswer) _ratings(theme),
    ],
  );

  Widget _memory(ThemeData theme) {
    final bool done = _matched.length == _tiles.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Chip(label: Text('Memory Game')),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tiles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
          ),
          itemBuilder: (BuildContext context, int i) {
            final bool visible = _matched.contains(i) || _firstTile == i;
            return Card(
              child: InkWell(
                onTap: () => _tapMemory(i),
                child: Center(child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(visible ? _tiles[i].text : '✦', textAlign: TextAlign.center),
                )),
              ),
            );
          },
        ),
        if (done) FilledButton(onPressed: () => _rate(CardRating.good), child: const Text('Finish · Good')),
      ],
    );
  }

  void _tapMemory(int index) {
    if (_matched.contains(index) || _firstTile == index) return;
    setState(() {
      if (_firstTile == null) {
        _firstTile = index;
      } else {
        final int first = _firstTile!;
        if (_tiles[first].pair == _tiles[index].pair &&
            _tiles[first].isTerm != _tiles[index].isTerm) {
          _matched.addAll(<int>[first, index]);
        }
        _firstTile = null;
      }
    });
  }

  Widget _prompt(ThemeData theme, String label, String text) => Card(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: <Widget>[
        Text(label),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
      ]),
    ),
  );

  Widget _face(ThemeData theme, Flashcard card, bool back) => Card(
    key: ValueKey<bool>(back),
    color: back ? theme.colorScheme.surfaceContainerHighest : null,
    child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Text(back ? 'ANSWER' : 'QUESTION'),
        const SizedBox(height: 12),
        Text(back ? card.back : card.front, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        if (back && card.notes != null && card.notes!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12), Text(card.notes!),
        ],
      ]),
    )),
  );

  Widget _ratings(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
    child: Row(children: <Widget>[
      _rateButton('Again', CardRating.again, theme.colorScheme.error),
      _rateButton('Hard', CardRating.hard, theme.colorScheme.tertiary),
      _rateButton('Good', CardRating.good, theme.colorScheme.primary),
      _rateButton('Easy', CardRating.easy, theme.colorScheme.secondary),
    ]),
  );

  Widget _rateButton(String label, CardRating rating, Color color) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: FilledButton.tonal(
        onPressed: () => _rate(rating),
        style: FilledButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withValues(alpha: 0.18),
        ),
        child: Text(label),
      ),
    ),
  );

  Widget _summary(ThemeData theme) => Scaffold(
    appBar: AppBar(title: const Text('Session complete')),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Icon(Icons.celebration_outlined, size: 64, color: theme.colorScheme.primary),
      const SizedBox(height: 16),
      Text('Reviewed ' + _reviewed.toString() + (_reviewed == 1 ? ' card' : ' cards')),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: () { setState(() => _loading = true); _load(); },
        icon: const Icon(Icons.replay),
        label: const Text('Study again'),
      ),
    ])),
  );
}

class _Tile {
  const _Tile(this.pair, this.text, this.isTerm);
  final int pair;
  final String text;
  final bool isTerm;
}

class _Painter extends CustomPainter {
  const _Painter(this.points);
  final List<Offset> points;
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..strokeWidth = 3..strokeCap = StrokeCap.round;
    for (int i = 1; i < points.length; i++) {
      if (points[i - 1].isInfinite || points[i].isInfinite) continue;
      canvas.drawLine(points[i - 1], points[i], paint);
    }
  }
  @override
  bool shouldRepaint(covariant _Painter oldDelegate) => oldDelegate.points != points;
}

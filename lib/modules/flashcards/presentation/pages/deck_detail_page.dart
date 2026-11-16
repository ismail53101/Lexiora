import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_query.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/fc_repository.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/card_editor_page.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_sheets.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/deck_tile.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';

/// One deck: its counts, a Study button and a searchable card browser.
class DeckDetailPage extends ConsumerStatefulWidget {
  const DeckDetailPage({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<DeckDetailPage> createState() => _DeckDetailPageState();
}

class _DeckDetailPageState extends ConsumerState<DeckDetailPage> {
  static const int _pageSize = 40;

  final ScrollController _scroll = ScrollController();
  Timer? _debounce;
  String _text = '';
  FcStatusFilter _status = FcStatusFilter.all;
  FcSort _sort = FcSort.recent;
  List<FcCard> _cards = <FcCard>[];
  bool _hasMore = true;
  bool _loading = false;
  bool _loaded = false;
  final Set<String> _selected = <String>{};

  bool get _selecting => _selected.isNotEmpty;

  FcCardQuery _query({int limit = _pageSize, int offset = 0}) => FcCardQuery(
        deckId: widget.deckId,
        text: _text,
        status: _status,
        sort: _sort,
        limit: limit,
        offset: offset,
      );

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
    });
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final int limit = _cards.length > _pageSize ? _cards.length : _pageSize;
    final List<FcCard> rows = await ref.read(fcRepositoryProvider).browse(_query(limit: limit));
    if (!mounted) return;
    setState(() {
      _cards = rows;
      _hasMore = rows.length >= limit;
      _loaded = true;
      _selected.removeWhere((String id) => !rows.any((FcCard c) => c.id == id));
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    final List<FcCard> rows =
        await ref.read(fcRepositoryProvider).browse(_query(offset: _cards.length));
    if (!mounted) return;
    setState(() {
      _cards = <FcCard>[..._cards, ...rows];
      _hasMore = rows.length >= _pageSize;
      _loading = false;
    });
  }

  void _refilter() {
    _cards = <FcCard>[];
    _hasMore = true;
    _loaded = false;
    _reload();
  }

  void _toggle(String id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
      });

  Future<void> _bulk(Future<void> Function(FcRepository repo, List<String> ids) action, {String? done}) async {
    final List<String> ids = _selected.toList();
    await action(ref.read(fcRepositoryProvider), ids);
    if (!mounted) return;
    setState(_selected.clear);
    if (done != null) fcToast(context, done);
  }

  Future<void> _move() async {
    final List<FcDeckSummary> decks = ref.read(fcDecksProvider).asData?.value ?? const <FcDeckSummary>[];
    final FcDeck? target = await showDialog<FcDeck>(
      context: context,
      builder: (BuildContext c) => SimpleDialog(
        title: const Text('Move to deck'),
        children: <Widget>[
          for (final FcDeckSummary s in decks.where((FcDeckSummary s) => s.deck.id != widget.deckId))
            SimpleDialogOption(onPressed: () => Navigator.pop(c, s.deck), child: Text(s.deck.name)),
          if (decks.length < 2)
            const Padding(padding: EdgeInsets.all(16), child: Text('Create another deck first.')),
        ],
      ),
    );
    if (target == null) return;
    await _bulk((FcRepository r, List<String> ids) => r.moveCards(ids, target.id),
        done: 'Moved to ${target.name}');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<int>>(fcRevisionProvider, (AsyncValue<int>? _, AsyncValue<int> __) => _reload());
    final AsyncValue<FcDeckSummary?> async = ref.watch(fcDeckProvider(widget.deckId));
    final FcDeckSummary? summary = async.asData?.value;
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    if (async.hasValue && summary == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.search_off, title: 'This deck no longer exists'),
      );
    }

    return Scaffold(
      appBar: _selecting
          ? AppBar(
              leading: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(_selected.clear)),
              title: Text('${_selected.length} selected'),
              actions: <Widget>[
                IconButton(
                  tooltip: 'Select all loaded',
                  icon: const Icon(Icons.select_all),
                  onPressed: () => setState(() => _selected.addAll(_cards.map((FcCard c) => c.id))),
                ),
                IconButton(
                  tooltip: 'Suspend',
                  icon: const Icon(Icons.pause_circle_outline),
                  onPressed: () => _bulk((FcRepository r, List<String> ids) async {
                    for (final String id in ids) {
                      await r.setSuspended(id, true);
                    }
                  }, done: 'Suspended'),
                ),
                IconButton(
                  tooltip: 'Unsuspend',
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () => _bulk((FcRepository r, List<String> ids) async {
                    for (final String id in ids) {
                      await r.setSuspended(id, false);
                    }
                  }, done: 'Unsuspended'),
                ),
                IconButton(tooltip: 'Move', icon: const Icon(Icons.drive_file_move_outline), onPressed: _move),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final bool ok = await fcConfirm(
                      context,
                      title: 'Delete ${_selected.length} cards?',
                      message: 'Their review history is deleted too. This can’t be undone.',
                    );
                    if (ok) await _bulk((FcRepository r, List<String> ids) => r.deleteCards(ids), done: 'Deleted');
                  },
                ),
              ],
            )
          : AppBar(
              title: Text(summary?.deck.name ?? ''),
              actions: <Widget>[
                IconButton(
                  tooltip: 'Study settings',
                  icon: const Icon(Icons.tune),
                  onPressed: () => showDeckSettings(context, widget.deckId),
                ),
                if (summary != null)
                  IconButton(
                    tooltip: 'More',
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => showDeckActions(context, ref, summary),
                  ),
              ],
            ),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openCardEditor(context, deckId: widget.deckId),
              icon: const Icon(Icons.add),
              label: const Text('Add card'),
            ),
      body: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: 1 + (_cards.isEmpty ? 1 : _cards.length) + (_hasMore && _cards.isNotEmpty ? 1 : 0),
        itemBuilder: (BuildContext context, int i) {
          if (i == 0) return _header(summary, theme, cs);
          if (_cards.isEmpty) return _empty();
          final int idx = i - 1;
          if (idx >= _cards.length) {
            return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
          }
          final FcCard c = _cards[idx];
          return FcCardTile(
            card: c,
            selected: _selected.contains(c.id),
            selectionMode: _selecting,
            onTap: () => _selecting ? _toggle(c.id) : openCardEditor(context, deckId: widget.deckId, cardId: c.id),
            onLongPress: () => _toggle(c.id),
            onToggleStar: _selecting ? null : () => ref.read(fcRepositoryProvider).setStarred(c.id, !c.bookmarked),
          );
        },
      ),
    );
  }

  Widget _empty() {
    if (!_loaded) return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
    final bool filtered = _text.isNotEmpty || _status != FcStatusFilter.all;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: EmptyState(
        icon: filtered ? Icons.search_off : Icons.add_card_outlined,
        title: filtered ? 'No cards match' : 'This deck is empty',
        message: filtered ? 'Try a different search or filter.' : 'Add your first card to start learning.',
        action: filtered
            ? null
            : Wrap(
                spacing: 12,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () => openCardEditor(context, deckId: widget.deckId),
                    icon: const Icon(Icons.add),
                    label: const Text('Add card'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.flashcardsImport),
                    child: const Text('Import'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _header(FcDeckSummary? s, ThemeData theme, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (s != null)
          FcSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if ((s.deck.description ?? '').isNotEmpty) ...<Widget>[
                  Text(s.deck.description!, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    FcCountChip(label: 'new', value: s.newCount, color: cs.fcNew),
                    FcCountChip(label: 'learning', value: s.learningCount, color: cs.fcLearning),
                    FcCountChip(label: 'due', value: s.reviewCount, color: cs.fcReview),
                    Text('${s.total} cards${s.suspendedCount > 0 ? ' · ${s.suspendedCount} suspended' : ''}',
                        style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: s.dueTotal == 0 ? null : () => context.push(fcStudyLocation(deckId: s.deck.id)),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(s.dueTotal == 0 ? 'Nothing due' : 'Study ${s.dueTotal}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: s.total == 0 ? null : () => context.push(fcStudyLocation(deckId: s.deck.id, mode: StudyMode.cram)),
                      icon: const Icon(Icons.fitness_center, size: 18),
                      label: const Text('Practice'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: SearchBar(
            hintText: 'Search this deck',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll<double>(0),
            trailing: <Widget>[
              PopupMenuButton<FcSort>(
                tooltip: 'Sort',
                icon: const Icon(Icons.sort),
                initialValue: _sort,
                onSelected: (FcSort v) {
                  _sort = v;
                  _refilter();
                },
                itemBuilder: (BuildContext c) => <PopupMenuEntry<FcSort>>[
                  for (final FcSort s in FcSort.values) PopupMenuItem<FcSort>(value: s, child: Text(s.label)),
                ],
              ),
            ],
            onChanged: (String v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 250), () {
                _text = v;
                _refilter();
              });
            },
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: <Widget>[
              for (final FcStatusFilter f in FcStatusFilter.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: FilterChip(
                    label: Text(f.label),
                    selected: _status == f,
                    onSelected: (_) {
                      _status = f;
                      _refilter();
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

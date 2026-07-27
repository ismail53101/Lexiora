import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/flashcard_tile.dart';

/// A lazily-paginated card list (handles 100k+ via LIMIT/OFFSET). Reloads on
/// filter change and whenever [fcRevisionProvider] bumps (after edits).
class PaginatedCards extends ConsumerStatefulWidget {
  const PaginatedCards({super.key, required this.filter, this.padding});

  final FlashcardFilter filter;
  final EdgeInsetsGeometry? padding;

  @override
  ConsumerState<PaginatedCards> createState() => _PaginatedCardsState();
}

class _PaginatedCardsState extends ConsumerState<PaginatedCards> {
  static const int _pageSize = 40;
  final ScrollController _scroll = ScrollController();
  final List<Flashcard> _items = <Flashcard>[];
  int _offset = 0;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void didUpdateWidget(PaginatedCards old) {
    super.didUpdateWidget(old);
    if (old.filter != widget.filter) _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!reset && !_hasMore)) return;
    _loading = true;
    if (reset) {
      _offset = 0;
      _hasMore = true;
    }
    final List<Flashcard> page = await ref
        .read(flashcardRepositoryProvider)
        .cards(widget.filter, limit: _pageSize, offset: _offset);
    if (!mounted) return;
    setState(() {
      if (reset) _items.clear();
      _items.addAll(page);
      _offset += page.length;
      _hasMore = page.length == _pageSize;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(fcRevisionProvider, (_, _) => _load(reset: true));
    final Map<String, int> colors = ref.watch(fcSubjectColorsProvider).maybeWhen(
          data: (Map<String, int> m) => m,
          orElse: () => const <String, int>{},
        );

    if (_items.isEmpty && !_loading) {
      return const EmptyState(
        icon: Icons.style_outlined,
        title: 'No cards',
        message: 'Add a card, or adjust your search and filters.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 6),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (BuildContext context, int i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return FlashcardTile(card: _items[i], colors: colors);
        },
      ),
    );
  }
}

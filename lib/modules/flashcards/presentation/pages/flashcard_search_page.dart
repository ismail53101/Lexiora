import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/paginated_cards.dart';

/// Search & filter across all cards (deck/subject/topic/text/tag + flags).
class FlashcardSearchPage extends ConsumerStatefulWidget {
  const FlashcardSearchPage({super.key});

  @override
  ConsumerState<FlashcardSearchPage> createState() => _FlashcardSearchPageState();
}

class _FlashcardSearchPageState extends ConsumerState<FlashcardSearchPage> {
  final TextEditingController _field = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(flashcardFilterProvider.notifier).reset());
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  FlashcardFilterNotifier get _n => ref.read(flashcardFilterProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final FlashcardFilter f = ref.watch(flashcardFilterProvider);
    final List<String> subjects = ref.watch(fcSubjectSuggestionsProvider).maybeWhen(
          data: (List<String> s) => s,
          orElse: () => const <String>[],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Search & Filter')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _field,
              onChanged: _n.setQuery,
              decoration: InputDecoration(
                hintText: 'Search front, back, subject, tags…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: f.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _field.clear();
                          _n.setQuery('');
                        }),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                _menuChip<CardStatusFilter>(
                  label: 'Status',
                  value: f.status,
                  isDefault: f.status == CardStatusFilter.all,
                  options: CardStatusFilter.values,
                  labelOf: (CardStatusFilter v) => v.label,
                  onSelected: (CardStatusFilter v) => _n.set(f.copyWith(status: v)),
                ),
                _menuChip<CardSort>(
                  label: 'Sort',
                  value: f.sort,
                  isDefault: f.sort == CardSort.recent,
                  options: CardSort.values,
                  labelOf: (CardSort v) => v.label,
                  onSelected: (CardSort v) => _n.set(f.copyWith(sort: v)),
                ),
                _stringChip(
                  label: 'Subject',
                  value: f.subject,
                  options: subjects,
                  onSelected: (String? v) =>
                      _n.set(f.copyWith(subject: v, clearSubject: v == null)),
                ),
                _difficultyChip(f),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Bookmarked'),
                    selected: f.onlyBookmarked,
                    onSelected: (bool v) => _n.set(f.copyWith(onlyBookmarked: v)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Favourite'),
                    selected: f.onlyFavorite,
                    onSelected: (bool v) => _n.set(f.copyWith(onlyFavorite: v)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: PaginatedCards(filter: f)),
        ],
      ),
    );
  }

  Widget _difficultyChip(FlashcardFilter f) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<CardDifficulty?>(
        onSelected: (CardDifficulty? d) =>
            _n.set(f.copyWith(difficulty: d, clearDifficulty: d == null)),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<CardDifficulty?>>[
          const PopupMenuItem<CardDifficulty?>(child: Text('Any')),
          for (final CardDifficulty d in CardDifficulty.values)
            PopupMenuItem<CardDifficulty?>(value: d, child: Text(d.label)),
        ],
        child: Chip(
          label: Text(f.difficulty == null ? 'Difficulty' : f.difficulty!.label),
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
          backgroundColor: f.difficulty == null
              ? null
              : Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }

  Widget _menuChip<T>({
    required String label,
    required T value,
    required bool isDefault,
    required List<T> options,
    required String Function(T) labelOf,
    required ValueChanged<T> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<T>(
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<T>>[
          for (final T o in options)
            PopupMenuItem<T>(value: o, child: Text(labelOf(o))),
        ],
        child: Chip(
          label: Text(isDefault ? label : '$label: ${labelOf(value)}'),
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
          backgroundColor: isDefault
              ? null
              : Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }

  Widget _stringChip({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        onSelected: (String v) => onSelected(v.isEmpty ? null : v),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: '', child: Text('Any')),
          for (final String o in options)
            PopupMenuItem<String>(value: o, child: Text(o)),
        ],
        child: Chip(
          label: Text(value == null ? label : '$label: $value'),
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
          backgroundColor: value == null
              ? null
              : Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }
}

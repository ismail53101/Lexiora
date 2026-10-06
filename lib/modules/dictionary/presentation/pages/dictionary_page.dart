import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/core/widgets/error_view.dart';
import 'package:lexiora/modules/dictionary/data/dictionary_seeder.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/presentation/controllers/dictionary_search_controller.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';
import 'package:lexiora/modules/dictionary/presentation/widgets/dictionary_attribution.dart';
import 'package:lexiora/modules/dictionary/presentation/widgets/dictionary_result_tile.dart';

/// The offline Dictionary screen: a search bar with instant, debounced search,
/// and idle / loading / no-result / results states. When the search box is
/// empty it shows the user's saved words. First-run seeding is surfaced as a
/// one-time progress state.
class DictionaryPage extends ConsumerStatefulWidget {
  const DictionaryPage({super.key});

  @override
  ConsumerState<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends ConsumerState<DictionaryPage> {
  final TextEditingController _field = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dictionarySearchControllerProvider.notifier).reset();
      // Kick off the one-time first-run seed; UI observes seeder.status.
      ref.read(dictionarySeederProvider).ensureSeeded();
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _field.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      ref.read(dictionarySearchControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final DictionarySeeder seeder = ref.watch(dictionarySeederProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictionary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About this dictionary',
            onPressed: () => showDictionaryAttribution(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchField(
            controller: _field,
            onChanged: (String v) => ref
                .read(dictionarySearchControllerProvider.notifier)
                .onQueryChanged(v),
            onClear: () {
              _field.clear();
              ref
                  .read(dictionarySearchControllerProvider.notifier)
                  .onQueryChanged('');
            },
          ),
          // Permanent in-page banner: sits right under the search box so it
          // stays visible (also with the keyboard open) while results scroll.
          ManagedBannerAd(
            manager: sl<RewardedAdManager>(),
            placementName: 'dictionary',
          ),
          Expanded(
            child: ValueListenableBuilder<DictionarySeedStatus>(
              valueListenable: seeder.status,
              builder: (BuildContext context, DictionarySeedStatus seed, _) {
                if (seed.isSeeding) return _SeedingView(status: seed);
                if (seed.isError) {
                  return ErrorView(
                    title: 'Dictionary unavailable',
                    message: 'The offline dictionary could not be prepared.',
                    onRetry: () =>
                        ref.read(dictionarySeederProvider).ensureSeeded(),
                  );
                }
                return _buildBody();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final DictionarySearchState state =
        ref.watch(dictionarySearchControllerProvider);

    switch (state.status) {
      case DictionarySearchStatus.idle:
        return _IdleFavorites(onOpenWord: _openWord);
      case DictionarySearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case DictionarySearchStatus.error:
        return ErrorView(
          title: 'Search failed',
          message: 'Something went wrong while searching. Please try again.',
          onRetry: () => ref
              .read(dictionarySearchControllerProvider.notifier)
              .onQueryChanged(state.query),
        );
      case DictionarySearchStatus.empty:
        return _NoLocalResult(
          query: state.query,
          onAskAi: () => _openAiWord(state.query),
        );
      case DictionarySearchStatus.ready:
        return _ResultsList(
          state: state,
          scroll: _scroll,
          onOpenWord: _openWord,
        );
    }
  }

  void _openWord(DictionaryResult r) =>
      context.push(AppRoutes.dictionaryWord(r.wordLower));

  void _openAiWord(String query) =>
      context.push(AppRoutes.dictionaryWord(query.trim().toLowerCase()));
}

/// A missing local word is not a dead end: opening it invokes the Dictionary's
/// AI fallback directly on the details page. This is deliberately a button,
/// rather than an automatic request for every typo, so token usage stays low.
class _NoLocalResult extends StatelessWidget {
  const _NoLocalResult({required this.query, required this.onAskAi});

  final String query;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.auto_awesome,
                size: 54, color: theme.colorScheme.primary),
            const SizedBox(height: 18),
            Text('Not in offline dictionary',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '“$query” is not in the local word list. Ask Lexiora AI for its meaning, Urdu translation, synonyms, antonyms, and example.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAskAi,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Ask AI for this word'),
            ),
            const SizedBox(height: 10),
            Text('Requires internet. Your offline dictionary remains unchanged.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search the dictionary',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (BuildContext context, TextEditingValue value, _) =>
                value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear',
                        onPressed: onClear,
                      ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.state,
    required this.scroll,
    required this.onOpenWord,
  });

  final DictionarySearchState state;
  final ScrollController scroll;
  final ValueChanged<DictionaryResult> onOpenWord;

  @override
  Widget build(BuildContext context) {
    final int extra = state.hasMore || state.loadingMore ? 1 : 0;
    return ListView.separated(
      controller: scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: state.results.length + extra,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int i) {
        if (i >= state.results.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final DictionaryResult r = state.results[i];
        return DictionaryResultTile(result: r, onTap: () => onOpenWord(r));
      },
    );
  }
}

/// Idle state (empty search box): shows Recent searches and Saved words, or a
/// prompt when there is neither.
class _IdleFavorites extends ConsumerWidget {
  const _IdleFavorites({required this.onOpenWord});

  final ValueChanged<DictionaryResult> onOpenWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DictionaryResult> favs = ref.watch(favoritesProvider).maybeWhen(
          data: (List<DictionaryResult> f) => f,
          orElse: () => const <DictionaryResult>[],
        );
    final List<String> recent = ref.watch(recentSearchesProvider).maybeWhen(
          data: (List<String> r) => r,
          orElse: () => const <String>[],
        );
    if (favs.isEmpty && recent.isEmpty) return const _SearchPrompt();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: <Widget>[
        if (recent.isNotEmpty) _RecentSearches(words: recent),
        if (favs.isNotEmpty) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: <Widget>[
                const Icon(Icons.bookmark, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Saved words',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          for (final DictionaryResult r in favs)
            DictionaryResultTile(result: r, onTap: () => onOpenWord(r)),
        ],
      ],
    );
  }
}

/// Recent-searches chips with a Clear action.
class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.history,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Recent',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    ref.read(dictionaryRepositoryProvider).clearSearchHistory(),
                child: const Text('Clear'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String w in words)
                  ActionChip(
                    label: Text(w),
                    onPressed: () =>
                        context.push(AppRoutes.dictionaryWord(w.toLowerCase())),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.menu_book_outlined,
      title: 'Search the dictionary',
      message: 'Start typing to look up definitions, parts of speech and '
          'examples — all offline. Words you save appear here.',
    );
  }
}

class _SeedingView extends StatelessWidget {
  const _SeedingView({required this.status});

  final DictionarySeedStatus status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              child: LinearProgressIndicator(
                value: status.progress > 0 ? status.progress : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Preparing the dictionary',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'This happens once. Loading the offline word database'
              '${status.progress > 0 ? ' (${(status.progress * 100).round()}%)' : ''}…',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
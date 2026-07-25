import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/dictionary_usecases.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';

/// Lifecycle of the search box.
enum DictionarySearchStatus { idle, loading, ready, empty, error }

/// Immutable state for the dictionary search screen.
class DictionarySearchState extends Equatable {
  const DictionarySearchState({
    this.query = '',
    this.results = const <DictionaryResult>[],
    this.status = DictionarySearchStatus.idle,
    this.hasMore = false,
    this.loadingMore = false,
  });

  final String query;
  final List<DictionaryResult> results;
  final DictionarySearchStatus status;
  final bool hasMore;
  final bool loadingMore;

  DictionarySearchState copyWith({
    String? query,
    List<DictionaryResult>? results,
    DictionarySearchStatus? status,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      DictionarySearchState(
        query: query ?? this.query,
        results: results ?? this.results,
        status: status ?? this.status,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );

  @override
  List<Object?> get props => [query, results, status, hasMore, loadingMore];
}

/// Controller powering instant, debounced, paged dictionary search.
///
/// Typing updates the query and (after a short debounce) runs a search; a
/// monotonically increasing sequence number discards stale responses so the
/// list never flickers to an out-of-order result. Scrolling near the end calls
/// [loadMore] for the next page.
class DictionarySearchController extends Notifier<DictionarySearchState> {
  /// Page size for search results. Must match [SearchParams]'s default `limit`
  /// (both 50), which is why the search calls below don't pass `limit`.
  static const int _pageSize = 50;
  static const Duration _debounceDelay = Duration(milliseconds: 180);

  Timer? _debounce;
  int _seq = 0;

  @override
  DictionarySearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const DictionarySearchState();
  }

  /// Clears state — called when the search screen is (re)opened.
  void reset() {
    _debounce?.cancel();
    _seq++;
    state = const DictionarySearchState();
  }

  /// Handles each keystroke: debounces, then searches.
  void onQueryChanged(String raw) {
    final String q = raw.trim();
    _debounce?.cancel();
    if (q.isEmpty) {
      _seq++;
      state = const DictionarySearchState();
      return;
    }
    // Reflect the pending query immediately so the UI feels responsive.
    state = state.copyWith(query: q, status: DictionarySearchStatus.loading);
    _debounce = Timer(_debounceDelay, () => _search(q));
  }

  Future<void> _search(String q) async {
    final int seq = ++_seq;
    // First-run: make sure the dictionary is loaded before querying.
    try {
      await ref.read(dictionarySeederProvider).ensureSeeded();
    } on Object {
      // Seed errors surface via the seeder's own status; treat search as empty.
    }
    if (seq != _seq) return;

    final result =
        await ref.read(searchDictionaryProvider).call(SearchParams(q));
    if (seq != _seq) return;

    state = result.fold(
      (_) => state.copyWith(
        status: DictionarySearchStatus.error,
        results: const <DictionaryResult>[],
        hasMore: false,
        loadingMore: false,
      ),
      (List<DictionaryResult> list) => state.copyWith(
        query: q,
        results: list,
        status: list.isEmpty
            ? DictionarySearchStatus.empty
            : DictionarySearchStatus.ready,
        hasMore: list.length >= _pageSize,
        loadingMore: false,
      ),
    );
  }

  /// Loads the next page of results for the current query.
  Future<void> loadMore() async {
    final DictionarySearchState s = state;
    if (!s.hasMore ||
        s.loadingMore ||
        s.status != DictionarySearchStatus.ready) {
      return;
    }
    state = s.copyWith(loadingMore: true);
    final int seq = _seq;
    final result = await ref.read(searchDictionaryProvider).call(
          SearchParams(s.query, offset: s.results.length),
        );
    if (seq != _seq) return;

    state = result.fold(
      (_) => state.copyWith(loadingMore: false, hasMore: false),
      (List<DictionaryResult> more) => state.copyWith(
        results: <DictionaryResult>[...state.results, ...more],
        hasMore: more.length >= _pageSize,
        loadingMore: false,
      ),
    );
  }
}

final NotifierProvider<DictionarySearchController, DictionarySearchState>
    dictionarySearchControllerProvider =
    NotifierProvider<DictionarySearchController, DictionarySearchState>(
  DictionarySearchController.new,
);

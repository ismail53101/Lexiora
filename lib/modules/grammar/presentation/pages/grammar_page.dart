import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_topic.dart';
import 'package:lexiora/modules/grammar/presentation/providers/grammar_providers.dart';
import 'package:lexiora/modules/grammar/presentation/widgets/grammar_topic_tile.dart';

/// Grammar home: a learning-app style list of categories. Tapping a category
/// drills into its subtopics (Category → Subcategory → Lesson). Also offers
/// search across lessons and a "Continue learning" shortcut.
class GrammarPage extends ConsumerStatefulWidget {
  const GrammarPage({super.key});

  @override
  ConsumerState<GrammarPage> createState() => _GrammarPageState();
}

class _GrammarPageState extends ConsumerState<GrammarPage> {
  final TextEditingController _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _open(GrammarTopicSummary t) {
    if (t.isLeaf) {
      context.push(AppRoutes.grammarLesson(t.id));
    } else {
      context.push(AppRoutes.grammarTopic(t.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String query = ref.watch(grammarQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grammar'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Grammar',
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _field,
              textInputAction: TextInputAction.search,
              onChanged: (String v) =>
                  ref.read(grammarQueryProvider.notifier).set(v),
              decoration: InputDecoration(
                hintText: 'Search grammar lessons',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear',
                        onPressed: () {
                          _field.clear();
                          ref.read(grammarQueryProvider.notifier).set('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: query.trim().isEmpty ? _dashboard() : _results(),
          ),
        ],
      ),
    );
  }

  Widget _results() {
    final AsyncValue<List<GrammarTopicSummary>> results =
        ref.watch(grammarSearchResultsProvider);
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _SearchHint(),
      data: (List<GrammarTopicSummary> list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: 'No lessons found',
            message: 'Try another word, or browse the categories.',
          );
        }
        return ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int i) =>
              GrammarTopicTile(topic: list[i], onTap: () => _open(list[i])),
        );
      },
    );
  }

  Widget _dashboard() {
    final List<GrammarTopicSummary> categories =
        ref.watch(grammarChildrenProvider(null)).maybeWhen(
              data: (List<GrammarTopicSummary> c) => c,
              orElse: () => const <GrammarTopicSummary>[],
            );
    final List<GrammarTopicSummary> continueLearning =
        ref.watch(grammarContinueProvider).maybeWhen(
              data: (List<GrammarTopicSummary> c) => c,
              orElse: () => const <GrammarTopicSummary>[],
            );
    final List<GrammarTopicSummary> favorites =
        ref.watch(grammarFavoritesProvider).maybeWhen(
              data: (List<GrammarTopicSummary> c) => c,
              orElse: () => const <GrammarTopicSummary>[],
            );

    if (categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: <Widget>[
        if (continueLearning.isNotEmpty) ...<Widget>[
          const _Header('Continue learning'),
          for (final GrammarTopicSummary t in continueLearning.take(3))
            GrammarTopicTile(topic: t, onTap: () => _open(t)),
          const Divider(height: 1),
        ],
        const _Header('Grammar topics'),
        for (final GrammarTopicSummary t in categories)
          GrammarTopicTile(topic: t, onTap: () => _open(t)),
        if (favorites.isNotEmpty) ...<Widget>[
          const Divider(height: 1),
          const _Header('Favorites'),
          for (final GrammarTopicSummary t in favorites)
            GrammarTopicTile(topic: t, onTap: () => _open(t)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('About Grammar'),
        content: const Text(
          'Learn grammar step by step. Each topic opens its subtopics, and each '
          'subtopic has its own lesson: introduction, Urdu and English '
          'explanation, types, rules, examples, common mistakes, practice, a '
          'quiz, and a summary. Everything works offline.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.menu_book_outlined,
      title: 'Search grammar',
      message: 'Type a topic like "noun", "present perfect" or "clause".',
    );
  }
}

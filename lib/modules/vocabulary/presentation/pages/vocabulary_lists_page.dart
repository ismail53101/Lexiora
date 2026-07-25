import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/core/widgets/error_view.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_list.dart';
import 'package:lexiora/modules/vocabulary/presentation/providers/vocabulary_providers.dart';
import 'package:lexiora/modules/vocabulary/presentation/widgets/vocabulary_list_card.dart';

/// Vocabulary home: pick a word list to browse A–Z. Vocabulary focuses purely
/// on vocabulary learning — cross-cutting upcoming features (Flashcards, Quiz,
/// AI Assistant, Cloud Sync) live on the Home screen, not here.
class VocabularyListsPage extends ConsumerWidget {
  const VocabularyListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<VocabularyListSummary>> lists =
        ref.watch(vocabularyListsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulary')),
      body: lists.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => ErrorView(
          title: 'Could not load vocabulary',
          message: 'Something went wrong loading the word lists.',
          onRetry: () => ref.invalidate(vocabularySeedProvider),
        ),
        data: (List<VocabularyListSummary> data) => ListView(
          children: <Widget>[
            const _Header('Word lists'),
            if (data.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No word lists yet',
                  message: 'Vocabulary packs will appear here once added.',
                ),
              )
            else
              for (final VocabularyListSummary l in data)
                VocabularyListCard(
                  list: l,
                  onTap: () => context.push(AppRoutes.vocabularyList(l.id)),
                ),
            const SizedBox(height: 24),
          ],
        ),
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

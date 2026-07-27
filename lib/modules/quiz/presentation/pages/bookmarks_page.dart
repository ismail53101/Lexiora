import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/paginated_questions.dart';

/// Bookmarked questions (optionally scoped to one subject), with a one-tap
/// "Practice bookmarked" session.
class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = subjectId != null
        ? 1 // scoped: always allow practice; player handles empty gracefully
        : ref.watch(quizBookmarkCountProvider).maybeWhen(
              data: (int v) => v,
              orElse: () => 0,
            );
    final String playPath = subjectId == null
        ? '${AppRoutes.quizPlayer}?bookmarked=1&mode=${QuizMode.practice.name}'
        : '${AppRoutes.quizPlayer}?subject=$subjectId&bookmarked=1&mode=${QuizMode.practice.name}';
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      floatingActionButton: count == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(playPath),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Practice'),
            ),
      body: PaginatedQuestions(
        filter: QuizFilter(subjectId: subjectId, onlyBookmarked: true),
        padding: const EdgeInsets.only(bottom: 88, top: 4),
        emptyTitle: 'No bookmarks',
        emptyMessage: 'Bookmark questions to revisit them here later.',
      ),
    );
  }
}

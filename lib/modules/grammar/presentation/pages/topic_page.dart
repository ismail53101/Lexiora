import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_topic.dart';
import 'package:lexiora/modules/grammar/presentation/providers/grammar_providers.dart';
import 'package:lexiora/modules/grammar/presentation/widgets/grammar_topic_tile.dart';

/// A category / subcategory screen: lists the children of a branch node. Tapping
/// a branch drills deeper; tapping a leaf opens its dedicated lesson.
class TopicPage extends ConsumerWidget {
  const TopicPage({super.key, required this.topicId});

  final String topicId;

  void _open(BuildContext context, GrammarTopicSummary t) {
    if (t.isLeaf) {
      context.push(AppRoutes.grammarLesson(t.id));
    } else {
      context.push(AppRoutes.grammarTopic(t.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = ref.watch(grammarTopicTitleProvider(topicId)).maybeWhen(
          data: (String? t) => t ?? 'Grammar',
          orElse: () => 'Grammar',
        );
    final AsyncValue<List<GrammarTopicSummary>> children =
        ref.watch(grammarChildrenProvider(topicId));

    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: children.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not open topic',
          message: 'Please try again.',
        ),
        data: (List<GrammarTopicSummary> list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nothing here yet',
              message: 'This topic has no lessons yet.',
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int i) =>
                GrammarTopicTile(topic: list[i], onTap: () => _open(context, list[i])),
          );
        },
      ),
    );
  }
}

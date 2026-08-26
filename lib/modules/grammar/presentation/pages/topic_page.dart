import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';
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
          final bool isTensesOverview = topicId == 'tenses';
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: list.length + (isTensesOverview ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int i) {
              if (isTensesOverview && i == list.length) {
                return const _TensesReferenceImage();
              }
              return GrammarTopicTile(
                topic: list[i],
                onTap: () => _open(context, list[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _TensesReferenceImage extends StatefulWidget {
  const _TensesReferenceImage();

  @override
  State<_TensesReferenceImage> createState() => _TensesReferenceImageState();
}

class _TensesReferenceImageState extends State<_TensesReferenceImage> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onDoubleTap: () {
            if (_controller.value != Matrix4.identity()) {
              _controller.value = Matrix4.identity();
            } else {
              _controller.value = Matrix4.identity()..scale(2.0);
            }
          },
          child: InteractiveViewer(
            transformationController: _controller,
            minScale: 1,
            maxScale: 4,
            child: Image.asset(
              'assets/grammar/images/english_tenses_at_a_glance.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

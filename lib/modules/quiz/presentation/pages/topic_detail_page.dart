import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_bank.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_topic.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';

/// A topic's quizzes. Tap a quiz to play it, or practise the whole topic.
class TopicDetailPage extends ConsumerWidget {
  const TopicDetailPage({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuizTopic? topic = ref.watch(quizTopicByIdProvider(topicId)).maybeWhen(
          data: (QuizTopic? t) => t,
          orElse: () => null,
        );
    final List<QuizBankSummary> quizzes =
        ref.watch(quizTopicBanksProvider(topicId)).maybeWhen(
              data: (List<QuizBankSummary> b) => b,
              orElse: () => const <QuizBankSummary>[],
            );
    final int totalQuestions =
        quizzes.fold(0, (int a, QuizBankSummary b) => a + b.questionCount);

    return Scaffold(
      appBar: AppBar(title: Text(topic?.name ?? 'Topic')),
      floatingActionButton: totalQuestions == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(
                  '${AppRoutes.quizPlayer}?topic=$topicId&mode=${QuizMode.practice.name}'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Practice all'),
            ),
      body: quizzes.isEmpty
          ? const EmptyState(
              icon: Icons.quiz_outlined,
              title: 'No quizzes yet',
              message: 'Quizzes for this topic are added from the Admin CMS.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88, top: 4),
              children: <Widget>[
                for (final QuizBankSummary b in quizzes)
                  Card(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: const Icon(Icons.play_circle_outline),
                      title: Text(b.bank.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${b.questionCount} questions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: b.questionCount == 0
                          ? null
                          : () => context.push(
                              '${AppRoutes.quizPlayer}?bank=${b.bank.id}&mode=${QuizMode.practice.name}'),
                    ),
                  ),
              ],
            ),
    );
  }
}

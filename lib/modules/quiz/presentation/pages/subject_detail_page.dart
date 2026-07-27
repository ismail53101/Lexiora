import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_bank.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_subject.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_topic.dart';
import 'package:lexiora/modules/quiz/presentation/pages/bookmarks_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/subject_stats_page.dart';
import 'package:lexiora/modules/quiz/presentation/pages/wrong_answers_page.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_icons.dart';

/// A subject's screen — topics + practice actions, mirroring the Grammar
/// hierarchy (Subject → Topic → Quiz).
class SubjectDetailPage extends ConsumerWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<QuizSubjectSummary> subjects =
        ref.watch(quizSubjectsProvider(false)).maybeWhen(
              data: (List<QuizSubjectSummary> s) => s,
              orElse: () => const <QuizSubjectSummary>[],
            );
    QuizSubject? subject;
    for (final QuizSubjectSummary s in subjects) {
      if (s.subject.id == subjectId) {
        subject = s.subject;
        break;
      }
    }
    final List<QuizTopicSummary> topics =
        ref.watch(quizTopicsProvider(subjectId)).maybeWhen(
              data: (List<QuizTopicSummary> t) => t,
              orElse: () => const <QuizTopicSummary>[],
            );
    final List<QuizBankSummary> looseQuizzes =
        ref.watch(quizSubjectLooseBanksProvider(subjectId)).maybeWhen(
              data: (List<QuizBankSummary> b) => b,
              orElse: () => const <QuizBankSummary>[],
            );

    return Scaffold(
      appBar: AppBar(title: Text(subject?.name ?? 'Subject')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          if (topics.isNotEmpty)
            QuizSectionCard(
              icon: Icons.category_outlined,
              title: 'Topics',
              child: Column(
                children: <Widget>[
                  for (final QuizTopicSummary t in topics)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(quizIcon(t.topic.icon)),
                      title: Text(t.topic.name),
                      subtitle: Text('${t.questionCount} questions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.quizTopic(t.topic.id)),
                    ),
                ],
              ),
            ),
          if (looseQuizzes.isNotEmpty)
            QuizSectionCard(
              icon: Icons.quiz_outlined,
              title: 'Quizzes',
              child: Column(
                children: <Widget>[
                  for (final QuizBankSummary b in looseQuizzes)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_circle_outline),
                      title: Text(b.bank.name),
                      subtitle: Text('${b.questionCount} questions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: b.questionCount == 0
                          ? null
                          : () => context.push(
                              '${AppRoutes.quizPlayer}?bank=${b.bank.id}&mode=${QuizMode.practice.name}'),
                    ),
                ],
              ),
            ),
          QuizSectionCard(
            icon: Icons.school_outlined,
            title: 'Practice',
            child: Column(
              children: <Widget>[
                _action(context, Icons.play_circle_outline, 'MCQs',
                    'Practice every question in this subject',
                    () => context.push(
                        '${AppRoutes.quizPlayer}?subject=$subjectId&mode=${QuizMode.practice.name}')),
                _action(context, Icons.star_border, 'Bookmarks',
                    'Your saved questions',
                    () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => BookmarksPage(subjectId: subjectId)))),
                _action(context, Icons.error_outline, 'Wrong Answers',
                    'Review and retry your mistakes',
                    () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => WrongAnswersPage(subjectId: subjectId)))),
                _action(context, Icons.bar_chart, 'Statistics',
                    'Your progress in this subject',
                    () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) =>
                            SubjectStatsPage(subjectId: subjectId, subjectName: subject?.name ?? 'Subject')))),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

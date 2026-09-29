import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/app_bottom_nav.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_subject.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_icons.dart';

/// Which subject list this page renders. Both share the same data; only the
/// title and the per-subject destination differ.
enum QuizSubjectsVariant {
  /// Subject-wise MCQs practice (subject → topics → practice).
  mcqs,

  /// Stage picker for the staged Quiz ladder (subject → stage map).
  stages,
}

/// Subject-first list. A learning surface only: it renders whatever published
/// subjects exist and never creates or manages content. Global learner
/// utilities live in the overflow menu.
class SubjectsPage extends ConsumerWidget {
  const SubjectsPage({super.key, this.variant = QuizSubjectsVariant.mcqs});

  final QuizSubjectsVariant variant;

  bool get _isStages => variant == QuizSubjectsVariant.stages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<QuizSubjectSummary>> subjectsAsync =
        ref.watch(quizSubjectsProvider(false));

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      appBar: AppBar(
        title: Text(_isStages ? 'Quiz' : 'MCQs'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push(AppRoutes.quizSearch),
          ),
          PopupMenuButton<String>(
            onSelected: (String v) {
              switch (v) {
                case 'analytics':
                  context.push(AppRoutes.quizAnalytics);
                case 'bookmarks':
                  context.push(AppRoutes.quizBookmarks);
                case 'wrong':
                  context.push(AppRoutes.quizWrong);
                case 'settings':
                  context.push(AppRoutes.quizSettings);
              }
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                  value: 'analytics', child: Text('Analytics')),
              PopupMenuItem<String>(
                  value: 'bookmarks', child: Text('Bookmarks')),
              PopupMenuItem<String>(
                  value: 'wrong', child: Text('Wrong answers')),
              PopupMenuItem<String>(
                  value: 'settings', child: Text('Quiz settings')),
            ],
          ),
        ],
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load subjects',
          message: 'Please try again.',
        ),
        data: (List<QuizSubjectSummary> subjects) {
          if (subjects.isEmpty) {
            return const EmptyState(
              icon: Icons.school_outlined,
              title: 'No subjects yet',
              message: 'Published quiz content will appear here once it is added.',
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: <Widget>[
              for (final QuizSubjectSummary s in subjects)
                _SubjectCard(summary: s, variant: variant),
              const SizedBox(height: 24),
            ].animate(interval: 40.ms).fadeIn(duration: 200.ms).slideY(
                  begin: 0.05,
                  end: 0,
                  curve: Curves.easeOut,
                ),
          );
        },
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.summary, required this.variant});
  final QuizSubjectSummary summary;
  final QuizSubjectsVariant variant;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final QuizSubject s = summary.subject;
    final Color color = s.colorValue ?? theme.colorScheme.primary;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push(variant == QuizSubjectsVariant.stages
            ? AppRoutes.quizStageMap(s.id)
            : AppRoutes.quizSubject(s.id)),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(quizIcon(s.icon), color: Colors.white),
        ),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(<String>[
          if (summary.topicCount > 0) '${summary.topicCount} topics',
          '${summary.questionCount} questions',
        ].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

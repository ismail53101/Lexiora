import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/presentation/pages/pos_quiz_stage_player_page.dart';
import 'package:lexiora/modules/grammar/presentation/providers/grammar_providers.dart';

/// Staged ladder for the Parts of Speech quiz. Each stage contains ten questions.
class PosQuizStageMapPage extends ConsumerStatefulWidget {
  const PosQuizStageMapPage({super.key});

  @override
  ConsumerState<PosQuizStageMapPage> createState() => _PosQuizStageMapPageState();
}

class _PosQuizStageMapPageState extends ConsumerState<PosQuizStageMapPage> {
  final Set<int> _passedStages = <int>{};

  bool _isUnlocked(int index) => index == 0 || _passedStages.contains(index - 1);

  Future<void> _openStage(GrammarLesson lesson, int index) async {
    if (!_isUnlocked(index)) return;
    final bool? passed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PosQuizStagePlayerPage(
          lesson: lesson,
          stageIndex: index,
        ),
      ),
    );
    if (passed == true && mounted) {
      setState(() => _passedStages.add(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<GrammarLesson?> lessonValue =
        ref.watch(grammarLeafProvider('pos/quiz'));
    return Scaffold(
      appBar: AppBar(title: const Text('Parts of Speech Quiz')),
      body: lessonValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load quiz questions.')),
        data: (GrammarLesson? lesson) {
          if (lesson == null || lesson.quiz.isEmpty) {
            return const Center(child: Text('No quiz questions available.'));
          }
          final int stageCount = (lesson.quiz.length + 9) ~/ 10;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(Icons.flag_outlined,
                              color: Theme.of(context).colorScheme.primary, size: 30),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text('Stage ladder',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    )),
                          ),
                          Text('${_passedStages.length} / $stageCount passed',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Each stage has 10 questions. Score 50% or more to unlock the next stage.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stageCount,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final bool unlocked = _isUnlocked(index);
                  final bool passed = _passedStages.contains(index);
                  final int count = (index == stageCount - 1)
                      ? lesson.quiz.length - index * 10
                      : 10;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: unlocked ? () => _openStage(lesson, index) : null,
                    child: Card(
                      color: unlocked
                          ? Theme.of(context).colorScheme.surface
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: passed
                              ? Colors.green
                              : unlocked
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                          width: unlocked || passed ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Icon(
                                  passed
                                      ? Icons.check_circle_outline
                                      : unlocked
                                          ? Icons.play_arrow_rounded
                                          : Icons.lock_outline,
                                  color: passed
                                      ? Colors.green
                                      : unlocked
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).disabledColor,
                                  size: 30,
                                ),
                                if (!unlocked)
                                  Icon(Icons.lock_outline,
                                      color: Theme.of(context).disabledColor),
                              ],
                            ),
                            const Spacer(),
                            Text('Stage ${index + 1}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    )),
                            const SizedBox(height: 6),
                            Text(
                              passed
                                  ? 'Passed'
                                  : unlocked
                                      ? '$count questions · 50s each'
                                      : 'Pass Stage $index to unlock',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

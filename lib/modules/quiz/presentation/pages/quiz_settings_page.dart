import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_settings.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';

/// Quiz Engine preferences. Applies immediately and persists to the key-value
/// settings store.
class QuizSettingsPage extends ConsumerStatefulWidget {
  const QuizSettingsPage({super.key});

  @override
  ConsumerState<QuizSettingsPage> createState() => _QuizSettingsPageState();
}

class _QuizSettingsPageState extends ConsumerState<QuizSettingsPage> {
  QuizSettings? _s;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final QuizSettings s = await ref.read(quizRepositoryProvider).loadSettings();
    if (mounted) setState(() => _s = s);
  }

  Future<void> _update(QuizSettings next) async {
    setState(() => _s = next);
    await ref.read(quizRepositoryProvider).saveSettings(next);
    ref.invalidate(quizSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final QuizSettings? s = _s;
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Settings')),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: <Widget>[
                const _SectionLabel('Session'),
                ListTile(
                  title: const Text('Default mode'),
                  subtitle: Text(s.defaultMode.description),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<QuizMode>(
                    segments: const <ButtonSegment<QuizMode>>[
                      ButtonSegment<QuizMode>(
                          value: QuizMode.practice, label: Text('Practice')),
                      ButtonSegment<QuizMode>(
                          value: QuizMode.exam, label: Text('Exam')),
                    ],
                    selected: <QuizMode>{s.defaultMode},
                    onSelectionChanged: (Set<QuizMode> v) =>
                        _update(s.copyWith(defaultMode: v.first)),
                  ),
                ),
                ListTile(
                  title: const Text('Questions per quiz'),
                  subtitle: Text(s.questionsPerQuiz == 0
                      ? 'All available'
                      : '${s.questionsPerQuiz} questions'),
                  trailing: DropdownButton<int>(
                    value: s.questionsPerQuiz,
                    items: const <DropdownMenuItem<int>>[
                      DropdownMenuItem<int>(value: 0, child: Text('All')),
                      DropdownMenuItem<int>(value: 10, child: Text('10')),
                      DropdownMenuItem<int>(value: 20, child: Text('20')),
                      DropdownMenuItem<int>(value: 30, child: Text('30')),
                      DropdownMenuItem<int>(value: 50, child: Text('50')),
                    ],
                    onChanged: (int? v) =>
                        _update(s.copyWith(questionsPerQuiz: v ?? 0)),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Shuffle questions'),
                  value: s.shuffleQuestions,
                  onChanged: (bool v) =>
                      _update(s.copyWith(shuffleQuestions: v)),
                ),
                SwitchListTile(
                  title: const Text('Shuffle options'),
                  value: s.shuffleOptions,
                  onChanged: (bool v) => _update(s.copyWith(shuffleOptions: v)),
                ),
                const Divider(),
                const _SectionLabel('Feedback'),
                SwitchListTile(
                  title: const Text('Show explanations'),
                  subtitle:
                      const Text('Reveal explanations after answering (Practice).'),
                  value: s.showExplanations,
                  onChanged: (bool v) =>
                      _update(s.copyWith(showExplanations: v)),
                ),
                SwitchListTile(
                  title: const Text('Negative marking'),
                  subtitle: const Text('Penalise wrong answers in Exam mode.'),
                  value: s.negativeMarking,
                  onChanged: (bool v) =>
                      _update(s.copyWith(negativeMarking: v)),
                ),
                const Divider(),
                const _SectionLabel('Timer'),
                SwitchListTile(
                  title: const Text('Enable timer'),
                  value: s.timerEnabled,
                  onChanged: (bool v) => _update(s.copyWith(timerEnabled: v)),
                ),
                if (s.timerEnabled)
                  ListTile(
                    title: const Text('Seconds per question'),
                    subtitle: Slider(
                      min: 15,
                      max: 180,
                      divisions: 11,
                      label: '${s.secondsPerQuestion}s',
                      value: s.secondsPerQuestion.toDouble().clamp(15, 180),
                      onChanged: (double v) =>
                          _update(s.copyWith(secondsPerQuestion: v.round())),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.primary)),
    );
  }
}

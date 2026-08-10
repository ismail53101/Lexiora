import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/pomodoro_state.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/pages/pomodoro_fullscreen_page.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/manual_timer_controller.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/pomodoro_controller.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

String _mmss(int seconds) {
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// ⏱️ Study Timer with two modes: the existing Pomodoro and a Manual (count-up)
/// timer where the user decides how long to study.
class StudyTimerCard extends ConsumerStatefulWidget {
  const StudyTimerCard({super.key});

  @override
  ConsumerState<StudyTimerCard> createState() => _StudyTimerCardState();
}

class _StudyTimerCardState extends ConsumerState<StudyTimerCard> {
  int _mode = 0; // 0 = Pomodoro, 1 = Manual

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int minutesToday = ref.watch(studyMinutesTodayProvider).maybeWhen(
          data: (int m) => m,
          orElse: () => 0,
        );
    return SectionCard(
      icon: Icons.timer_outlined,
      title: 'Study Timer',
      trailing: IconButton(
        icon: const Icon(Icons.fullscreen),
        tooltip: 'Full screen',
        visualDensity: VisualDensity.compact,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => const PomodoroFullscreenPage(),
          ),
        ),
      ),
      child: Column(
        children: <Widget>[
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 0, label: Text('Pomodoro')),
              ButtonSegment<int>(value: 1, label: Text('Manual')),
            ],
            selected: <int>{_mode},
            onSelectionChanged: (Set<int> s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 10),
          _mode == 0 ? const _PomodoroBody() : const _ManualBody(),
          const SizedBox(height: 8),
          Text('Studied today: ${formatDuration(minutesToday)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _PomodoroBody extends ConsumerWidget {
  const _PomodoroBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final PomodoroState state = ref.watch(pomodoroProvider);
    final PomodoroController controller = ref.read(pomodoroProvider.notifier);
    final bool isPreset = PomodoroMode.presets
        .any((PomodoroMode m) => m.label == state.mode.label);

    return Column(
      children: <Widget>[
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final PomodoroMode m in PomodoroMode.presets)
              ChoiceChip(
                label: Text(m.label),
                selected: state.mode.label == m.label,
                onSelected: (_) => controller.setMode(m),
              ),
            ChoiceChip(
              label: Text(isPreset ? 'Custom' : state.mode.label),
              selected: !isPreset,
              onSelected: (_) async {
                final PomodoroMode? m = await _pickCustom(context);
                if (m != null) controller.setMode(m);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        ProgressRing(
          value: state.progress,
          size: 132,
          strokeWidth: 10,
          color: state.isFocus
              ? theme.colorScheme.primary
              : theme.colorScheme.tertiary,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_mmss(state.remainingSeconds),
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(state.isFocus ? 'Focus' : 'Break',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FilledButton.icon(
              onPressed: state.running ? controller.pause : controller.start,
              icon: Icon(state.running ? Icons.pause : Icons.play_arrow),
              label: Text(state.running
                  ? 'Pause'
                  : (state.remainingSeconds < state.phaseSeconds
                      ? 'Resume'
                      : 'Start')),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: controller.reset,
              icon: const Icon(Icons.replay),
              label: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }

  Future<PomodoroMode?> _pickCustom(BuildContext context) {
    final TextEditingController focus = TextEditingController(text: '30');
    final TextEditingController brk = TextEditingController(text: '5');
    return showDialog<PomodoroMode>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Custom timer'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: focus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Focus (min)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: brk,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Break (min)'),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final int f = int.tryParse(focus.text.trim()) ?? 0;
              final int b = int.tryParse(brk.text.trim()) ?? 0;
              if (f <= 0) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pop(PomodoroMode('$f / $b', f, b < 0 ? 0 : b));
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}

class _ManualBody extends ConsumerWidget {
  const _ManualBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ManualTimerState state = ref.watch(manualTimerProvider);
    final ManualTimerController controller =
        ref.read(manualTimerProvider.notifier);
    final bool started = state.elapsedSeconds > 0 || state.running;

    return Column(
      children: <Widget>[
        Container(
          width: 132,
          height: 132,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_mmss(state.elapsedSeconds),
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(state.running ? 'Studying…' : 'Manual',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FilledButton.icon(
              onPressed: state.running ? controller.pause : controller.start,
              icon: Icon(state.running ? Icons.pause : Icons.play_arrow),
              label: Text(state.running ? 'Pause' : (started ? 'Resume' : 'Start')),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: started
                  ? () {
                      final int mins = controller.finish();
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                            content: Text(mins >= 1
                                ? 'Logged ${formatDuration(mins)} of study'
                                : 'Too short to log')));
                    }
                  : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Finish'),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/pomodoro_state.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/pomodoro_controller.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

String _mmss(int seconds) {
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// A distraction-free, full-screen view of the same Pomodoro timer shown on
/// the Study Planner dashboard — same [pomodoroProvider], so starting,
/// pausing or resetting here is reflected back on the dashboard card (and
/// vice versa) instantly, since they share one controller.
class PomodoroFullscreenPage extends ConsumerWidget {
  const PomodoroFullscreenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final PomodoroState state = ref.watch(pomodoroProvider);
    final PomodoroController controller = ref.read(pomodoroProvider.notifier);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Exit full screen',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    Text('Pomodoro',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    const SizedBox(width: 48), // balances the close button
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(state.mode.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 24),
                      ProgressRing(
                        value: state.progress,
                        size: 280,
                        strokeWidth: 16,
                        color: state.isFocus
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(_mmss(state.remainingSeconds),
                                style: theme.textTheme.displayLarge
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            Text(state.isFocus ? 'Focus' : 'Break',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 18),
                              textStyle: theme.textTheme.titleMedium,
                            ),
                            onPressed:
                                state.running ? controller.pause : controller.start,
                            icon: Icon(
                                state.running ? Icons.pause : Icons.play_arrow,
                                size: 26),
                            label: Text(state.running
                                ? 'Pause'
                                : (state.remainingSeconds < state.phaseSeconds
                                    ? 'Resume'
                                    : 'Start')),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 18),
                              textStyle: theme.textTheme.titleMedium,
                            ),
                            onPressed: controller.reset,
                            icon: const Icon(Icons.replay, size: 24),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

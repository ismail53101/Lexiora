import 'dart:math' as math;

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
///
/// Premium interaction: tap the big ring to start and tap it again to pause —
/// there is no separate Start button, just a Reset. Rotating the phone flips
/// into a wide "big screen" layout (ring left, controls right).
class PomodoroFullscreenPage extends ConsumerWidget {
  const PomodoroFullscreenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final PomodoroState state = ref.watch(pomodoroProvider);
    final PomodoroController controller = ref.read(pomodoroProvider.notifier);
    final bool running = state.running;

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
                child: LayoutBuilder(
                  builder:
                      (BuildContext context, BoxConstraints constraints) {
                    final bool landscape =
                        constraints.maxWidth > constraints.maxHeight;
                    // The ring scales with the screen — big and bold in
                    // landscape, like a real desk timer.
                    final double ringSize = landscape
                        ? math.min(constraints.maxHeight * 0.72, 360.0)
                        : 280.0;

                    final Widget dial = GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: running ? controller.pause : controller.start,
                      child: ProgressRing(
                        value: state.progress,
                        size: ringSize,
                        strokeWidth: landscape ? 22 : 16,
                        color: state.isFocus
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(_mmss(state.remainingSeconds),
                                style: theme.textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: ringSize * 0.24)),
                            Text(state.isFocus ? 'Focus' : 'Break',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    );

                    final Widget hint = Text(
                      running
                          ? 'Tap the ring to pause'
                          : 'Tap the ring to start',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    );

                    final Widget reset = OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 18),
                        textStyle: theme.textTheme.titleMedium,
                      ),
                      onPressed: controller.reset,
                      icon: const Icon(Icons.replay, size: 24),
                      label: const Text('Reset'),
                    );

                    if (landscape) {
                      // Big-screen mode: ring on the left, info + controls on
                      // the right so everything fits a rotated phone.
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 32, 24),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: Center(child: dial)),
                            const SizedBox(width: 40),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(state.mode.label,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 8),
                                  Text(
                                      state.isFocus ? 'Focus session' : 'Break',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 28),
                                  hint,
                                  const SizedBox(height: 16),
                                  reset,
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(state.mode.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 24),
                          dial,
                          const SizedBox(height: 28),
                          hint,
                          const SizedBox(height: 16),
                          reset,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

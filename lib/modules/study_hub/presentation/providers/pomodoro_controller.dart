import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/pomodoro_state.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:uuid/uuid.dart';

/// Drives the Pomodoro timer. Pure transitions live in [PomodoroState]; this
/// controller only wires a 1-second [Timer] and records a study session each
/// time a focus block completes (which feeds hours, streak and statistics).
class PomodoroController extends Notifier<PomodoroState> {
  Timer? _timer;

  @override
  PomodoroState build() {
    ref.onDispose(_stopTimer);
    return PomodoroState.initial();
  }

  void start() {
    if (state.running) return;
    state = state.start();
    _ensureTimer();
  }

  void pause() {
    state = state.pause();
    _stopTimer();
  }

  void resume() => start();

  void reset() {
    stopAndSave();
  }

  /// Saves the still-open focus portion before resetting or leaving the timer.
  /// Completed focus blocks are already persisted by [_onTick].
  int stopAndSave() {
    _stopTimer();
    final int minutes = _recordPartialFocus();
    state = state.reset();
    return minutes;
  }

  void setMode(PomodoroMode mode) {
    stopAndSave();
    state = PomodoroState.initial(mode);
  }

  void _ensureTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTick() {
    final PomodoroTick tick = state.tick();
    state = tick.state;
    if (tick.focusCompleted) {
      final DateTime now = DateTime.now();
      final ActiveStudyContext context = ref.read(activeStudyContextProvider);
      unawaited(ref.read(studyHubRepositoryProvider).addSession(StudySession(
            id: const Uuid().v4(),
            day: dayKey(now.subtract(Duration(minutes: tick.focusMinutes))),
            startedAt: now.subtract(Duration(minutes: tick.focusMinutes)),
            durationMinutes: tick.focusMinutes,
            subject: context.subject,
            taskId: context.taskId,
            endedAt: now,
            createdAt: now,
          )));
      if (context.taskId != null) {
        unawaited(ref.read(studyHubRepositoryProvider).setTaskCompleted(
            context.taskId!, completed: true));
      }
    }
    if (!state.running) _stopTimer();
  }

  int _recordPartialFocus() {
    if (!state.isFocus) return 0;
    final int minutes =
        (state.phaseSeconds - state.remainingSeconds) ~/ 60;
    if (minutes < 1) return 0;
    final DateTime now = DateTime.now();
    final ActiveStudyContext context = ref.read(activeStudyContextProvider);
    unawaited(ref.read(studyHubRepositoryProvider).addSession(StudySession(
          id: const Uuid().v4(),
          day: dayKey(now.subtract(Duration(minutes: minutes))),
          startedAt: now.subtract(Duration(minutes: minutes)),
          durationMinutes: minutes,
          subject: context.subject,
          taskId: context.taskId,
          endedAt: now,
          createdAt: now,
        )));
    if (context.taskId != null) {
      unawaited(ref.read(studyHubRepositoryProvider).setTaskCompleted(
          context.taskId!, completed: true));
    }
    return minutes;
  }
}

final NotifierProvider<PomodoroController, PomodoroState> pomodoroProvider =
    NotifierProvider<PomodoroController, PomodoroState>(PomodoroController.new);

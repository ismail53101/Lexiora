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
    _stopTimer();
    state = state.reset();
  }

  void setMode(PomodoroMode mode) {
    _stopTimer();
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
      unawaited(ref.read(studyHubRepositoryProvider).addSession(StudySession(
            id: const Uuid().v4(),
            day: todayKey(),
            startedAt: now.subtract(Duration(minutes: tick.focusMinutes)),
            durationMinutes: tick.focusMinutes,
            createdAt: now,
          )));
    }
    if (!state.running) _stopTimer();
  }
}

final NotifierProvider<PomodoroController, PomodoroState> pomodoroProvider =
    NotifierProvider<PomodoroController, PomodoroState>(PomodoroController.new);

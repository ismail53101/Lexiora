import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:uuid/uuid.dart';

/// State of the manual (count-up) study timer.
class ManualTimerState extends Equatable {
  const ManualTimerState({this.running = false, this.elapsedSeconds = 0});
  final bool running;
  final int elapsedSeconds;

  ManualTimerState copyWith({bool? running, int? elapsedSeconds}) =>
      ManualTimerState(
        running: running ?? this.running,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      );

  @override
  List<Object?> get props => <Object?>[running, elapsedSeconds];
}

/// A manual study timer: the user decides how long to study. Start / Pause /
/// Resume / Finish. Finishing logs a study session (>= 1 minute) so statistics,
/// hours and the streak update automatically.
class ManualTimerController extends Notifier<ManualTimerState> {
  Timer? _timer;

  @override
  ManualTimerState build() {
    ref.onDispose(_stop);
    return const ManualTimerState();
  }

  void start() {
    if (state.running) return;
    state = state.copyWith(running: true);
    _timer ??= Timer.periodic(const Duration(seconds: 1),
        (_) => state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1));
  }

  void pause() {
    state = state.copyWith(running: false);
    _stop();
  }

  void reset() {
    finish();
  }

  /// Saves the elapsed study time before the timer is reset or its page exits.
  int stopAndSave() => finish();

  /// Stops, logs a session for the elapsed whole minutes, and resets.
  /// Returns the logged minutes (0 if under a minute).
  int finish() {
    _stop();
    final int minutes = state.elapsedSeconds ~/ 60;
    final ActiveStudyContext context = ref.read(activeStudyContextProvider);
    if (minutes >= 1) {
      final DateTime now = DateTime.now();
      unawaited(ref.read(studyHubRepositoryProvider).addSession(StudySession(
            id: const Uuid().v4(),
            day: dayKey(now.subtract(Duration(minutes: minutes))),
            startedAt: now.subtract(Duration(minutes: minutes)),
            durationMinutes: minutes,
            kind: 'manual',
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
    ref.read(activeStudyContextProvider.notifier).clear();
    state = const ManualTimerState();
    return minutes;
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}

final NotifierProvider<ManualTimerController, ManualTimerState>
    manualTimerProvider =
    NotifierProvider<ManualTimerController, ManualTimerState>(
        ManualTimerController.new);

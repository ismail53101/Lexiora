import 'package:equatable/equatable.dart';

/// A Pomodoro focus/break configuration.
class PomodoroMode extends Equatable {
  const PomodoroMode(this.label, this.focusMinutes, this.breakMinutes);

  final String label;
  final int focusMinutes;
  final int breakMinutes;

  static const PomodoroMode pomodoro25 = PomodoroMode('25 / 5', 25, 5);
  static const PomodoroMode pomodoro50 = PomodoroMode('50 / 10', 50, 10);

  /// The built-in presets shown as chips (Custom is added by the UI).
  static const List<PomodoroMode> presets = <PomodoroMode>[
    pomodoro25,
    pomodoro50,
  ];

  @override
  List<Object?> get props => <Object?>[label, focusMinutes, breakMinutes];
}

enum PomodoroPhase { focus, brk }

/// The result of advancing the timer one second: the next [state] plus whether
/// a focus block just completed (so the caller can record a study session).
class PomodoroTick {
  const PomodoroTick(this.state, {this.focusCompleted = false, this.focusMinutes = 0});
  final PomodoroState state;
  final bool focusCompleted;
  final int focusMinutes;
}

/// Immutable, fully testable Pomodoro timer state. All transitions are pure —
/// the controller wires a real 1-second [Timer] to [tick].
class PomodoroState extends Equatable {
  const PomodoroState({
    required this.mode,
    required this.phase,
    required this.remainingSeconds,
    required this.running,
    this.completedFocus = 0,
  });

  final PomodoroMode mode;
  final PomodoroPhase phase;
  final int remainingSeconds;
  final bool running;
  final int completedFocus;

  factory PomodoroState.initial([PomodoroMode mode = PomodoroMode.pomodoro25]) =>
      PomodoroState(
        mode: mode,
        phase: PomodoroPhase.focus,
        remainingSeconds: mode.focusMinutes * 60,
        running: false,
      );

  int get phaseSeconds =>
      (phase == PomodoroPhase.focus ? mode.focusMinutes : mode.breakMinutes) * 60;

  /// Elapsed fraction of the current phase, 0..1.
  double get progress =>
      phaseSeconds == 0 ? 0 : 1 - (remainingSeconds / phaseSeconds);

  bool get isFocus => phase == PomodoroPhase.focus;

  PomodoroState copyWith({
    PomodoroPhase? phase,
    int? remainingSeconds,
    bool? running,
    int? completedFocus,
  }) {
    return PomodoroState(
      mode: mode,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      running: running ?? this.running,
      completedFocus: completedFocus ?? this.completedFocus,
    );
  }

  PomodoroState start() => copyWith(running: true);
  PomodoroState pause() => copyWith(running: false);

  /// Back to a fresh focus block for the current mode (keeps the session count).
  PomodoroState reset() => PomodoroState(
        mode: mode,
        phase: PomodoroPhase.focus,
        remainingSeconds: mode.focusMinutes * 60,
        running: false,
        completedFocus: completedFocus,
      );

  /// Advance one second. When a focus block reaches zero it flips to a break
  /// (and reports the completed focus minutes); a finished break flips back to
  /// focus. A paused timer is unchanged.
  PomodoroTick tick() {
    if (!running) return PomodoroTick(this);
    if (remainingSeconds > 1) {
      return PomodoroTick(copyWith(remainingSeconds: remainingSeconds - 1));
    }
    if (phase == PomodoroPhase.focus) {
      return PomodoroTick(
        copyWith(
          phase: PomodoroPhase.brk,
          remainingSeconds: mode.breakMinutes * 60,
          completedFocus: completedFocus + 1,
        ),
        focusCompleted: true,
        focusMinutes: mode.focusMinutes,
      );
    }
    return PomodoroTick(
      copyWith(
        phase: PomodoroPhase.focus,
        remainingSeconds: mode.focusMinutes * 60,
      ),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[mode, phase, remainingSeconds, running, completedFocus];
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/study_hub/domain/pomodoro_state.dart';

void main() {
  test('initial state is a paused focus block for the mode', () {
    final PomodoroState s = PomodoroState.initial();
    expect(s.phase, PomodoroPhase.focus);
    expect(s.running, isFalse);
    expect(s.remainingSeconds, 25 * 60);
    expect(s.completedFocus, 0);
  });

  test('a paused timer does not advance on tick', () {
    final PomodoroState s = PomodoroState.initial();
    final PomodoroTick t = s.tick();
    expect(t.state, s);
    expect(t.focusCompleted, isFalse);
  });

  test('running timer counts down one second per tick', () {
    final PomodoroState s = PomodoroState.initial().start();
    final PomodoroTick t = s.tick();
    expect(t.state.remainingSeconds, 25 * 60 - 1);
    expect(t.state.running, isTrue);
  });

  test('finishing a focus block flips to break and reports completion', () {
    final PomodoroState s = PomodoroState.initial().start().copyWith(remainingSeconds: 1);
    final PomodoroTick t = s.tick();
    expect(t.focusCompleted, isTrue);
    expect(t.focusMinutes, 25);
    expect(t.state.phase, PomodoroPhase.brk);
    expect(t.state.remainingSeconds, 5 * 60);
    expect(t.state.completedFocus, 1);
    expect(t.state.running, isTrue);
  });

  test('finishing a break flips back to focus without a session', () {
    final PomodoroState s = PomodoroState.initial()
        .start()
        .copyWith(phase: PomodoroPhase.brk, remainingSeconds: 1);
    final PomodoroTick t = s.tick();
    expect(t.focusCompleted, isFalse);
    expect(t.state.phase, PomodoroPhase.focus);
    expect(t.state.remainingSeconds, 25 * 60);
  });

  test('reset returns to a fresh focus block but keeps the session count', () {
    final PomodoroState s = PomodoroState.initial()
        .start()
        .copyWith(remainingSeconds: 3, completedFocus: 2);
    final PomodoroState r = s.reset();
    expect(r.running, isFalse);
    expect(r.phase, PomodoroPhase.focus);
    expect(r.remainingSeconds, 25 * 60);
    expect(r.completedFocus, 2);
  });

  test('progress reflects elapsed fraction of the phase', () {
    final PomodoroState s =
        PomodoroState.initial().copyWith(remainingSeconds: 25 * 60 ~/ 2);
    expect(s.progress, closeTo(0.5, 0.01));
  });
}

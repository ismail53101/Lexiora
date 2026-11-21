import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/study_hub/domain/scheduling/pomodoro_planner.dart';

void main() {
  List<(BlockKind, int)> kinds(PomodoroPlan p) =>
      p.blocks.map((PlannedBlock b) => (b.kind, b.minutes)).toList();

  test('2 hours with 50 + 10: focus, break, focus, break, focus 20', () {
    final PomodoroPlan p =
        planPomodoro(totalFocusMinutes: 120, focusMinutes: 50, breakMinutes: 10);
    expect(kinds(p), <(BlockKind, int)>[
      (BlockKind.focus, 50),
      (BlockKind.rest, 10),
      (BlockKind.focus, 50),
      (BlockKind.rest, 10),
      (BlockKind.focus, 20),
    ]);
    expect(p.focusBlocks, 3);
    expect(p.breaks, 2);
    expect(p.focusMinutes, 120);
    expect(p.windowMinutes, 140);
    expect(p.summary, '50 + 10 + 50 + 10 + 20');
  });

  test('offsets are cumulative and there is never a trailing break', () {
    final PomodoroPlan p =
        planPomodoro(totalFocusMinutes: 100, focusMinutes: 50, breakMinutes: 10);
    expect(p.blocks.map((PlannedBlock b) => b.offsetMinutes).toList(), <int>[0, 50, 60]);
    expect(p.blocks.last.kind, BlockKind.focus);
    expect(p.blocks.last.endOffsetMinutes, p.windowMinutes);
  });

  test('a tiny tail is merged into the previous focus block', () {
    final PomodoroPlan p =
        planPomodoro(totalFocusMinutes: 105, focusMinutes: 50, breakMinutes: 10);
    expect(kinds(p), <(BlockKind, int)>[
      (BlockKind.focus, 50),
      (BlockKind.rest, 10),
      (BlockKind.focus, 55),
    ]);
    expect(p.focusMinutes, 105);
  });

  test('a tail of exactly the minimum stays a block', () {
    final PomodoroPlan p =
        planPomodoro(totalFocusMinutes: 60, focusMinutes: 25, breakMinutes: 5);
    expect(p.blocks.last.minutes, 10);
    expect(p.focusBlocks, 3);
  });

  test('a session no longer than one block is a single block, no break', () {
    final PomodoroPlan p =
        planPomodoro(totalFocusMinutes: 30, focusMinutes: 25, breakMinutes: 5);
    expect(kinds(p), <(BlockKind, int)>[(BlockKind.focus, 30)]);
    expect(p.breaks, 0);
    expect(planPomodoro(totalFocusMinutes: 20, focusMinutes: 50, breakMinutes: 10).blocks, hasLength(1));
  });

  test('zero break length gives back-to-back focus blocks', () {
    final PomodoroPlan p =
        planPomodoro(totalFocusMinutes: 100, focusMinutes: 50, breakMinutes: 0);
    expect(p.breaks, 0);
    expect(p.focusBlocks, 2);
    expect(p.windowMinutes, 100);
  });


  test('a 1-hour split is 50 minutes focus plus 10 minutes break', () {
    final PomodoroPlan p = planPomodoroWindow(
      totalWindowMinutes: 60,
      focusMinutes: 50,
      breakMinutes: 10,
    );
    expect(kinds(p), <(BlockKind, int)>[
      (BlockKind.focus, 50),
      (BlockKind.rest, 10),
    ]);
    expect(p.windowMinutes, 60);
    expect(p.focusMinutes, 50);
  });

  test('a 2-hour split keeps the full window without a trailing focus extension', () {
    final PomodoroPlan p = planPomodoroWindow(
      totalWindowMinutes: 120,
      focusMinutes: 50,
      breakMinutes: 10,
    );
    expect(kinds(p), <(BlockKind, int)>[
      (BlockKind.focus, 50),
      (BlockKind.rest, 10),
      (BlockKind.focus, 50),
      (BlockKind.rest, 10),
    ]);
    expect(p.windowMinutes, 120);
    expect(p.focusMinutes, 100);
  });

  test('empty input gives an empty plan', () {
    expect(planPomodoro(totalFocusMinutes: 0, focusMinutes: 25, breakMinutes: 5).blocks, isEmpty);
  });

  test('focus minutes are always preserved exactly', () {
    for (int total = 5; total <= 400; total += 7) {
      for (final (int f, int b) in <(int, int)>[(25, 5), (50, 10), (90, 15)]) {
        final PomodoroPlan p =
            planPomodoro(totalFocusMinutes: total, focusMinutes: f, breakMinutes: b);
        expect(p.focusMinutes, total, reason: '$total / $f+$b');
      }
    }
  });
}

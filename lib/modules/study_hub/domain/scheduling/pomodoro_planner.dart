/// Splits a long study session into focus blocks with short breaks between
/// them (Pomodoro style). Pure arithmetic — no AI, no I/O.
library;

enum BlockKind { focus, rest }

/// One piece of a plan, relative to the start of the plan.
class PlannedBlock {
  const PlannedBlock({
    required this.kind,
    required this.offsetMinutes,
    required this.minutes,
  });

  final BlockKind kind;

  /// Minutes after the start of the whole plan.
  final int offsetMinutes;
  final int minutes;

  int get endOffsetMinutes => offsetMinutes + minutes;
}

class PomodoroPlan {
  const PomodoroPlan(this.blocks);

  final List<PlannedBlock> blocks;

  int get focusBlocks =>
      blocks.where((PlannedBlock b) => b.kind == BlockKind.focus).length;
  int get breaks =>
      blocks.where((PlannedBlock b) => b.kind == BlockKind.rest).length;
  int get focusMinutes => blocks
      .where((PlannedBlock b) => b.kind == BlockKind.focus)
      .fold(0, (int s, PlannedBlock b) => s + b.minutes);

  /// Total time from the first block's start to the last block's end,
  /// including the breaks.
  int get windowMinutes => blocks.isEmpty ? 0 : blocks.last.endOffsetMinutes;

  /// "50 + 10 + 50 + 10 + 20" for previews.
  String get summary =>
      blocks.map((PlannedBlock b) => '${b.minutes}').join(' + ');
}

/// Plans [totalFocusMinutes] of study as focus blocks of [focusMinutes] with
/// a [breakMinutes] break between consecutive blocks (never after the last).
///
/// A leftover tail shorter than [minTailMinutes] is merged into the previous
/// focus block instead of becoming a tiny block of its own.
PomodoroPlan planPomodoro({
  required int totalFocusMinutes,
  required int focusMinutes,
  required int breakMinutes,
  int minTailMinutes = 10,
}) {
  assert(focusMinutes > 0 && breakMinutes >= 0);
  if (totalFocusMinutes <= 0) return const PomodoroPlan(<PlannedBlock>[]);

  final List<int> focuses = <int>[];
  int remaining = totalFocusMinutes;
  while (remaining > 0) {
    final int f = remaining < focusMinutes ? remaining : focusMinutes;
    remaining -= f;
    if (f < minTailMinutes && focuses.isNotEmpty) {
      focuses[focuses.length - 1] += f;
    } else {
      focuses.add(f);
    }
  }

  final List<PlannedBlock> out = <PlannedBlock>[];
  int offset = 0;
  for (int i = 0; i < focuses.length; i++) {
    out.add(PlannedBlock(
      kind: BlockKind.focus,
      offsetMinutes: offset,
      minutes: focuses[i],
    ));
    offset += focuses[i];
    if (i < focuses.length - 1 && breakMinutes > 0) {
      out.add(PlannedBlock(
        kind: BlockKind.rest,
        offsetMinutes: offset,
        minutes: breakMinutes,
      ));
      offset += breakMinutes;
    }
  }
  return PomodoroPlan(out);
}

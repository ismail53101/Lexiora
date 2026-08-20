import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/scheduling/study_schedule_service.dart';

void main() {
  final DateTime created = DateTime(2026, 1, 1);

  StudyTask task(
    String id, {
    required int start,
    required int end,
    bool automatic = false,
    SessionKind kind = SessionKind.session,
  }) {
    return StudyTask(
      id: id,
      day: '2026-01-01',
      title: id,
      startMinute: start,
      endMinute: end,
      durationMinutes: end - start,
      autoScheduled: automatic,
      kind: kind,
      createdAt: created,
      updatedAt: created,
    );
  }

  test('next automatic session follows a ten-minute break at 10:10', () {
    final List<StudyTask> rows = StudyScheduleService.recalculate(<StudyTask>[
      task('session', start: 540, end: 600),
      task('break', start: 600, end: 610, kind: SessionKind.breakTime),
      task('next', start: 610, end: 670, automatic: true),
    ]);
    expect(rows.singleWhere((StudyTask t) => t.id == 'next').startMinute, 610);
  });

  test('next automatic session follows a twenty-minute break at 10:20', () {
    final List<StudyTask> rows = StudyScheduleService.recalculate(<StudyTask>[
      task('session', start: 540, end: 600),
      task('break', start: 600, end: 620, kind: SessionKind.breakTime),
      task('next', start: 620, end: 680, automatic: true),
    ]);
    expect(rows.singleWhere((StudyTask t) => t.id == 'next').startMinute, 620);
  });

  test('next automatic session starts at the previous end without a break', () {
    final List<StudyTask> rows = StudyScheduleService.recalculate(<StudyTask>[
      task('session', start: 540, end: 600),
      task('next', start: 600, end: 660, automatic: true),
    ]);
    expect(rows.singleWhere((StudyTask t) => t.id == 'next').startMinute, 600);
  });

  test('editing a session or break duration propagates to later automatic rows', () {
    final List<StudyTask> rows = StudyScheduleService.recalculate(<StudyTask>[
      task('session', start: 540, end: 630),
      task('break', start: 630, end: 650, kind: SessionKind.breakTime),
      task('next', start: 650, end: 710, automatic: true),
    ]);
    expect(rows.singleWhere((StudyTask t) => t.id == 'next').startMinute, 650);
  });

  test('manual time remains an anchor and overlap is reported', () {
    final List<StudyTask> rows = StudyScheduleService.recalculate(<StudyTask>[
      task('automatic', start: 540, end: 600, automatic: true),
      task('manual', start: 570, end: 630),
    ]);
    expect(rows.singleWhere((StudyTask t) => t.id == 'manual').startMinute, 570);
    expect(StudyScheduleService.conflicts(rows), hasLength(1));
  });

  test('ordering uses minute values and supports midnight and noon', () {
    expect(StudyScheduleService.normalizeMinute(0), 0);
    expect(StudyScheduleService.normalizeMinute(720), 720);
    final List<StudyTask> rows = StudyScheduleService.recalculate(<StudyTask>[
      task('noon', start: 720, end: 780),
      task('midnight', start: 0, end: 60),
      task('later', start: 780, end: 840, automatic: true),
    ]);
    expect(rows.map((StudyTask t) => t.id).toList(), <String>[
      'midnight',
      'noon',
      'later',
    ]);
  });
}

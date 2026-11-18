import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/study_hub/data/datasources/study_hub_local_data_source.dart';
import 'package:lexiora/modules/study_hub/data/repositories/study_hub_repository_impl.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/scheduling/study_schedule_service.dart';

/// Regression tests for the "add subject + break" flow of the session editor:
/// duplicates on retry, breaks silently dropped, half-saved sessions and
/// automatic sessions starting at midnight.
void main() {
  const String day = '2026-03-10';
  const int h = 60;
  final List<AppDatabase> dbs = <AppDatabase>[];

  Future<StudyHubRepositoryImpl> repo({Future<void> Function()? onChanged}) async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    dbs.add(db);
    return StudyHubRepositoryImpl(StudyHubLocalDataSource(db), onTasksChanged: onChanged);
  }

  tearDownAll(() async {
    for (final AppDatabase d in dbs) {
      await d.close();
    }
  });

  StudyTask session(
    String id,
    String subject, {
    int? start,
    int? duration,
    bool auto = false,
  }) {
    final DateTime now = DateTime(2026, 3, 10);
    return StudyTask(
      id: id,
      day: day,
      title: subject,
      subject: subject,
      kind: SessionKind.session,
      startMinute: auto ? null : start,
      endMinute: auto || start == null || duration == null ? null : start + duration,
      durationMinutes: duration,
      autoScheduled: auto,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<StudyTask>> timeline(StudyHubRepositoryImpl r) async {
    final List<StudyTask> t = await r.watchTasks(day).first;
    t.sort((StudyTask a, StudyTask b) =>
        (a.startMinute ?? 99999).compareTo(b.startMinute ?? 99999));
    return t;
  }

  String line(StudyTask t) =>
      '${t.isBreak ? 'B' : 'S'} ${t.title} ${t.startMinute}-${t.endMinute}';

  group('scheduling rules', () {
    test('an empty day starts automatic items at 09:00, not midnight', () {
      expect(StudyScheduleService.nextAvailableMinute(const <StudyTask>[]), 9 * h);
    });

    test('validateSpan', () {
      expect(StudyScheduleService.validateSpan(null, null), isNull);
      expect(StudyScheduleService.validateSpan(9 * h, 10 * h), isNull);
      expect(StudyScheduleService.validateSpan(10 * h, 10 * h), isNotNull);
      expect(StudyScheduleService.validateSpan(11 * h, 10 * h), isNotNull);
      expect(StudyScheduleService.validateSpan(9 * h, null), isNotNull);
      expect(StudyScheduleService.validateSpan(23 * h, 25 * h), isNotNull);
      expect(StudyScheduleService.validateSpan(23 * h, 24 * h), isNull);
    });
  });

  group('saveSessionWithBreak', () {
    test('your example: 9–10 + break, then automatic subjects follow with breaks', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveSessionWithBreak(
          session: session('s1', 'Maths', start: 9 * h, duration: h), breakId: 'b1', breakMinutes: 10);
      await r.saveSessionWithBreak(
          session: session('s2', 'English', duration: h, auto: true), breakId: 'b2', breakMinutes: 10);
      await r.saveSessionWithBreak(
          session: session('s3', 'Physics', duration: h, auto: true), breakId: 'b3', breakMinutes: 10);
      expect((await timeline(r)).map(line).toList(), <String>[
        'S Maths 540-600',
        'B Break 600-610',
        'S English 610-670',
        'B Break 670-680',
        'S Physics 680-740',
        'B Break 740-750',
      ]);
    });

    test('the first automatic session of a day is placed at 09:00', () async {
      final StudyHubRepositoryImpl r = await repo();
      final StudyTask saved = await r.saveSessionWithBreak(
          session: session('s1', 'Maths', duration: h, auto: true), breakId: 'b1');
      expect((saved.startMinute, saved.endMinute), (9 * h, 10 * h));
    });

    test('saving again with the same ids never duplicates', () async {
      final StudyHubRepositoryImpl r = await repo();
      for (int i = 0; i < 3; i++) {
        await r.saveSessionWithBreak(
            session: session('s1', 'Maths', duration: h, auto: true), breakId: 'b1', breakMinutes: 10);
      }
      final List<StudyTask> t = await timeline(r);
      expect(t.where((StudyTask x) => !x.isBreak), hasLength(1));
      expect(t.where((StudyTask x) => x.isBreak), hasLength(1));
    });

    test('an overlap saves NOTHING (no half-saved session)', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(session('fixed', 'Chemistry', start: 10 * h + 30, duration: h));
      await expectLater(
        r.saveSessionWithBreak(
            session: session('s1', 'Maths', start: 10 * h, duration: h), breakId: 'b1', breakMinutes: 10),
        throwsA(isA<StudyScheduleOverlapException>()),
      );
      expect((await timeline(r)).map((StudyTask t) => t.id).toList(), <String>['fixed']);
    });

    test('a break that would overlap the next fixed session is rejected as a whole', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(session('fixed', 'Chemistry', start: 10 * h + 5, duration: h));
      await expectLater(
        r.saveSessionWithBreak(
            session: session('s1', 'Maths', start: 9 * h, duration: h), breakId: 'b1', breakMinutes: 10),
        throwsA(isA<StudyScheduleOverlapException>()),
      );
      expect(await timeline(r), hasLength(1));
    });

    test('invalid times are rejected and nothing is saved', () async {
      final StudyHubRepositoryImpl r = await repo();
      await expectLater(
        r.saveSessionWithBreak(
            session: session('s1', 'Maths', start: 11 * h, duration: -30), breakId: 'b1'),
        throwsA(isA<StudyScheduleInvalidTimeException>()),
      );
      await expectLater(
        r.saveSessionWithBreak(
            session: session('s2', 'Maths', start: 23 * h + 30, duration: h), breakId: 'b2'),
        throwsA(isA<StudyScheduleInvalidTimeException>()),
      );
      await expectLater(
        r.saveSessionWithBreak(
            session: session('s3', 'Maths', start: 23 * h, duration: 50), breakId: 'b3', breakMinutes: 30),
        throwsA(isA<StudyScheduleInvalidTimeException>()),
      );
      expect(await timeline(r), isEmpty);
    });

    test('editing an automatic session keeps its place and later ones follow', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveSessionWithBreak(session: session('a', 'A', duration: h, auto: true), breakId: 'ba');
      await r.saveSessionWithBreak(session: session('b', 'B', duration: h, auto: true), breakId: 'bb');
      final StudyTask a = (await r.watchTasks(day).first).firstWhere((StudyTask t) => t.id == 'a');
      await r.saveSessionWithBreak(
          session: a.copyWith(title: 'A renamed', durationMinutes: 90), breakId: 'ba');
      expect((await timeline(r)).map(line).toList(), <String>[
        'S A renamed 540-630',
        'S B 630-690',
      ]);
    });

    test('turning the break off removes it; changing its length moves it', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveSessionWithBreak(
          session: session('s1', 'Maths', start: 9 * h, duration: h), breakId: 'b1', breakMinutes: 10);
      await r.saveSessionWithBreak(
          session: session('s1', 'Maths', start: 9 * h, duration: h), breakId: 'b1', breakMinutes: 20);
      expect((await timeline(r)).map(line).toList(), <String>['S Maths 540-600', 'B Break 600-620']);
      await r.saveSessionWithBreak(
          session: session('s1', 'Maths', start: 9 * h, duration: h), breakId: 'b1');
      expect((await timeline(r)).map(line).toList(), <String>['S Maths 540-600']);
    });

    test('a session without a time is saved and gets no break', () async {
      final StudyHubRepositoryImpl r = await repo();
      final StudyTask saved = await r.saveSessionWithBreak(
          session: session('s1', 'Read news'), breakId: 'b1', breakMinutes: 10);
      expect(saved.startMinute, isNull);
      expect(await timeline(r), hasLength(1));
    });

    test('slow reminder rescheduling never blocks saving', () async {
      final Completer<void> never = Completer<void>();
      int calls = 0;
      final StudyHubRepositoryImpl r = await repo(onChanged: () {
        calls++;
        return never.future;
      });
      await r
          .saveSessionWithBreak(
              session: session('s1', 'Maths', duration: h, auto: true), breakId: 'b1', breakMinutes: 10)
          .timeout(const Duration(seconds: 5));
      expect(calls, 1);
    });

    test('a failing reminder refresh never breaks saving', () async {
      final StudyHubRepositoryImpl r = await repo(onChanged: () async => throw StateError('boom'));
      await r.saveSessionWithBreak(
          session: session('s1', 'Maths', duration: h, auto: true), breakId: 'b1');
      expect(await timeline(r), hasLength(1));
    });
  });

  group('saveSessionAsBlocks (Pomodoro)', () {
    test('2 hours of 50 + 10: focus blocks and breaks are chained', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveSessionAsBlocks(
          session: session('s1', 'Maths', start: 9 * h, duration: 2 * h),
          focusMinutes: 50, breakMinutes: 10);
      expect((await timeline(r)).map(line).toList(), <String>[
        'S Maths 540-590',
        'B Break 590-600',
        'S Maths 600-650',
        'B Break 650-660',
        'S Maths 660-680',
      ]);
    });

    test('automatic start goes after the previous item (or 09:00 on an empty day)', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveSessionAsBlocks(
          session: session('s1', 'Maths', duration: 60, auto: true), focusMinutes: 25, breakMinutes: 5);
      expect((await timeline(r)).first.startMinute, 9 * h);
      await r.saveSessionAsBlocks(
          session: session('s2', 'English', duration: 50, auto: true), focusMinutes: 50, breakMinutes: 10);
      final List<StudyTask> t = await timeline(r);
      // Maths: 25 b5 25 b5 10 -> ends 09:00 + 70 = 10:10; English starts there.
      expect(t.where((StudyTask x) => x.subject == 'English').single.startMinute, 10 * h + 10);
    });

    test('saving again replaces the blocks (no duplicates), even with a new plan', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveSessionAsBlocks(
          session: session('s1', 'Maths', start: 9 * h, duration: 2 * h), focusMinutes: 50, breakMinutes: 10);
      await r.saveSessionAsBlocks(
          session: session('s1', 'Maths', start: 9 * h, duration: 2 * h), focusMinutes: 50, breakMinutes: 10);
      expect(await timeline(r), hasLength(5));
      await r.saveSessionAsBlocks(
          session: session('s1', 'Maths', start: 9 * h, duration: h), focusMinutes: 50, breakMinutes: 10);
      expect((await timeline(r)).map(line).toList(), <String>['S Maths 540-590', 'B Break 590-600', 'S Maths 600-610']);
    });

    test('an overlap or running past midnight saves nothing', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveTask(session('fixed', 'Chemistry', start: 10 * h, duration: h));
      await expectLater(
        r.saveSessionAsBlocks(
            session: session('s1', 'Maths', start: 9 * h, duration: 2 * h), focusMinutes: 50, breakMinutes: 10),
        throwsA(isA<StudyScheduleOverlapException>()),
      );
      await expectLater(
        r.saveSessionAsBlocks(
            session: session('s2', 'Maths', start: 23 * h, duration: 2 * h), focusMinutes: 50, breakMinutes: 10),
        throwsA(isA<StudyScheduleInvalidTimeException>()),
      );
      await expectLater(
        r.saveSessionAsBlocks(session: session('s3', 'Maths', duration: h), focusMinutes: 50, breakMinutes: 10),
        throwsA(isA<StudyScheduleInvalidTimeException>()),
      );
      expect((await timeline(r)).map((StudyTask t) => t.id).toList(), <String>['fixed']);
    });

    test('a session shorter than one block stays a single session', () async {
      final StudyHubRepositoryImpl r = await repo();
      await r.saveSessionAsBlocks(
          session: session('s1', 'Maths', start: 9 * h, duration: 30), focusMinutes: 50, breakMinutes: 10);
      expect((await timeline(r)).map(line).toList(), <String>['S Maths 540-570']);
    });
  });
}

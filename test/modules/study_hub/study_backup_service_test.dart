import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/study_hub/data/datasources/study_hub_local_data_source.dart';
import 'package:lexiora/modules/study_hub/data/repositories/study_hub_repository_impl.dart';
import 'package:lexiora/modules/study_hub/data/services/study_backup_service.dart';
import 'package:lexiora/modules/study_hub/data/services/study_export_service.dart';

void main() {
  late AppDatabase db;
  late StudyHubRepositoryImpl repo;
  const StudyBackupService service =
      StudyBackupService(StudyExportService());

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StudyHubRepositoryImpl(StudyHubLocalDataSource(db));
  });

  tearDown(() => db.close());

  test('imports a single-day CSV onto the explicitly chosen target day', () async {
    const String csv = '''
Date,Type,Subject,Topic,Start,End,Priority,Status,Notes
2026-11-22,Session,English,Grammar,9:00 AM,9:50 AM,High,Pending,Review
2026-11-22,Break,Break,,9:50 AM,10:00 AM,Medium,,
''';

    final List<int> bytes = utf8.encode(csv);
    expect(service.csvDates(bytes), <String>{'2026-11-22'});

    final int count = await service.importCsv(
      repo,
      bytes,
      targetDay: '2026-11-25',
    );

    expect(count, 2);
    expect(await repo.watchTasks('2026-11-22').first, isEmpty);

    final rows = await repo.watchTasks('2026-11-25').first;
    expect(rows, hasLength(2));
    expect(rows.map((r) => r.day), everyElement('2026-11-25'));
    expect(rows.first.startMinute, 9 * 60);
    expect(rows.first.endMinute, 9 * 60 + 50);
  });

  test('imports today plan from the current time and preserves breaks', () async {
    const String csv = '''
Date,Type,Subject,Topic,Start,End,Priority,Status,Notes
2026-11-22,Session,English,Grammar,9:00 AM,9:50 AM,High,Pending,Review
2026-11-22,Break,Break,,9:50 AM,10:00 AM,Medium,,
2026-11-22,Session,Newspaper,Opinion,10:00 AM,10:50 AM,Medium,Pending,Read
2026-11-22,Break,Break,,10:50 AM,11:00 AM,Medium,,
''';

    final int count = await service.importCsv(
      repo,
      utf8.encode(csv),
      targetDay: '2026-11-22',
      nowMinute: 11 * 60 + 11,
    );

    expect(count, 4);
    final rows = await repo.watchTasks('2026-11-22').first;
    expect(
      rows.map((r) => (r.isBreak ? 'B ' : 'S ') +
          r.startMinute.toString() + '-' + r.endMinute.toString()).toList(),
      <String>[
        'S 671-721',
        'B 721-731',
        'S 731-781',
        'B 781-791',
      ],
    );
  });

  test('keeps the CSV date when no target day is selected', () async {
    const String csv = '''
Date,Type,Subject,Topic,Start,End,Priority,Status,Notes
2026-11-22,Session,English,Grammar,9:00 AM,9:50 AM,High,Pending,Review
''';

    final int count = await service.importCsv(repo, utf8.encode(csv));

    expect(count, 1);
    final rows = await repo.watchTasks('2026-11-22').first;
    expect(rows, hasLength(1));
    expect(rows.single.day, '2026-11-22');
  });
}

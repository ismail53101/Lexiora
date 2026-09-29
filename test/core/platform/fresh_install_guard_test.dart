import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/platform/fresh_install_guard.dart';

/// Data-level regression tests for the FreshInstallGuard: a database restored
/// by Android's auto-backup must have its AI chat rows purged, while real user
/// data on in-place updates (and pre-feature installs) must never be touched.
void main() {
  late AppDatabase db;
  late Directory cacheDir;
  late DateTime installTime;

  FreshInstallGuard buildGuard() => FreshInstallGuard(
        firstInstallTime: () async => installTime,
        cacheDir: () async => cacheDir,
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    cacheDir = await Directory.systemTemp.createTemp('guard_test_');
    installTime = DateTime.now().subtract(const Duration(minutes: 5));
  });

  tearDown(() async {
    await db.close();
    await cacheDir.delete(recursive: true);
  });

  Future<void> seedChats() async {
    await db.into(db.aiConversations).insert(
          AiConversationsCompanion.insert(
            id: 'conv-1',
            title: 'hi',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
    await db.into(db.aiMessages).insert(
          AiMessagesCompanion.insert(
            id: 'msg-1',
            conversationId: 'conv-1',
            role: 1,
            content: 'Yes, you absolutely can qualify…',
            createdAt: DateTime(2026),
          ),
        );
    await db.into(db.aiProjects).insert(
          AiProjectsCompanion.insert(
            id: 'proj-1',
            name: 'Stale project',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
  }

  Future<int> conversationCount() async {
    final count = db.aiConversations.id.count();
    final query = db.selectOnly(db.aiConversations)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> messageCount() async {
    final count = db.aiMessages.id.count();
    final query = db.selectOnly(db.aiMessages)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> projectCount() async {
    final count = db.aiProjects.id.count();
    final query = db.selectOnly(db.aiProjects)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  test('purges restored chat data on a fresh install', () async {
    // A backup-restored database already contains the stale chats, but no
    // marker (the marker ships with this feature) and no sentinel (cache is
    // never restored).
    await seedChats();

    final bool purged = await buildGuard().purgeStaleChatData(db);

    expect(purged, isTrue);
    expect(await conversationCount(), 0);
    expect(await messageCount(), 0);
    expect(await projectCount(), 0);
  });

  test('never touches real chats on an in-place update', () async {
    // First launch of the current install: seeds the markers.
    await buildGuard().purgeStaleChatData(db);

    // The user's real data, created after that first launch.
    await seedChats();

    // A later launch (e.g. after an app update — same app-data directory,
    // same cache, marker present).
    final bool purged = await buildGuard().purgeStaleChatData(db);

    expect(purged, isFalse);
    expect(await conversationCount(), 1);
    expect(await messageCount(), 1);
    expect(await projectCount(), 1);
  });

  test('keeps data on a pre-feature install (old install time)', () async {
    await seedChats();
    installTime = DateTime.now().subtract(const Duration(days: 30));

    final bool purged = await buildGuard().purgeStaleChatData(db);

    expect(purged, isFalse);
    expect(await conversationCount(), 1);
    expect(await messageCount(), 1);
    expect(await projectCount(), 1);
  });

  test('keeps data when the sentinel survives but the marker does not',
      () async {
    // Same-installation signal via cache sentinel alone (e.g. the marker row
    // was written, then the user's settings table was somehow reset).
    final File sentinel =
        File('${cacheDir.path}/fresh_install.sentinel');
    await sentinel.writeAsString('present');

    await seedChats();
    final bool purged = await buildGuard().purgeStaleChatData(db);

    expect(purged, isFalse);
    expect(await conversationCount(), 1);
    expect(await messageCount(), 1);
  });

  test('purged data stays purged on the next launch', () async {
    await seedChats();
    final FreshInstallGuard guard = buildGuard();
    await guard.purgeStaleChatData(db);
    await guard.purgeStaleChatData(db);

    expect(await conversationCount(), 0);
    expect(await messageCount(), 0);
  });
}

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Data-level guard against chat data that Android's auto-backup restored
/// into a fresh installation, so Recents always starts empty after a
/// reinstall (the stale rows are deleted from the database itself — never
/// merely hidden in the UI).
///
/// Why this is needed: the manifest declares no backup exclusions, so Android
/// silently backs up the whole app-data directory — including the SQLite
/// database that stores AI chats — and restores it when the app is
/// reinstalled. That restored database is exactly where a stale "hi" chat can
/// reappear under Recents on a "fresh" install.
///
/// Detecting a restore (vs. a normal update) without ever touching real user
/// data on updates uses two independent markers:
///
/// 1. **Install-time marker inside the database** (`settings` table). It is
///    written once and lives in the very file Android restores. If the app
///    updates in place, the marker is still there → real user data, never
///    touched.
/// 2. **Cache-dir sentinel file.** The cache directory is excluded from
///    auto-backup, so it is wiped on uninstall and never restored. If the
///    sentinel exists, the current app-data directory is the *same
///    installation* that wrote the marker — an in-place update (or a normal
///    restart), not a restore.
///
/// A purge happens only when **both** signals say "restored": the database
/// carries no marker AND the sentinel is missing, corroborated by a recent
/// OS install time. Everything else — true first installs (empty database
/// anyway) and every in-place update (marker + sentinel present) — is left
/// completely untouched.
class FreshInstallGuard {
  FreshInstallGuard({
    Future<DateTime?> Function()? firstInstallTime,
    Future<Directory> Function()? cacheDir,
    DateTime Function()? now,
  })  : _firstInstallTime = firstInstallTime ?? _defaultFirstInstallTime,
        _cacheDir = cacheDir ?? _defaultCacheDir,
        _now = now ?? DateTime.now;

  static final FreshInstallGuard instance = FreshInstallGuard();

  static const String _markerKey = 'fresh_install_marker_v1';
  static const String _sentinelName = 'fresh_install.sentinel';

  static const MethodChannel _channel = MethodChannel('lexiora/platform');

  /// OS install time of the current build (null off-Android or on failure).
  static Future<DateTime?> _defaultFirstInstallTime() async {
    if (!Platform.isAndroid) return null;
    try {
      final int? ms = await _channel.invokeMethod<int>('getFirstInstallTime');
      if (ms == null || ms <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } on Object {
      return null;
    }
  }

  static Future<Directory> _defaultCacheDir() => getTemporaryDirectory();

  final Future<DateTime?> Function() _firstInstallTime;
  final Future<Directory> Function() _cacheDir;
  final DateTime Function() _now;

  /// OS install times this recent corroborate a genuine fresh install.
  static const Duration _freshInstallWindow = Duration(hours: 6);

  /// Runs the guard once per launch. Returns true when a restored database
  /// was detected and the stale AI chat rows were deleted. Never throws —
  /// any failure is logged and treated as "nothing to do" so startup is
  /// never blocked by this check.
  Future<bool> purgeStaleChatData(AppDatabase db) async {
    try {
      final Directory cache = await _cacheDir();
      final File sentinel = File('${cache.path}/$_sentinelName');
      final bool hasSentinel = await sentinel.exists();

      final DateTime? firstInstall = await _firstInstallTime();
      final bool installTimeIsRecent = firstInstall != null &&
          _now().difference(firstInstall) < _freshInstallWindow;

      final bool markerPresent = await _readMarker(db);
      final bool restored = !markerPresent && !hasSentinel;

      if (!restored) {
        // Same installation (or a genuine first run): ensure the marker
        // exists so future updates can never be mistaken for restores.
        if (!markerPresent) await _writeMarker(db);
        await _ensureSentinel(sentinel);
        return false;
      }

      if (firstInstall != null && !installTimeIsRecent) {
        // Database has no marker but the OS says this is not a recent
        // install — e.g. the very first launch right after this feature
        // shipped. Treat as a pre-feature install: seed the markers and
        // keep every existing row.
        AppLogger.i(
          'FreshInstallGuard: no marker, but install is not recent — '
          'treating as pre-feature install; seeding markers only.',
        );
        await _writeMarker(db);
        await _ensureSentinel(sentinel);
        return false;
      }

      AppLogger.i(
        'FreshInstallGuard: restored database detected — purging AI chats.',
      );
      await db.batch((Batch batch) {
        batch.deleteWhere(db.aiMessages, (_) => const Constant(true));
        batch.deleteWhere(db.aiConversations, (_) => const Constant(true));
        batch.deleteWhere(db.aiProjects, (_) => const Constant(true));
      });
      await _writeMarker(db);
      await _ensureSentinel(sentinel);
      return true;
    } on Object catch (e, st) {
      AppLogger.e('FreshInstallGuard failed', error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool> _readMarker(AppDatabase db) async {
    final List<SettingRow> rows =
        await (db.select(db.settings)..where((t) => t.key.equals(_markerKey)))
            .get();
    return rows.isNotEmpty;
  }

  Future<void> _writeMarker(AppDatabase db) async {
    await db.into(db.settings).insertOnConflictUpdate(
          const SettingsCompanion(
            key: Value(_markerKey),
            value: Value<String>('1'),
          ),
        );
  }

  Future<void> _ensureSentinel(File sentinel) async {
    try {
      if (!await sentinel.exists()) {
        await sentinel.writeAsString(DateTime.now().toIso8601String());
      }
    } on Object {
      // A read-only cache dir must never block the purge itself.
    }
  }
}

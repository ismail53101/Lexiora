import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Snapshot of the AI allowance that survives app restarts.
@immutable
class AiUsageSnapshot {
  const AiUsageSnapshot({required this.remaining, this.exhaustedAt});

  final int remaining;

  /// When the allowance hit zero (starts the 1-hour refill clock).
  final DateTime? exhaustedAt;
}

/// Tiny JSON-file store for the AI allowance. Persisting it means closing and
/// reopening the app does not hand out a free batch of searches, and the
/// 1-hour refill clock keeps running while the app is closed.
class AiUsageStore {
  AiUsageStore({Future<Directory> Function()? directory})
      : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  Future<File> _file() async =>
      File(p.join((await _directory()).path, 'ai_usage.json'));

  Future<AiUsageSnapshot?> read() async {
    try {
      final File f = await _file();
      if (!await f.exists()) return null;
      final Object? raw = jsonDecode(await f.readAsString());
      if (raw is! Map) return null;
      final Object? remaining = raw['remaining'];
      final Object? exhausted = raw['exhaustedAtMs'];
      if (remaining is! int) return null;
      return AiUsageSnapshot(
        remaining: remaining,
        exhaustedAt: exhausted is int
            ? DateTime.fromMillisecondsSinceEpoch(exhausted)
            : null,
      );
    } on Object catch (error) {
      AppLogger.w('AI usage read failed; starting fresh: $error');
      return null;
    }
  }

  Future<void> write(AiUsageSnapshot snapshot) async {
    try {
      final File f = await _file();
      await f.writeAsString(
        jsonEncode(<String, Object?>{
          'remaining': snapshot.remaining,
          'exhaustedAtMs': snapshot.exhaustedAt?.millisecondsSinceEpoch,
        }),
        flush: true,
      );
    } on Object catch (error) {
      AppLogger.w('AI usage write failed: $error');
    }
  }
}
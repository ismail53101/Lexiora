import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, ByteData, rootBundle;
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/modules/translation/data/datasources/translation_local_data_source.dart';

/// Loads the bundled, gzip-compressed offline translation data into the
/// database on first use.
///
/// Mirrors the dictionary seeder's design: idempotent + deduped [ensureSeeded],
/// interruption-safe (clear-then-seed, version flag written only on success),
/// and memory-efficient streaming/batched inserts on the database isolate.
class TranslationSeeder {
  TranslationSeeder(this._local, {AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final TranslationLocalDataSource _local;
  final AssetBundle _bundle;

  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);
  Future<void>? _inFlight;

  Future<void> ensureSeeded() {
    final Future<void>? existing = _inFlight;
    if (existing != null) return existing;
    final Future<void> run = _run();
    _inFlight = run;
    unawaited(run.then<void>((_) {}, onError: (_, _) => _inFlight = null));
    return run;
  }

  Future<void> _run() async {
    try {
      final String? seeded = await _local.seededVersion();
      if (seeded == TranslationConstants.datasetVersion &&
          await _local.entryCount() > 0) {
        ready.value = true;
        return;
      }

      await _local.clearEntries();

      final ByteData data =
          await _bundle.load(TranslationConstants.assetPath);
      final Uint8List bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      int inserted = 0;
      final List<TranslationEntriesCompanion> batch =
          <TranslationEntriesCompanion>[];

      final Stream<String> lines = _chunk(bytes)
          .transform(gzip.decoder)
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final String line in lines) {
        if (line.isEmpty) continue;
        final Map<String, dynamic> o =
            json.decode(line) as Map<String, dynamic>;
        batch.add(
          TranslationEntriesCompanion.insert(
            langCode: o['l'] as String,
            wordLower: (o['w'] as String).toLowerCase(),
            translation: o['t'] as String,
          ),
        );
        if (batch.length >= TranslationConstants.seedBatchSize) {
          await _local.insertEntries(batch);
          inserted += batch.length;
          batch.clear();
        }
      }
      if (batch.isNotEmpty) {
        await _local.insertEntries(batch);
        inserted += batch.length;
      }

      await _local.setSeededVersion(TranslationConstants.datasetVersion);
      AppLogger.i('Translations seeded: $inserted entries');
      ready.value = true;
    } on Object catch (e, s) {
      AppLogger.e('Translation seed failed', error: e, stackTrace: s);
      rethrow;
    }
  }

  Stream<List<int>> _chunk(Uint8List bytes, [int size = 65536]) async* {
    for (int i = 0; i < bytes.length; i += size) {
      yield bytes.sublist(i, math.min(i + size, bytes.length));
    }
  }
}

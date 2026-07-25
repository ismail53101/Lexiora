import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, ByteData, rootBundle;
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/modules/dictionary/data/datasources/dictionary_local_data_source.dart';

/// Where the one-time seed currently is.
enum DictionarySeedPhase { idle, seeding, ready, error }

/// Snapshot of seeding progress, surfaced to the UI so the (one-time) first-run
/// import shows a real progress bar instead of an opaque spinner.
@immutable
class DictionarySeedStatus {
  const DictionarySeedStatus(
    this.phase, {
    this.progress = 0,
    this.inserted = 0,
    this.message,
  });

  final DictionarySeedPhase phase;
  final double progress; // 0..1 (approximate; based on an entry estimate)
  final int inserted;
  final String? message;

  bool get isReady => phase == DictionarySeedPhase.ready;
  bool get isSeeding => phase == DictionarySeedPhase.seeding;
  bool get isError => phase == DictionarySeedPhase.error;
}

/// Loads the bundled, gzip-compressed JSON-Lines dictionary into the database
/// on first launch.
///
/// Design notes:
///  * **Idempotent & deduped** — [ensureSeeded] returns a single shared future,
///    so the page and the reader popup can both call it without double-seeding.
///  * **Interruption-safe** — the entries table is cleared before seeding and a
///    version flag is written only on success, so a killed first run simply
///    re-seeds cleanly next time.
///  * **Memory-efficient** — the asset is streamed through the gzip/utf8/line
///    decoders in small chunks and inserted in batches, so peak memory stays
///    low even for 150k+ rows. Favorites live in a separate table and are never
///    touched here.
class DictionarySeeder {
  DictionarySeeder(this._local, {AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final DictionaryLocalDataSource _local;
  final AssetBundle _bundle;

  /// Rough entry count of the bundled set, used only for the progress %.
  static const int _estimatedEntries = 163201;

  final ValueNotifier<DictionarySeedStatus> status =
      ValueNotifier<DictionarySeedStatus>(
    const DictionarySeedStatus(DictionarySeedPhase.idle),
  );

  Future<void>? _inFlight;

  /// Ensures the dictionary is seeded. Safe to call repeatedly and concurrently.
  Future<void> ensureSeeded() {
    final Future<void>? existing = _inFlight;
    if (existing != null) return existing;
    final Future<void> run = _run();
    _inFlight = run;
    // Allow a retry after a failure, while still propagating the error to the
    // current awaiters.
    unawaited(run.then<void>((_) {}, onError: (_, _) => _inFlight = null));
    return run;
  }

  Future<void> _run() async {
    try {
      final String? seeded = await _local.seededVersion();
      if (seeded == DictionaryConstants.datasetVersion &&
          await _local.entryCount() > 0) {
        status.value = const DictionarySeedStatus(
          DictionarySeedPhase.ready,
          progress: 1,
        );
        return;
      }

      status.value = const DictionarySeedStatus(
        DictionarySeedPhase.seeding,
        message: 'Preparing dictionary…',
      );

      // Clear any partial/old data (favorites are in a separate table).
      await _local.clearEntries();

      final ByteData data =
          await _bundle.load(DictionaryConstants.assetPath);
      final Uint8List bytes = data.buffer
          .asUint8List(data.offsetInBytes, data.lengthInBytes);

      int inserted = 0;
      final List<DictionaryEntriesCompanion> batch =
          <DictionaryEntriesCompanion>[];

      final Stream<String> lines = _chunk(bytes)
          .transform(gzip.decoder)
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final String line in lines) {
        if (line.isEmpty) continue;
        final Map<String, dynamic> o =
            json.decode(line) as Map<String, dynamic>;
        final String word = o['w'] as String;
        batch.add(
          DictionaryEntriesCompanion.insert(
            word: word,
            wordLower: word.toLowerCase(),
            meaning: o['m'] as String,
            partOfSpeech: Value<String?>(o['p'] as String?),
            exampleSentence: Value<String?>(o['e'] as String?),
          ),
        );
        if (batch.length >= DictionaryConstants.seedBatchSize) {
          await _local.insertEntries(batch);
          inserted += batch.length;
          batch.clear();
          _emitProgress(inserted);
        }
      }
      if (batch.isNotEmpty) {
        await _local.insertEntries(batch);
        inserted += batch.length;
      }

      await _local.setSeededVersion(DictionaryConstants.datasetVersion);
      AppLogger.i('Dictionary seeded: $inserted entries');
      status.value = DictionarySeedStatus(
        DictionarySeedPhase.ready,
        progress: 1,
        inserted: inserted,
      );
    } on Object catch (e, s) {
      AppLogger.e('Dictionary seed failed', error: e, stackTrace: s);
      status.value = const DictionarySeedStatus(
        DictionarySeedPhase.error,
        message: 'Could not prepare the dictionary.',
      );
      rethrow;
    }
  }

  void _emitProgress(int inserted) {
    status.value = DictionarySeedStatus(
      DictionarySeedPhase.seeding,
      progress: (inserted / _estimatedEntries).clamp(0.0, 0.99),
      inserted: inserted,
      message: 'Preparing dictionary…',
    );
  }

  /// Emits [bytes] in small chunks so the decoders produce output progressively
  /// and stream back-pressure keeps peak memory bounded during seeding.
  Stream<List<int>> _chunk(Uint8List bytes, [int size = 65536]) async* {
    for (int i = 0; i < bytes.length; i += size) {
      yield bytes.sublist(i, math.min(i + size, bytes.length));
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, AssetManifest, ByteData, rootBundle;
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
      // Extra packs: every `*.json` under assets/translations/ is merged after
      // the base gz (CMS-ready — drop a file in and rebuild to expand the
      // offline set; the version below is a content signature, so a new or
      // edited pack re-seeds automatically). Base gz rows always win on a
      // (lang, word) collision so curated entries are never overridden.
      final Map<String, String> packs = await _loadPacks(await _safeListPacks());
      final String desiredVersion = _versionFor(packs);

      final String? seeded = await _local.seededVersion();
      if (seeded == desiredVersion && await _local.entryCount() > 0) {
        ready.value = true;
        return;
      }

      await _local.clearEntries();

      final ByteData data =
          await _bundle.load(TranslationConstants.assetPath);
      final Uint8List bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      int inserted = 0;
      final Set<String> seenKeys = <String>{};
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
        final String lang = o['l'] as String;
        final String wl = (o['w'] as String).toLowerCase();
        seenKeys.add('$lang\u0000$wl');
        batch.add(
          TranslationEntriesCompanion.insert(
            langCode: lang,
            wordLower: wl,
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

      // Merge extra packs: only rows whose (lang, word) is not already present.
      for (final String raw in packs.values) {
        final Object? decoded = jsonDecode(raw);
        if (decoded is! List) continue;
        for (final Object? entry in decoded) {
          if (entry is! Map<String, dynamic>) continue;
          final Object? l = entry['l'];
          final Object? w = entry['w'];
          final Object? t = entry['t'];
          if (l is! String || w is! String || t is! String) continue;
          final String wl = w.trim().toLowerCase();
          if (wl.isEmpty || t.trim().isEmpty) continue;
          if (!seenKeys.add('$l\u0000$wl')) continue;
          batch.add(
            TranslationEntriesCompanion.insert(
              langCode: l,
              wordLower: wl,
              translation: t.trim(),
            ),
          );
          if (batch.length >= TranslationConstants.seedBatchSize) {
            await _local.insertEntries(batch);
            inserted += batch.length;
            batch.clear();
          }
        }
      }
      if (batch.isNotEmpty) {
        await _local.insertEntries(batch);
        inserted += batch.length;
      }

      await _local.setSeededVersion(desiredVersion);
      AppLogger.i('Translations seeded: $inserted entries'
          ' (${packs.length} extra pack(s))');
      ready.value = true;
    } on Object catch (e, s) {
      AppLogger.e('Translation seed failed', error: e, stackTrace: s);
      rethrow;
    }
  }

  // ── Extra pack discovery / loading (CMS-ready) ──────────────────────────────

  Future<List<String>> _safeListPacks() async {
    try {
      final AssetManifest manifest =
          await AssetManifest.loadFromAssetBundle(_bundle);
      final List<String> packs = manifest
          .listAssets()
          .where((String key) =>
              key.startsWith(TranslationConstants.assetDir) &&
              key.toLowerCase().endsWith('.json'))
          .toList()
        ..sort();
      return packs;
    } on Object catch (e) {
      AppLogger.w('Translation: pack discovery failed ($e); no extra packs.');
      return const <String>[];
    }
  }

  Future<Map<String, String>> _loadPacks(List<String> paths) async {
    final Map<String, String> out = <String, String>{};
    for (final String path in paths) {
      try {
        out[path] = await _bundle.loadString(path);
      } on Object catch (e) {
        AppLogger.w('Translation: could not read pack "$path" ($e); skipped');
      }
    }
    return out;
  }

  /// Deterministic version = the manual dataset version plus a hash of every
  /// extra pack's path + bytes. Adding/editing/removing a pack re-seeds.
  String _versionFor(Map<String, String> packs) {
    final List<String> keys = packs.keys.toList()..sort();
    int hash = 0xcbf29ce484222325; // FNV-1a 64-bit basis
    const int prime = 0x100000001b3;
    void mix(String s) {
      for (final int b in utf8.encode(s)) {
        hash ^= b;
        hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
      }
    }

    for (final String k in keys) {
      mix(k);
      mix('\u0000');
      mix(packs[k]!);
      mix('\u0001');
    }
    final String sig = hash.toUnsigned(64).toRadixString(16);
    return '${TranslationConstants.datasetVersion}#packs-${keys.length}-$sig';
  }

  Stream<List<int>> _chunk(Uint8List bytes, [int size = 65536]) async* {
    for (int i = 0; i < bytes.length; i += size) {
      yield bytes.sublist(i, math.min(i + size, bytes.length));
    }
  }
}

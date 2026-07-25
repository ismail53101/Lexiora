import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, AssetManifest, rootBundle;
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/modules/dictionary/data/datasources/dictionary_local_data_source.dart';

/// Signature of the function used to discover the curated word-pack asset paths.
/// Injectable so tests can provide a fixed list without a real asset manifest.
typedef DictionaryPackLister = Future<List<String>> Function(AssetBundle bundle);

/// Seeds the curated, exam-oriented word packs into `dictionary_exam_entries`
/// (Dictionary v2).
///
/// ## Data-driven, multi-pack loader (CMS-ready)
/// Instead of a single hard-coded file, this seeder **auto-discovers every
/// `*.json` file under `assets/dictionary/`** (via the Flutter asset manifest),
/// then **merges them into one searchable table**. To add thousands of new
/// curated words later you only:
///   1. drop one or more `*.json` files into `assets/dictionary/`, and
///   2. rebuild.
/// No Dart change is required — `pubspec.yaml` already declares the
/// `assets/dictionary/` directory, so new files are bundled automatically, and
/// the seed version is derived from the packs' **content signature** so a new
/// or edited pack re-seeds on next launch on its own.
///
/// Each pack is a JSON array of entries following the existing
/// `DictionaryEntry`/exam schema (an object with a `word` plus the rich body).
/// Entries are keyed by lowercased headword; if two packs define the same word,
/// the later pack (alphabetical by path) wins.
///
/// ## Guarantees
/// * **Non-destructive** — only the curated `dictionary_exam_entries` table is
///   (re)built. Favorites, search history, progress, the base dictionary
///   (`wordset.jsonl.gz`, seeded separately) and translations are never touched.
/// * **Crash-proof** — a missing manifest, a missing file, or a malformed pack
///   is logged and skipped; the rest still load. If nothing loads, existing
///   data is left intact.
/// * **Idempotent & deduped** — [ensureSeeded] shares a single in-flight future;
///   re-seeding only runs when the discovered packs' content signature changes.
class ExamWordsSeeder {
  ExamWordsSeeder(
    this._local, {
    AssetBundle? bundle,
    DictionaryPackLister? listPacks,
  })  : _bundle = bundle ?? rootBundle,
        _listPacks = listPacks ?? _discoverPacks;

  final DictionaryLocalDataSource _local;
  final AssetBundle _bundle;
  final DictionaryPackLister _listPacks;

  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);
  Future<void>? _inFlight;

  /// Ensures the curated packs are seeded. Safe to call repeatedly/concurrently.
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
      // 1) Discover pack paths and load their raw contents (resilient).
      final List<String> paths = await _safeListPacks();
      final Map<String, String> packs = await _loadPacks(paths);

      if (packs.isEmpty) {
        // Nothing to seed (no packs bundled, or all unreadable). Do NOT clear
        // existing data — just report readiness based on what's already there.
        AppLogger.w('Exam dictionary: no curated packs found under '
            '${ExamDictionaryConstants.assetDir}; leaving existing data intact.');
        ready.value = await _local.examCount() > 0;
        return;
      }

      // 2) Version gate: re-seed only when the packs' content changed. The
      //    signature covers every pack's path + bytes, so adding, removing or
      //    editing a file all trigger a re-seed with no code change.
      final String desiredVersion = _versionFor(packs);
      final String? seeded = await _local.examSeededVersion();
      if (seeded == desiredVersion && await _local.examCount() > 0) {
        ready.value = true;
        return;
      }

      // 3) Parse + merge all packs (dedup by lowercased headword; later wins).
      final Map<String, DictionaryExamEntriesCompanion> merged =
          <String, DictionaryExamEntriesCompanion>{};
      int files = 0;
      for (final MapEntry<String, String> pack in packs.entries) {
        final int added = _mergePack(pack.key, pack.value, merged);
        if (added >= 0) files++;
      }

      // 4) Rebuild the curated table from the merged set.
      await _local.clearExamEntries();
      int inserted = 0;
      final List<DictionaryExamEntriesCompanion> batch =
          <DictionaryExamEntriesCompanion>[];
      for (final DictionaryExamEntriesCompanion c in merged.values) {
        batch.add(c);
        if (batch.length >= ExamDictionaryConstants.seedBatchSize) {
          await _local.insertExamEntries(batch);
          inserted += batch.length;
          batch.clear();
        }
      }
      if (batch.isNotEmpty) {
        await _local.insertExamEntries(batch);
        inserted += batch.length;
      }

      await _local.setExamSeededVersion(desiredVersion);
      AppLogger.i('Exam dictionary seeded: $inserted words from $files pack(s)');
      ready.value = true;
    } on Object catch (e, s) {
      AppLogger.e('Exam dictionary seed failed', error: e, stackTrace: s);
      // Non-fatal: the base dictionary + hybrid translation still work; the
      // curated pack simply won't be (fully) available this run.
      ready.value = false;
      rethrow;
    }
  }

  // ── Discovery ──────────────────────────────────────────────────────────────

  Future<List<String>> _safeListPacks() async {
    try {
      final List<String> paths = await _listPacks(_bundle);
      if (paths.isNotEmpty) return paths;
    } on Object catch (e) {
      AppLogger.w('Exam dictionary: pack discovery failed ($e); '
          'falling back to ${ExamDictionaryConstants.assetPath}');
    }
    // Fallback to the known curated file so the feature works even if the asset
    // manifest is unavailable (e.g. some test bundles).
    return <String>[ExamDictionaryConstants.assetPath];
  }

  /// Default production discovery: every `assets/dictionary/*.json` asset.
  static Future<List<String>> _discoverPacks(AssetBundle bundle) async {
    final AssetManifest manifest =
        await AssetManifest.loadFromAssetBundle(bundle);
    final List<String> packs = manifest
        .listAssets()
        .where((String key) =>
            key.startsWith(ExamDictionaryConstants.assetDir) &&
            key.toLowerCase().endsWith(ExamDictionaryConstants.packSuffix))
        .toList()
      ..sort(); // deterministic merge order
    return packs;
  }

  /// Loads each pack's raw text, skipping any that fail to read.
  Future<Map<String, String>> _loadPacks(List<String> paths) async {
    final Map<String, String> out = <String, String>{};
    for (final String path in paths) {
      try {
        out[path] = await _bundle.loadString(path);
      } on Object catch (e) {
        AppLogger.w('Exam dictionary: could not read pack "$path" ($e); skipped');
      }
    }
    return out;
  }

  // ── Parsing / merging ───────────────────────────────────────────────────────

  /// Parses one pack and merges its entries into [into].
  /// Returns the number of entries added (>= 0), or -1 if the pack was invalid.
  int _mergePack(
    String path,
    String raw,
    Map<String, DictionaryExamEntriesCompanion> into,
  ) {
    late final List<dynamic> data;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        AppLogger.w('Exam dictionary: pack "$path" is not a JSON array; skipped');
        return -1;
      }
      data = decoded;
    } on Object catch (e) {
      AppLogger.w('Exam dictionary: pack "$path" is not valid JSON ($e); skipped');
      return -1;
    }

    int added = 0;
    for (final dynamic entry in data) {
      if (entry is! Map<String, dynamic>) continue;
      final String word = (entry['word'] as String?)?.trim() ?? '';
      if (word.isEmpty) continue;
      into[word.toLowerCase()] = DictionaryExamEntriesCompanion.insert(
        wordLower: word.toLowerCase(),
        word: word,
        contentJson: jsonEncode(entry),
      );
      added++;
    }
    return added;
  }

  // ── Content signature (drives the version gate) ─────────────────────────────

  /// A deterministic version string = the manual dataset version plus a hash of
  /// every pack's path and bytes. Any pack added/removed/edited changes it.
  String _versionFor(Map<String, String> packs) {
    final List<String> keys = packs.keys.toList()..sort();
    int hash = 0xcbf29ce484222325; // 64-bit FNV-1a offset basis
    const int prime = 0x100000001b3;
    void mix(String s) {
      for (final int b in utf8.encode(s)) {
        hash ^= b;
        hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
      }
    }

    for (final String k in keys) {
      mix(k);
      mix(' ');
      mix(packs[k]!);
      mix('');
    }
    final String sig = hash.toUnsigned(64).toRadixString(16);
    return '${ExamDictionaryConstants.datasetVersion}#packs-${keys.length}-$sig';
  }
}

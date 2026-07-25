import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, AssetManifest, rootBundle;
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/modules/vocabulary/data/datasources/vocabulary_local_data_source.dart';

/// Discovers the vocabulary pack asset paths. Injectable for deterministic tests.
typedef VocabularyPackLister = Future<List<String>> Function(AssetBundle bundle);

/// Seeds vocabulary lists + words from bundled JSON packs (Phase v0.6.0).
///
/// ## Data-driven, multi-pack loader (CMS-ready)
/// Auto-discovers **every `assets/vocabulary/*.json` pack** (one pack per list)
/// via the Flutter asset manifest and merges them. To add a list later — GRE,
/// Oxford 3000, IELTS, … — drop a new `*.json` pack in and rebuild: no Dart
/// change (the directory is declared in pubspec and the seed version is a
/// content signature, so new/edited packs re-seed automatically on next launch).
///
/// A pack has the shape:
/// ```json
/// { "list": {"id":"general","title":"General Vocabulary","subtitle":"…","order":1},
///   "words": [ {"word":"Abandon","ipa":"/əˈbændən/","urdu":"ترک کرنا",
///               "meaning":"to give up completely","pos":"verb"} ] }
/// ```
///
/// Guarantees: **non-destructive** (only the two vocabulary tables are rebuilt),
/// **crash-proof** (a missing manifest / file / malformed pack is logged and
/// skipped; if nothing loads, existing data is left intact), and **idempotent**
/// (a shared in-flight future; re-seeds only when the content signature changes).
class VocabularySeeder {
  VocabularySeeder(
    this._local, {
    AssetBundle? bundle,
    VocabularyPackLister? listPacks,
  })  : _bundle = bundle ?? rootBundle,
        _listPacks = listPacks ?? _discoverPacks;

  final VocabularyLocalDataSource _local;
  final AssetBundle _bundle;
  final VocabularyPackLister _listPacks;

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
      final List<String> paths = await _safeListPacks();
      final Map<String, String> packs = await _loadPacks(paths);

      if (packs.isEmpty) {
        AppLogger.w('Vocabulary: no packs found under '
            '${VocabularyConstants.assetDir}; leaving existing data intact.');
        ready.value = await _local.wordCount() > 0;
        return;
      }

      final String desiredVersion = _versionFor(packs);
      final String? seeded = await _local.seededVersion();
      if (seeded == desiredVersion && await _local.wordCount() > 0) {
        ready.value = true;
        return;
      }

      // Merge every pack (later pack by path wins for a given list/word id).
      final Map<String, VocabularyListsCompanion> lists =
          <String, VocabularyListsCompanion>{};
      final Map<String, VocabularyWordsCompanion> words =
          <String, VocabularyWordsCompanion>{};
      for (final MapEntry<String, String> pack in packs.entries) {
        _mergePack(pack.key, pack.value, lists, words);
      }

      if (words.isEmpty) {
        AppLogger.w('Vocabulary: packs contained no valid words; '
            'leaving existing data intact.');
        ready.value = await _local.wordCount() > 0;
        return;
      }

      await _local.clearAll();
      await _local.insertLists(lists.values.toList(growable: false));
      await _insertWordsBatched(words.values.toList(growable: false));
      await _local.setSeededVersion(desiredVersion);
      AppLogger.i('Vocabulary seeded: ${words.length} words '
          'across ${lists.length} list(s)');
      ready.value = true;
    } on Object catch (e, s) {
      AppLogger.e('Vocabulary seed failed', error: e, stackTrace: s);
      ready.value = false;
      rethrow;
    }
  }

  Future<void> _insertWordsBatched(List<VocabularyWordsCompanion> all) async {
    final List<VocabularyWordsCompanion> batch = <VocabularyWordsCompanion>[];
    for (final VocabularyWordsCompanion c in all) {
      batch.add(c);
      if (batch.length >= VocabularyConstants.seedBatchSize) {
        await _local.insertWords(List<VocabularyWordsCompanion>.of(batch));
        batch.clear();
      }
    }
    if (batch.isNotEmpty) await _local.insertWords(batch);
  }

  // ── Discovery ──────────────────────────────────────────────────────────────

  Future<List<String>> _safeListPacks() async {
    try {
      return await _listPacks(_bundle);
    } on Object catch (e) {
      AppLogger.w('Vocabulary: pack discovery failed ($e); none loaded.');
      return const <String>[];
    }
  }

  static Future<List<String>> _discoverPacks(AssetBundle bundle) async {
    final AssetManifest manifest =
        await AssetManifest.loadFromAssetBundle(bundle);
    return manifest
        .listAssets()
        .where((String k) =>
            k.startsWith(VocabularyConstants.assetDir) &&
            k.toLowerCase().endsWith(VocabularyConstants.packSuffix))
        .toList()
      ..sort();
  }

  Future<Map<String, String>> _loadPacks(List<String> paths) async {
    final Map<String, String> out = <String, String>{};
    for (final String path in paths) {
      try {
        out[path] = await _bundle.loadString(path);
      } on Object catch (e) {
        AppLogger.w('Vocabulary: could not read pack "$path" ($e); skipped');
      }
    }
    return out;
  }

  // ── Parsing / merging ───────────────────────────────────────────────────────

  void _mergePack(
    String path,
    String raw,
    Map<String, VocabularyListsCompanion> lists,
    Map<String, VocabularyWordsCompanion> words,
  ) {
    Map<String, dynamic> obj;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        AppLogger.w('Vocabulary: pack "$path" is not a JSON object; skipped');
        return;
      }
      obj = decoded;
    } on Object catch (e) {
      AppLogger.w('Vocabulary: pack "$path" is not valid JSON ($e); skipped');
      return;
    }

    final Object? listRaw = obj['list'];
    final Object? wordsRaw = obj['words'];
    if (listRaw is! Map || wordsRaw is! List) {
      AppLogger.w('Vocabulary: pack "$path" missing list/words; skipped');
      return;
    }
    final String listId = (listRaw['id'] as String?)?.trim() ?? '';
    final String title = (listRaw['title'] as String?)?.trim() ?? '';
    if (listId.isEmpty || title.isEmpty) {
      AppLogger.w('Vocabulary: pack "$path" has no list id/title; skipped');
      return;
    }

    int count = 0;
    for (final Object? entry in wordsRaw) {
      if (entry is! Map) continue;
      final String word = (entry['word'] as String?)?.trim() ?? '';
      final String urdu = (entry['urdu'] as String?)?.trim() ?? '';
      final String meaning = (entry['meaning'] as String?)?.trim() ?? '';
      if (word.isEmpty || urdu.isEmpty || meaning.isEmpty) continue;
      final String lower = word.toLowerCase();
      final String id = '$listId/$lower';
      words[id] = VocabularyWordsCompanion.insert(
        id: id,
        listId: listId,
        word: word,
        wordLower: lower,
        letter: _letterOf(lower),
        urduMeaning: urdu,
        englishMeaning: meaning,
        ipa: Value<String?>(_nullTrim(entry['ipa'])),
        partOfSpeech: Value<String?>(_nullTrim(entry['pos'])),
        searchText: Value<String>('$lower $urdu'),
      );
      count++;
    }

    lists[listId] = VocabularyListsCompanion.insert(
      id: listId,
      title: title,
      subtitle: Value<String?>(_nullTrim(listRaw['subtitle'])),
      orderIndex: Value<int>((listRaw['order'] as num?)?.toInt() ?? 0),
      wordCount: Value<int>(count),
    );
  }

  static String _letterOf(String lower) {
    if (lower.isEmpty) return '#';
    final int c = lower.codeUnitAt(0);
    // a–z
    if (c >= 0x61 && c <= 0x7A) return String.fromCharCode(c - 32);
    return '#';
  }

  static String? _nullTrim(Object? v) {
    if (v == null) return null;
    final String s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  // ── Content signature (drives the version gate) ─────────────────────────────

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
      mix(' ');
      mix(packs[k]!);
      mix('');
    }
    final String sig = hash.toUnsigned(64).toRadixString(16);
    return '${VocabularyConstants.datasetVersion}#packs-${keys.length}-$sig';
  }
}

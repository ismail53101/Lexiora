import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/modules/grammar/data/datasources/grammar_local_data_source.dart';

/// Seeds the bundled Grammar tree (`grammar_topics.json`) into `grammar_topics`
/// once, on first use. Idempotent, interruption-safe, and non-destructive:
/// only the topics table is (re)built — progress and favorites are untouched.
class GrammarSeeder {
  GrammarSeeder(this._local, {AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final GrammarLocalDataSource _local;
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
      if (seeded == GrammarConstants.topicsDatasetVersion &&
          await _local.topicCount() > 0) {
        ready.value = true;
        return;
      }

      await _local.clearTopics();

      final String raw =
          await _bundle.loadString(GrammarConstants.topicsAssetPath);
      final List<dynamic> data = jsonDecode(raw) as List<dynamic>;

      final List<GrammarTopicsCompanion> batch = <GrammarTopicsCompanion>[];
      int inserted = 0;
      for (final dynamic entry in data) {
        if (entry is! Map<String, dynamic>) continue;
        final GrammarTopicsCompanion? c = _companionFrom(entry);
        if (c == null) continue;
        batch.add(c);
        if (batch.length >= 100) {
          await _local.insertTopics(batch);
          inserted += batch.length;
          batch.clear();
        }
      }
      if (batch.isNotEmpty) {
        await _local.insertTopics(batch);
        inserted += batch.length;
      }

      await _local.setSeededVersion(GrammarConstants.topicsDatasetVersion);
      AppLogger.i('Grammar tree seeded: $inserted nodes');
      ready.value = true;
    } on Object catch (e, s) {
      AppLogger.e('Grammar tree seed failed', error: e, stackTrace: s);
      ready.value = false;
      rethrow;
    }
  }

  GrammarTopicsCompanion? _companionFrom(Map<String, dynamic> o) {
    final String id = (o['id'] as String?)?.trim() ?? '';
    final String title = (o['title'] as String?)?.trim() ?? '';
    if (id.isEmpty || title.isEmpty) return null;

    final String? parentId = (o['parentId'] as String?)?.trim();
    final String? subtitle = (o['subtitle'] as String?)?.trim();
    final int order = (o['order'] as num?)?.toInt() ?? 0;
    final bool isLeaf = o['isLeaf'] == true;

    String? contentJson;
    final StringBuffer search = StringBuffer(title.toLowerCase());
    if (isLeaf && o['content'] is Map) {
      final Map<String, dynamic> content =
          (o['content'] as Map).cast<String, dynamic>();
      contentJson = jsonEncode(content);
      search
        ..write(' ')
        ..write((content['introduction']?.toString() ?? '').toLowerCase())
        ..write(' ')
        ..write((content['englishExplanation']?.toString() ?? '').toLowerCase());
    }
    final List<dynamic> keywords =
        (o['keywords'] as List<dynamic>?) ?? const <dynamic>[];
    if (keywords.isNotEmpty) {
      search
        ..write(' ')
        ..write(keywords.map((dynamic k) => k.toString()).join(' ').toLowerCase());
    }

    return GrammarTopicsCompanion.insert(
      id: id,
      title: title,
      parentId: Value<String?>(parentId),
      subtitle: Value<String?>(subtitle),
      orderIndex: Value<int>(order),
      isLeaf: Value<bool>(isLeaf),
      searchText: Value<String>(search.toString()),
      contentJson: Value<String?>(contentJson),
    );
  }
}

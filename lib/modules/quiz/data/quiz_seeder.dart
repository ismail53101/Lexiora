import 'dart:async';

import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/modules/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:lexiora/modules/quiz/data/providers/content_providers.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_subject.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_topic.dart';
import 'package:lexiora/modules/quiz/domain/quiz_json.dart';
import 'package:lexiora/modules/quiz/domain/repositories/question_provider.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_repository.dart';

/// Seeds the bundled exam question banks (assets/quiz/manifest.json) into the
/// normal quiz tables once, on first use.
///
/// Content lives as JSON bank files under `assets/quiz/` (see
/// [LocalJsonQuestionProvider] and [QuizJsonParser] for the schema). On the
/// first run after a [QuizConstants.datasetVersion] bump, the legacy demo rows
/// are removed and every bank listed in the manifest is imported through the
/// same `importPayload` path the Admin CMS uses, so everything stays editable
/// and nothing is hardcoded into UI logic. Failing banks are skipped rather
/// than aborting the seed.
class QuizSeeder {
  QuizSeeder(this._repo, this._local,
      [this._provider = const LocalJsonQuestionProvider()]);

  final QuizRepository _repo;
  final QuizLocalDataSource _local;
  final QuestionProvider _provider;
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
    if (await _local.seededVersion() == QuizConstants.datasetVersion) return;
    final DateTime now = DateTime.now();

    // Drop any legacy demo rows so the bundled banks are the single source of
    // bundled content (demo subjects cascade their topics, banks, questions).
    for (final subjectRow in await _local.allSubjects()) {
      if (subjectRow.source == QuizConstants.demoSource) {
        await _repo.deleteSubject(subjectRow.id);
      }
    }

    // Seed every bank listed in the bundled manifest.
    final Map<String, String> subjectIds = <String, String>{};
    if (await _provider.isAvailable()) {
      for (final QuizBankManifest manifest in await _provider.listBanks()) {
        final String subjectName =
            (manifest.subject?.trim().isNotEmpty ?? false)
                ? manifest.subject!.trim()
                : 'General Knowledge';
        final String subjectId =
            subjectIds.putIfAbsent(subjectName, () => _slug(subjectName));
        await _repo.saveSubject(QuizSubject(
          id: subjectId,
          name: subjectName,
          orderIndex: subjectIds.length - 1,
          source: QuizConstants.bundledSource,
          createdAt: now,
          updatedAt: now,
        ));

        String? topicId;
        final String topicName = (manifest.topic?.trim().isNotEmpty ?? false)
            ? manifest.topic!.trim()
            : '';
        if (topicName.isNotEmpty) {
          topicId = _slug('$subjectName $topicName');
          if (await _repo.topic(topicId) == null) {
            await _repo.saveTopic(QuizTopic(
              id: topicId,
              subjectId: subjectId,
              name: topicName,
              orderIndex: 0,
              createdAt: now,
              updatedAt: now,
            ));
          }
        }

        final QuizImportPayload payload = await _provider.fetchBank(manifest.ref);
        final ImportPreview preview = QuizJsonParser.validate(payload);
        if (preview.hasBlockingErrors) continue;
        await _repo.importPayload(payload, ImportStrategy.merge,
            subjectId: subjectId, topicId: topicId);
      }
    }

    await _local.setSeededVersion(QuizConstants.datasetVersion);
  }

  /// Deterministic lowercase-kebab slug used for stable subject/topic ids so
  /// re-seeding upserts rather than duplicating rows.
  static String _slug(String input) {
    final StringBuffer out = StringBuffer();
    for (final int unit in input.toLowerCase().codeUnits) {
      final String ch = String.fromCharCode(unit);
      final bool isAlnum = (ch.compareTo('a') >= 0 && ch.compareTo('z') <= 0) ||
          (ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0);
      if (isAlnum) {
        out.write(ch);
      } else if (out.isNotEmpty && !out.toString().endsWith('-')) {
        out.write('-');
      }
    }
    final String slug = out.toString().replaceAll(RegExp(r'-+$'), '');
    return slug.isEmpty ? 'subject' : slug;
  }
}

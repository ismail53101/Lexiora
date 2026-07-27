import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';
import 'package:lexiora/modules/quiz/domain/quiz_json.dart';
import 'package:lexiora/modules/quiz/domain/repositories/question_provider.dart';

/// Reads question banks bundled under `assets/quiz/`.
///
/// ── Expected folder structure (content is added later; none ships now) ──
///   assets/
///     quiz/
///       manifest.json                 ← lists every bank (see below)
///       pakistan_affairs/
///         economy.json
///         history.json
///       english/
///         grammar.json
///         vocabulary.json
///       islamiat/
///         seerat.json
///       general_knowledge/
///         science.json
///
/// `manifest.json` shape:
///   { "banks": [ { "ref": "pakistan_affairs/economy.json",
///                  "name": "Economy", "subject": "Pakistan Affairs" }, … ] }
///
/// Each referenced file uses the schema documented in [QuizJsonParser]. To ship
/// content later: drop the JSON files in, add `assets/quiz/` to pubspec, and
/// list the files in `manifest.json` — no engine change is required. With no
/// assets present (this version) every call returns empty, gracefully.
class LocalJsonQuestionProvider implements QuestionProvider {
  const LocalJsonQuestionProvider();

  static const String manifestPath = 'assets/quiz/manifest.json';
  static const String assetDir = 'assets/quiz/';

  @override
  QuizContentSource get source => QuizContentSource.localJson;

  @override
  Future<bool> isAvailable() async {
    try {
      await rootBundle.loadString(manifestPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<QuizBankManifest>> listBanks() async {
    try {
      final String raw = await rootBundle.loadString(manifestPath);
      final dynamic decoded = jsonDecode(raw);
      final List<dynamic> banks = decoded is Map
          ? (decoded['banks'] as List?) ?? const <dynamic>[]
          : (decoded is List ? decoded : const <dynamic>[]);
      return banks
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) => QuizBankManifest(
                ref: '${m['ref']}',
                name: '${m['name'] ?? m['ref']}',
                subject: m['subject'] as String?,
                topic: m['topic'] as String?,
                version: m['version'] as String?,
                questionCount: m['questionCount'] as int?,
              ))
          .toList();
    } catch (_) {
      return const <QuizBankManifest>[]; // no manifest bundled yet
    }
  }

  @override
  Future<QuizImportPayload> fetchBank(String ref) async {
    final String raw = await rootBundle.loadString('$assetDir$ref');
    final QuizImportPayload parsed =
        QuizJsonParser.parse(raw, fallbackName: ref);
    return QuizImportPayload(
      name: parsed.name,
      subject: parsed.subject,
      topic: parsed.topic,
      description: parsed.description,
      color: parsed.color,
      tags: parsed.tags,
      version: parsed.version,
      externalId: parsed.externalId,
      source: QuizContentSource.localJson,
      questions: parsed.questions,
    );
  }
}

/// Placeholder Cloud API provider. No networking and no backend in this version
/// — it advertises itself as unavailable so the UI can show "not configured".
/// Wiring a real backend later is a drop-in replacement behind [QuestionProvider].
class CloudQuestionProvider implements QuestionProvider {
  const CloudQuestionProvider();

  @override
  QuizContentSource get source => QuizContentSource.cloud;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<List<QuizBankManifest>> listBanks() async =>
      const <QuizBankManifest>[];

  @override
  Future<QuizImportPayload> fetchBank(String ref) async =>
      throw UnsupportedError('Cloud API is not configured in this build.');
}

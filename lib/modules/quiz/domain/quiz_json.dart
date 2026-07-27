import 'dart:convert';

import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';

/// Parses & validates the Quiz Engine's JSON exchange format. Pure Dart (no I/O)
/// so it is shared by Local JSON, Admin CMS and Cloud providers and is fully
/// unit-testable. The engine never hardcodes content — this only *reads* it.
///
/// ── JSON schema ────────────────────────────────────────────────────────────
/// {
///   "bank": {
///     "name": "Economy",           // required (falls back to file name)
///     "subject": "Pakistan Affairs",
///     "topic": "Economy",
///     "description": "…",
///     "color": 4283215696,          // optional ARGB int
///     "tags": "css,fpsc",
///     "version": "1.0",
///     "id": "pa_economy"            // optional external id (for merge/replace)
///   },
///   "questions": [
///     {
///       "type": "mcq",              // mcq | truefalse | blank
///                                    // (matching | multi are reserved)
///       "prompt": "…",              // required
///       "options": ["A","B","C"],   // required for mcq
///       "answer": 2,                 // mcq: index or option text;
///                                    // truefalse: true/false;
///                                    // blank: string or [strings]
///       "explanation": "…",
///       "subject": "…", "topic": "…", "tags": "…",
///       "difficulty": "medium",      // none | easy | medium | hard
///       "id": "q1"                   // optional external id
///     }
///   ]
/// }
///
/// A bare top-level array of question objects is also accepted (the bank name
/// then comes from [fallbackName]).
abstract final class QuizJsonParser {
  /// Decodes [jsonText] into a payload. Throws [FormatException] on malformed
  /// JSON or a completely unrecognised shape.
  static QuizImportPayload parse(String jsonText, {String? fallbackName}) {
    final dynamic decoded = jsonDecode(jsonText);
    Map<String, dynamic> bank = <String, dynamic>{};
    List<dynamic> rawQuestions;

    if (decoded is List) {
      rawQuestions = decoded;
    } else if (decoded is Map) {
      final Map<String, dynamic> map = decoded.cast<String, dynamic>();
      bank = (map['bank'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      rawQuestions = (map['questions'] as List?) ?? const <dynamic>[];
    } else {
      throw const FormatException('Unrecognised quiz JSON (expected object or array).');
    }

    final String name = (bank['name'] as String?)?.trim().isNotEmpty == true
        ? (bank['name'] as String).trim()
        : (fallbackName?.trim().isNotEmpty == true
            ? fallbackName!.trim()
            : 'Imported bank');

    final List<QuizQuestion> questions = <QuizQuestion>[];
    for (int i = 0; i < rawQuestions.length; i++) {
      final dynamic q = rawQuestions[i];
      if (q is! Map) continue;
      questions.add(_question(q.cast<String, dynamic>(), i));
    }

    return QuizImportPayload(
      name: name,
      subject: (bank['subject'] as String?)?.trim(),
      topic: (bank['topic'] as String?)?.trim(),
      description: (bank['description'] as String?)?.trim(),
      color: bank['color'] is int ? bank['color'] as int : null,
      tags: (bank['tags'] as String?)?.trim(),
      version: (bank['version'] as String?)?.trim(),
      externalId: (bank['id'] as String?)?.trim(),
      questions: questions,
    );
  }

  /// Validates a parsed payload, returning per-question issues and type counts.
  static ImportPreview validate(QuizImportPayload payload) {
    final List<ImportIssue> issues = <ImportIssue>[];
    final Map<QuestionType, int> byType = <QuestionType, int>{};

    if (payload.questions.isEmpty) {
      issues.add(const ImportIssue(
          -1, ImportSeverity.error, 'No questions found in this file.'));
    }

    for (int i = 0; i < payload.questions.length; i++) {
      final QuizQuestion q = payload.questions[i];
      byType[q.type] = (byType[q.type] ?? 0) + 1;

      if (q.prompt.trim().isEmpty) {
        issues.add(ImportIssue(i, ImportSeverity.error, 'Question ${i + 1}: empty prompt.'));
      }
      switch (q.type) {
        case QuestionType.mcqSingle:
          if (q.options.length < 2) {
            issues.add(ImportIssue(i, ImportSeverity.error,
                'Question ${i + 1}: MCQ needs at least 2 options.'));
          }
          if (q.answerIndex == null ||
              q.answerIndex! < 0 ||
              q.answerIndex! >= q.options.length) {
            issues.add(ImportIssue(i, ImportSeverity.error,
                'Question ${i + 1}: answer index is missing or out of range.'));
          }
        case QuestionType.trueFalse:
          if (q.answerBool == null) {
            issues.add(ImportIssue(i, ImportSeverity.error,
                'Question ${i + 1}: True/False answer is missing.'));
          }
        case QuestionType.fillBlank:
          if (q.answerTexts.isEmpty) {
            issues.add(ImportIssue(i, ImportSeverity.error,
                'Question ${i + 1}: fill-in-the-blank needs at least one accepted answer.'));
          }
        case QuestionType.matching:
        case QuestionType.multiCorrect:
          issues.add(ImportIssue(i, ImportSeverity.warning,
              'Question ${i + 1}: "${q.type.label}" is reserved and will be stored but not graded yet.'));
      }
    }
    return ImportPreview(payload: payload, issues: issues, byType: byType);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static QuizQuestion _question(Map<String, dynamic> m, int index) {
    final QuestionType type = _type(m['type']);
    final List<String> options = ((m['options'] as List?) ?? const <dynamic>[])
        .map((dynamic e) => '$e')
        .toList();
    final DateTime now = DateTime.now();

    int? answerIndex;
    bool? answerBool;
    List<String> answerTexts = const <String>[];
    List<int> answerIndexes = const <int>[];
    final dynamic answer = m['answer'];

    switch (type) {
      case QuestionType.mcqSingle:
        if (answer is int) {
          answerIndex = answer;
        } else if (answer is String) {
          final int idx = options.indexWhere(
              (String o) => o.trim().toLowerCase() == answer.trim().toLowerCase());
          answerIndex = idx >= 0 ? idx : null;
        }
      case QuestionType.trueFalse:
        if (answer is bool) {
          answerBool = answer;
        } else if (answer is String) {
          answerBool = answer.trim().toLowerCase() == 'true';
        }
      case QuestionType.fillBlank:
        if (answer is String) {
          answerTexts = <String>[answer];
        } else if (answer is List) {
          answerTexts = answer.map((dynamic e) => '$e').toList();
        }
      case QuestionType.multiCorrect:
        if (answer is List) {
          answerIndexes = answer.whereType<int>().toList();
        }
      case QuestionType.matching:
        break; // reserved
    }

    return QuizQuestion(
      id: 'import_$index',
      bankId: '',
      type: type,
      prompt: (m['prompt'] as String?)?.trim() ?? '',
      options: options,
      answerIndex: answerIndex,
      answerBool: answerBool,
      answerTexts: answerTexts,
      answerIndexes: answerIndexes,
      explanation: (m['explanation'] as String?)?.trim(),
      subject: (m['subject'] as String?)?.trim(),
      topic: (m['topic'] as String?)?.trim(),
      tags: (m['tags'] as String?)?.trim(),
      difficulty: _difficulty(m['difficulty']),
      externalId: (m['id'] as String?)?.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  static QuestionType _type(dynamic raw) {
    final String s = '$raw'.trim().toLowerCase();
    switch (s) {
      case 'mcq':
      case 'mcq_single':
      case 'single':
      case 'multiple_choice':
        return QuestionType.mcqSingle;
      case 'truefalse':
      case 'true_false':
      case 'tf':
      case 'boolean':
        return QuestionType.trueFalse;
      case 'blank':
      case 'fill':
      case 'fillblank':
      case 'fill_blank':
        return QuestionType.fillBlank;
      case 'matching':
      case 'match':
        return QuestionType.matching;
      case 'multi':
      case 'multicorrect':
      case 'multi_correct':
        return QuestionType.multiCorrect;
      default:
        return QuestionType.mcqSingle;
    }
  }

  static QuizDifficulty _difficulty(dynamic raw) {
    switch ('$raw'.trim().toLowerCase()) {
      case 'easy':
        return QuizDifficulty.easy;
      case 'medium':
      case 'moderate':
        return QuizDifficulty.medium;
      case 'hard':
      case 'difficult':
        return QuizDifficulty.hard;
      default:
        return QuizDifficulty.none;
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';

/// Where questions come from. The Quiz Engine never depends on any of these —
/// it only consumes [QuizQuestion] objects a provider yields.
enum QuizContentSource {
  localJson,
  admin,
  cloud,
  manual;

  String get id => switch (this) {
        QuizContentSource.localJson => 'local_json',
        QuizContentSource.admin => 'admin',
        QuizContentSource.cloud => 'cloud',
        QuizContentSource.manual => 'manual',
      };

  String get label => switch (this) {
        QuizContentSource.localJson => 'Local JSON',
        QuizContentSource.admin => 'Admin CMS',
        QuizContentSource.cloud => 'Cloud API',
        QuizContentSource.manual => 'Manual import',
      };
}

/// Metadata describing a bank a provider can supply, without loading questions.
class QuizBankManifest extends Equatable {
  const QuizBankManifest({
    required this.ref,
    required this.name,
    this.subject,
    this.topic,
    this.version,
    this.questionCount,
  });

  /// Opaque reference the provider understands (asset path, remote id, …).
  final String ref;
  final String name;
  final String? subject;
  final String? topic;
  final String? version;
  final int? questionCount;

  @override
  List<Object?> get props =>
      <Object?>[ref, name, subject, topic, version, questionCount];
}

/// A parsed, source-agnostic bank ready to import. Questions carry a placeholder
/// bank id; the importer assigns the real bank id and fresh row ids.
class QuizImportPayload extends Equatable {
  const QuizImportPayload({
    required this.name,
    required this.questions,
    this.subject,
    this.topic,
    this.description,
    this.color,
    this.tags,
    this.version,
    this.externalId,
    this.source = QuizContentSource.manual,
  });

  final String name;
  final String? subject;
  final String? topic;
  final String? description;
  final int? color;
  final String? tags;
  final String? version;
  final String? externalId;
  final QuizContentSource source;
  final List<QuizQuestion> questions;

  @override
  List<Object?> get props => <Object?>[
        name, subject, topic, description, color, tags, version, externalId,
        source, questions,
      ];
}

enum ImportStrategy {
  merge,
  replace;

  String get label => switch (this) {
        ImportStrategy.merge => 'Merge into existing',
        ImportStrategy.replace => 'Replace existing',
      };
}

enum ImportSeverity { error, warning }

/// A single validation finding tied to a question index (or -1 for bank-level).
class ImportIssue extends Equatable {
  const ImportIssue(this.index, this.severity, this.message);

  final int index;
  final ImportSeverity severity;
  final String message;

  @override
  List<Object?> get props => <Object?>[index, severity, message];
}

/// The result of validating a payload — shown on the Import preview screen.
class ImportPreview extends Equatable {
  const ImportPreview({
    required this.payload,
    required this.issues,
    required this.byType,
  });

  final QuizImportPayload payload;
  final List<ImportIssue> issues;
  final Map<QuestionType, int> byType;

  int get totalParsed => payload.questions.length;
  List<ImportIssue> get errors =>
      issues.where((ImportIssue i) => i.severity == ImportSeverity.error).toList();
  List<ImportIssue> get warnings => issues
      .where((ImportIssue i) => i.severity == ImportSeverity.warning)
      .toList();
  bool get hasBlockingErrors => errors.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[payload, issues, byType];
}

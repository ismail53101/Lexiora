import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// v0.9.2 guardrail: the public app must contain NO admin/content-management UI,
/// while the internal architecture (repositories, services, providers, parser)
/// is retained for the future standalone Sapiora CMS.
void main() {
  const String pages = 'lib/modules/quiz/presentation/pages';

  test('no admin UI exists in the public app', () {
    expect(Directory('$pages/admin').existsSync(), isFalse,
        reason: 'the admin/ UI folder must be removed');
    for (final String gone in <String>[
      '$pages/admin/admin_hub_page.dart',
      '$pages/admin/admin_subjects_page.dart',
      '$pages/admin/admin_topics_page.dart',
      '$pages/admin/admin_quizzes_page.dart',
      '$pages/admin/admin_questions_page.dart',
      '$pages/admin/admin_import_page.dart',
      '$pages/quiz_export_page.dart',
    ]) {
      expect(File(gone).existsSync(), isFalse, reason: '$gone must be deleted');
    }
  });

  test('no presentation code references admin/import/export navigation', () {
    final Iterable<File> dartFiles = Directory('lib/modules/quiz/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'));
    for (final File f in dartFiles) {
      final String src = f.readAsStringSync();
      expect(src.contains('AdminHubPage'), isFalse, reason: '${f.path} references admin UI');
      expect(src.contains('QuizExportPage'), isFalse, reason: '${f.path} references export UI');
      expect(src.contains('adminMode'), isFalse, reason: '${f.path} references the admin switch');
    }
  });

  test('internal architecture is retained (no navigation to it)', () {
    for (final String kept in <String>[
      'lib/modules/quiz/domain/repositories/quiz_admin_repository.dart',
      'lib/modules/quiz/data/repositories/quiz_admin_repository_impl.dart',
      'lib/modules/quiz/domain/repositories/question_provider.dart',
      'lib/modules/quiz/data/providers/content_providers.dart',
      'lib/modules/quiz/domain/quiz_json.dart',
      'lib/modules/quiz/data/services/quiz_export_service.dart',
    ]) {
      expect(File(kept).existsSync(), isTrue, reason: '$kept must be kept');
    }
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the bundled vocabulary content: every pack must be valid, deduped and
/// genuinely populated (not demo-sized). This fails loudly if a real list is
/// ever replaced by placeholder/demo data.
void main() {
  test('every bundled vocabulary pack is valid, deduped and non-trivial', () {
    final Directory dir = Directory('assets/vocabulary');
    final List<File> files = dir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.toLowerCase().endsWith('.json'))
        .toList();

    expect(files.length, greaterThanOrEqualTo(11),
        reason: 'all starter lists should ship');

    final Set<String> ids = <String>{};
    int total = 0;

    for (final File f in files) {
      final Object? decoded = jsonDecode(f.readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>(), reason: '${f.path} shape');
      final Map<String, dynamic> d = decoded! as Map<String, dynamic>;

      final Map<String, dynamic> list = d['list'] as Map<String, dynamic>;
      final String id = (list['id'] as String).trim();
      expect(id, isNotEmpty);
      expect(ids.add(id), isTrue, reason: 'duplicate list id "$id"');
      expect((list['title'] as String).trim(), isNotEmpty);

      final List<dynamic> words = d['words'] as List<dynamic>;
      expect(words.length, greaterThanOrEqualTo(40),
          reason: 'list "$id" looks like demo data (${words.length} words)');

      // Idioms & proverbs are phrases, not single words, so they have no
      // canonical IPA; everything else must carry a slashed IPA.
      final bool isIdioms = id == 'idioms';
      final List<String> required = isIdioms
          ? const <String>['word', 'urdu', 'meaning', 'pos']
          : const <String>['word', 'ipa', 'urdu', 'meaning', 'pos'];

      final Set<String> seen = <String>{};
      for (final dynamic w in words) {
        final Map<String, dynamic> m = w as Map<String, dynamic>;
        for (final String k in required) {
          expect((m[k] as String?)?.trim().isNotEmpty ?? false, isTrue,
              reason: 'list "$id" entry missing "$k"');
        }
        if (!isIdioms) {
          expect((m['ipa'] as String).startsWith('/'), isTrue,
              reason: 'list "$id": IPA for "${m['word']}" must be slashed');
        }
        final String wl = (m['word'] as String).toLowerCase();
        expect(seen.add(wl), isTrue, reason: 'list "$id" duplicate word "$wl"');
      }
      total += words.length;
    }

    expect(total, greaterThanOrEqualTo(1000),
        reason: 'realistic starter content across all lists, not demo data');
  });
}

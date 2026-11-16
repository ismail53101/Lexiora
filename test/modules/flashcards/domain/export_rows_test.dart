import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/csv_codec.dart';
import 'package:lexiora/modules/flashcards/domain/logic/export_rows.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';

void main() {
  final DateTime now = DateTime(2026, 3, 10, 12);
  FcCard card(String id, String front, String back,
          {FsrsCard? fsrs, List<String> tags = const <String>[], FcCardType type = FcCardType.basic, bool suspended = false}) =>
      FcCard(
        id: id, deckId: 'd', front: front, back: back, type: type, tags: tags,
        suspended: suspended, createdAt: now, updatedAt: now,
        fsrs: fsrs ?? FsrsCard.fresh(now),
      );

  test('matrix has a header and one row per card', () {
    final List<List<String>> m = exportMatrix(<FcCard>[
      card('1', 'Hello', 'سلام', tags: <String>['a', 'b']),
      card('2', 'Q', 'A',
          fsrs: FsrsCard(state: FsrsState.review, stability: 12.34, difficulty: 5,
              due: DateTime(2026, 4, 1, 4), lastReview: now)),
    ], <String, String>{'d': 'My deck'});
    expect(m, hasLength(3));
    expect(m.first, exportHeaders);
    expect(m[1].sublist(0, 6), <String>['My deck', 'Basic', 'Hello', 'سلام', 'a, b', '']);
    expect(m[1][8], 'New');
    expect(m[1][9], '');
    expect(m[2][8], 'Review');
    expect(m[2][9], '2026-04-01');
    expect(m[2][10], '12.3');
  });

  test('suspended cards are labelled as such', () {
    expect(statusLabel(card('1', 'q', 'a', suspended: true)), 'Suspended');
  });

  test('anki text is tab separated with underscored tags and round-trips', () {
    final String t = ankiText(<FcCard>[
      card('1', 'a\tb', 'say "hi"', tags: <String>['two words', 'x']),
      card('2', 'The {{c1::sun}} is a star', '', type: FcCardType.cloze),
    ]);
    final List<List<String>> rows = parseDelimited(t, delimiter: '\t');
    expect(rows[0], <String>['a\tb', 'say "hi"', 'two_words x']);
    final DraftParseResult back = draftsFromRows(rows);
    expect(back.drafts, hasLength(2));
    expect(back.drafts.last.type, FcCardType.cloze);
  });

  test('formats expose extension and mime', () {
    expect(FcExportFormat.csv.ext, 'csv');
    expect(FcExportFormat.pdf.mime, 'application/pdf');
    expect(FcExportFormat.values, hasLength(5));
  });
}

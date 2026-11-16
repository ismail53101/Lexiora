import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/flashcards/data/backup_codec.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/cloze.dart';
import 'package:lexiora/modules/flashcards/domain/logic/csv_codec.dart';
import 'package:lexiora/modules/flashcards/domain/logic/fc_time.dart';
import 'package:lexiora/modules/flashcards/domain/logic/legacy_mapper.dart';
import 'package:lexiora/modules/flashcards/domain/logic/stats_calc.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';

void main() {
  group('time helpers', () {
    test('study day rolls over at 04:00', () {
      expect(studyDayKey(DateTime(2026, 3, 10, 3, 59)), '2026-03-09');
      expect(studyDayKey(DateTime(2026, 3, 10, 4, 0)), '2026-03-10');
      expect(studyDayStart(DateTime(2026, 3, 10, 23, 0)), DateTime(2026, 3, 10, 4));
      expect(studyDayStart(DateTime(2026, 3, 10, 1, 0)), DateTime(2026, 3, 9, 4));
    });

    test('unix round trip and day arithmetic', () {
      final DateTime t = DateTime(2026, 1, 31, 9, 30, 15);
      expect(fromUnix(toUnix(t)), t);
      expect(daysBetween(DateTime(2026, 1, 31), DateTime(2026, 3, 1)), 29);
      expect(daysBetween(DateTime(2026, 3, 1), DateTime(2026, 1, 31)), -29);
      expect(parseDayKey('2026-02-03'), DateTime(2026, 2, 3));
      expect(parseDayKey('nope'), isNull);
    });

    test('formatInterval', () {
      expect(formatInterval(const Duration(seconds: 20)), '<1m');
      expect(formatInterval(const Duration(minutes: 10)), '10m');
      expect(formatInterval(const Duration(hours: 5)), '5h');
      expect(formatInterval(const Duration(days: 3)), '3d');
      expect(formatInterval(const Duration(days: 45)), '1.5mo');
      expect(formatInterval(const Duration(days: 365)), '1y');
      expect(formatInterval(const Duration(days: 548)), '1.5y');
    });
  });

  group('cloze', () {
    const String t = 'The {{c1::heart}} pumps {{c2::blood::fluid}} and {{c1::oxygen}}.';

    test('parse spans, indices, hints', () {
      final List<ClozeSpan> s = parseCloze(t);
      expect(s.map((ClozeSpan e) => e.answer).toList(), <String>['heart', 'blood', 'oxygen']);
      expect(s[1].hint, 'fluid');
      expect(s[0].hint, isNull);
      expect(clozeIndices(t), <int>[1, 2]);
      expect(nextClozeIndex(t), 3);
      expect(nextClozeIndex('plain'), 1);
      expect(hasCloze(t), true);
      expect(hasCloze('no cloze {{x}}'), false);
    });

    String join(List<ClozeSegment> l) => l.map((ClozeSegment e) => e.text).join();

    test('question hides the active deletion only', () {
      expect(join(renderCloze(t, activeIndex: 1, revealed: false)),
          'The […] pumps blood and […].');
      expect(join(renderCloze(t, activeIndex: 2, revealed: false)),
          'The heart pumps [fluid] and oxygen.');
      expect(join(renderCloze(t, revealed: false)),
          'The […] pumps [fluid] and […].');
    });

    test('answer reveals and marks the active ones', () {
      final List<ClozeSegment> r = renderCloze(t, activeIndex: 1, revealed: true);
      expect(join(r), 'The heart pumps blood and oxygen.');
      expect(r.where((ClozeSegment e) => e.isAnswer).map((ClozeSegment e) => e.text).toList(),
          <String>['heart', 'oxygen']);
      expect(clozePlainText(t), 'The heart pumps blood and oxygen.');
      expect(clozeQuestionText(t, activeIndex: 2), 'The heart pumps blank and oxygen.');
    });

    test('wrapSelectionAsCloze', () {
      final ({String text, int caret}) r = wrapSelectionAsCloze('Paris is big', 0, 5, 1);
      expect(r.text, '{{c1::Paris}} is big');
      expect(r.caret, 13);
      expect(wrapSelectionAsCloze('abc', 3, 3, 2).text, 'abc{{c2::}}');
    });

    test('multi-line cloze', () {
      expect(parseCloze('{{c1::a\nb}}').single.answer, 'a\nb');
    });
  });

  group('legacy mapper', () {
    final DateTime now = DateTime(2026, 3, 10, 12);

    test('new and learning', () {
      expect(legacyToFsrs(reviewState: 0, dueAt: null, intervalDays: 0, easeFactor: 2.5, lastReviewedAt: null, now: now).state,
          FsrsState.newCard);
      final FsrsCard l = legacyToFsrs(
          reviewState: 1, dueAt: now, intervalDays: 0, easeFactor: 2.5, lastReviewedAt: null, now: now);
      expect(l.state, FsrsState.learning);
      expect(l.step, 0);
      expect(l.stability, isNull);
    });

    test('review: stability = interval, difficulty from ease', () {
      FsrsCard r(double ease, int interval) => legacyToFsrs(
            reviewState: 2, dueAt: now, intervalDays: interval, easeFactor: ease,
            lastReviewedAt: now.subtract(Duration(days: interval)), now: now,
          );
      expect(r(2.5, 12).stability, 12);
      expect(r(2.5, 12).difficulty, closeTo(5, 1e-9));
      expect(r(1.3, 3).difficulty, closeTo(9, 1e-9));
      expect(r(5.0, 3).difficulty, 1);
      expect(r(0.5, 3).difficulty, 10);
      expect(r(2.5, 0).stability, 1);
    });

    test('review without lastReviewedAt gets one (so retrievability works)', () {
      final FsrsCard c = legacyToFsrs(
          reviewState: 2, dueAt: now, intervalDays: 5, easeFactor: 2.5, lastReviewedAt: null, now: now);
      expect(c.lastReview, now.subtract(const Duration(days: 5)));
    });
  });

  group('stats', () {
    test('current streak, including "not yet today"', () {
      final DateTime now = DateTime(2026, 3, 10, 15);
      expect(currentStreak(<String>{'2026-03-10', '2026-03-09', '2026-03-08'}, now), 3);
      expect(currentStreak(<String>{'2026-03-09', '2026-03-08'}, now), 2);
      expect(currentStreak(<String>{'2026-03-07'}, now), 0);
      expect(currentStreak(<String>{}, now), 0);
      expect(currentStreak(<String>{'2026-03-01', '2026-02-28', '2026-02-27'}, DateTime(2026, 3, 1)), 3);
    });

    test('longest streak', () {
      expect(longestStreak(<String>{'2026-03-01', '2026-03-02', '2026-03-03', '2026-03-10', '2026-03-11'}), 3);
      expect(longestStreak(<String>{}), 0);
      expect(longestStreak(<String>{'2026-02-28', '2026-03-01'}), 2);
    });

    test('heatmap shape, levels and future cells', () {
      final DateTime today = DateTime(2026, 3, 11); // Wednesday
      final List<List<HeatCell?>> g = buildHeatmap(
        <String, int>{'2026-03-11': 100, '2026-03-10': 30, '2026-03-09': 1},
        today,
        weeks: 3,
      );
      expect(g, hasLength(3));
      expect(g.every((List<HeatCell?> w) => w.length == 7), true);
      final List<HeatCell?> last = g.last;
      expect(last[0]!.day, DateTime(2026, 3, 9));
      expect(last[0]!.level, 1);
      expect(last[1]!.level, 2);
      expect(last[2]!.level, 4);
      expect(last[3], isNull);
      expect(g.first.first!.day, DateTime(2026, 2, 23));
    });

    test('forecast counts overdue on day 0 and ignores beyond horizon', () {
      final DateTime now = DateTime(2026, 3, 10, 12);
      final List<int> f = buildForecast(<DateTime>[
        DateTime(2026, 3, 8, 4),
        DateTime(2026, 3, 10, 4),
        DateTime(2026, 3, 11, 4),
        DateTime(2026, 3, 11, 4),
        DateTime(2026, 4, 30, 4),
      ], now, days: 5);
      expect(f, <int>[2, 2, 0, 0, 0]);
    });

    test('percent', () {
      expect(percent(1, 4), 25);
      expect(percent(0, 0), 0);
    });
  });

  group('csv codec', () {
    test('detect delimiter', () {
      expect(detectDelimiter('a\tb\tc'), '\t');
      expect(detectDelimiter('a,b,c'), ',');
      expect(detectDelimiter('a;b;c'), ';');
      expect(detectDelimiter('"a,b"\tc'), '\t');
    });

    test('parse quotes, embedded delimiters, newlines, CRLF and BOM', () {
      final List<List<String>> r = parseDelimited('\uFEFFfront,back\r\n"a, b","say ""hi"""\r\n"line1\nline2",x\r\n\r\n');
      expect(r, <List<String>>[
        <String>['front', 'back'],
        <String>['a, b', 'say "hi"'],
        <String>['line1\nline2', 'x'],
      ]);
    });

    test('encode round trips', () {
      final List<List<String>> rows = <List<String>>[
        <String>['a,b', 'say "hi"', 'multi\nline'],
        <String>['plain', '', 'x'],
      ];
      expect(parseDelimited(encodeDelimited(rows), delimiter: ','), rows);
      expect(parseDelimited(encodeDelimited(rows, delimiter: '\t'), delimiter: '\t'), rows);
    });

    test('drafts with header in any order', () {
      final DraftParseResult r = draftsFromRows(parseDelimited(
          'Answer,Question,Tags,Extra\nParis,Capital of France?,"geo, europe",common\n,,,\nonly,,,'));
      expect(r.drafts, hasLength(1));
      expect(r.drafts.single.front, 'Capital of France?');
      expect(r.drafts.single.back, 'Paris');
      expect(r.drafts.single.tags, <String>['geo', 'europe']);
      expect(r.drafts.single.notes, 'common');
      expect(r.skipped, 2);
    });

    test('drafts without header, anki-style tab file, cloze detection', () {
      final DraftParseResult r = draftsFromRows(parseDelimited(
          'hello\tسلام\tgreetings\nThe {{c1::sun}} is a star\t\t\nbad row\t'));
      expect(r.drafts, hasLength(2));
      expect(r.drafts.first.back, 'سلام');
      expect(r.drafts.first.tags, <String>['greetings']);
      expect(r.drafts.last.type, FcCardType.cloze);
      expect(r.skipped, 1);
    });

    test('type column', () {
      final DraftParseResult r = draftsFromRows(parseDelimited('front,back,type\nq,a,typed\nq2,a2,basic'));
      expect(r.drafts.map((CardDraft d) => d.type).toList(), <FcCardType>[FcCardType.typed, FcCardType.basic]);
    });
  });

  group('backup codec', () {
    test('rejects wrong type and newer versions', () {
      expect(() => decodeBackup(<String, dynamic>{'type': 'x'}), throwsA(isA<FormatException>()));
      expect(() => decodeBackup(<String, dynamic>{'type': 'flashcards_backup', 'version': 99}),
          throwsA(isA<FormatException>()));
    });

    test('v1 normalisation: camelCase → snake_case, millis → seconds, bool → int', () {
      final BackupData d = decodeBackup(<String, dynamic>{
        'type': 'flashcards_backup',
        'version': 1,
        'cards': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'c', 'deckId': 'd', 'front': 'f', 'back': 'b', 'bookmarked': true,
            'dueAt': 1700000000000, 'lastReviewedAt': null, 'createdAt': 1700000001000,
          },
        ],
      });
      final Map<String, Object?> c = d.cards.single;
      expect(c['deck_id'], 'd');
      expect(c['bookmarked'], 1);
      expect(c['due_at'], 1700000000);
      expect(c['created_at'], 1700000001);
      expect(c['last_reviewed_at'], isNull);
      expect(c['search_text'], isNull);
    });
  });

  group('models', () {
    test('card state helpers', () {
      final DateTime now = DateTime(2026, 3, 10);
      FcCard c(FsrsCard f, {int lapses = 0, DateTime? buried}) => FcCard(
            id: 'a', deckId: 'd', front: 'f', back: 'b', createdAt: now, updatedAt: now,
            fsrs: f, lapses: lapses, buriedUntil: buried,
          );
      expect(c(FsrsCard.fresh(now)).isNew, true);
      expect(c(FsrsCard.fresh(now)).isDue(now), true);
      expect(c(FsrsCard(state: FsrsState.review, stability: 30, difficulty: 5, due: now.add(const Duration(days: 1)), lastReview: now)).isDue(now), false);
      expect(c(FsrsCard(state: FsrsState.review, stability: 30, difficulty: 5, due: now, lastReview: now)).isMature, true);
      expect(c(FsrsCard.fresh(now), lapses: 8).isLeech, true);
      expect(c(FsrsCard.fresh(now), buried: now.add(const Duration(hours: 1))).isBuried(now), true);
    });

    test('StudyCounts', () {
      const StudyCounts s = StudyCounts(newCount: 3, learningCount: 2, reviewCount: 10);
      expect(s.total, 15);
      expect(s.estimatedMinutes, 5);
      expect(StudyCounts.zero.isEmpty, true);
      expect(StudyMode.due.isPractice, false);
      expect(StudyMode.cram.isPractice, true);
    });
  });

  // Keep the import used (Random seeds are exercised in the session tests).
  test('random import sanity', () => expect(Random(1).nextInt(1), 0));
}

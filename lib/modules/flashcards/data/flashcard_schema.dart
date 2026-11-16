import 'package:lexiora/modules/flashcards/data/fc_sql.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/fc_time.dart';
import 'package:lexiora/modules/flashcards/domain/logic/legacy_mapper.dart';

/// Extra tables for the FSRS flashcards engine.
///
/// They are created with plain SQL (not Drift table classes) so the generated
/// `app_database.g.dart` does not need regenerating, and they sit *next to*
/// the existing `decks`, `flashcards` and `review_logs` tables, which are left
/// untouched. That keeps every user's decks, cards and history intact.
class FcSchema {
  const FcSchema._();

  static const String cardState = 'fc_card_state';
  static const String deckSettings = 'fc_deck_settings';

  /// Idempotent DDL, run every time the database opens.
  static const List<String> ddl = <String>[
    '''
CREATE TABLE IF NOT EXISTS fc_card_state (
  card_id TEXT NOT NULL PRIMARY KEY,
  card_type INTEGER NOT NULL DEFAULT 0,
  cloze_index INTEGER,
  state INTEGER NOT NULL DEFAULT 0,
  step INTEGER,
  stability REAL,
  difficulty REAL,
  due_at INTEGER NOT NULL DEFAULT 0,
  last_review_at INTEGER,
  reps INTEGER NOT NULL DEFAULT 0,
  lapses INTEGER NOT NULL DEFAULT 0,
  suspended INTEGER NOT NULL DEFAULT 0,
  buried_until INTEGER NOT NULL DEFAULT 0
)''',
    'CREATE INDEX IF NOT EXISTS idx_fc_state_queue '
        'ON fc_card_state (state, suspended, due_at)',
    'CREATE INDEX IF NOT EXISTS idx_fc_logs_card '
        'ON review_logs (card_id, reviewed_at)',
    '''
CREATE TABLE IF NOT EXISTS fc_deck_settings (
  deck_id TEXT NOT NULL PRIMARY KEY,
  new_per_day INTEGER NOT NULL DEFAULT 20,
  reviews_per_day INTEGER NOT NULL DEFAULT 200,
  desired_retention REAL NOT NULL DEFAULT 0.9,
  shuffle_new INTEGER NOT NULL DEFAULT 0
)''',
  ];

  /// Legacy cards that do not have a scheduling row yet.
  static const String selectUnmigrated = '''
SELECT f.id AS id, f.review_state AS review_state, f.due_at AS due_at,
       f.interval_days AS interval_days, f.ease_factor AS ease_factor,
       f.last_reviewed_at AS last_reviewed_at, f.repetitions AS repetitions,
       f.lapses AS lapses
FROM flashcards f
LEFT JOIN fc_card_state s ON s.card_id = f.id
WHERE s.card_id IS NULL''';

  static const String insertState = '''
INSERT OR IGNORE INTO fc_card_state
 (card_id, card_type, cloze_index, state, step, stability, difficulty, due_at,
  last_review_at, reps, lapses, suspended, buried_until)
VALUES (?, 0, NULL, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0)''';

  // Column lists used by backup/restore (dump rows as-is, in these columns).
  static const List<String> deckCols = <String>[
    'id', 'name', 'description', 'subject', 'topic', 'color', 'icon',
    'archived', 'created_at', 'updated_at',
  ];
  static const List<String> cardCols = <String>[
    'id', 'deck_id', 'front', 'back', 'subject', 'topic', 'tags', 'notes',
    'difficulty', 'bookmarked', 'favorite', 'review_state', 'due_at',
    'interval_days', 'ease_factor', 'repetitions', 'lapses',
    'last_reviewed_at', 'search_text', 'created_at', 'updated_at',
  ];
  static const List<String> logCols = <String>[
    'id', 'card_id', 'deck_id', 'rating', 'day', 'reviewed_at', 'duration_ms',
  ];
  static const List<String> stateCols = <String>[
    'card_id', 'card_type', 'cloze_index', 'state', 'step', 'stability',
    'difficulty', 'due_at', 'last_review_at', 'reps', 'lapses', 'suspended',
    'buried_until',
  ];
  static const List<String> settingsCols = <String>[
    'deck_id', 'new_per_day', 'reviews_per_day', 'desired_retention',
    'shuffle_new',
  ];

  /// Columns holding Unix-second timestamps (the old v1 backup used millis).
  static const Set<String> timeCols = <String>{
    'created_at', 'updated_at', 'due_at', 'last_reviewed_at', 'reviewed_at',
    'last_review_at', 'buried_until',
  };

  /// Creates the tables and gives every legacy card an FSRS state.
  /// Safe to call on every launch.
  static Future<void> ensure(FcSql db) async {
    for (final String sql in ddl) {
      await db.execute(sql);
    }
    final List<Row> rows = await db.select(selectUnmigrated);
    if (rows.isEmpty) return;
    final DateTime now = DateTime.now();
    int i(Row r, String k) => (r[k] as num?)?.toInt() ?? 0;
    final List<({String sql, List<Object?> args})> inserts =
        <({String sql, List<Object?> args})>[];
    for (final Row r in rows) {
      final int? dueSec = (r['due_at'] as num?)?.toInt();
      final int? lastSec = (r['last_reviewed_at'] as num?)?.toInt();
      final FsrsCard c = legacyToFsrs(
        reviewState: i(r, 'review_state'),
        dueAt: dueSec == null ? null : fromUnix(dueSec),
        intervalDays: i(r, 'interval_days'),
        easeFactor: (r['ease_factor'] as num?)?.toDouble() ?? 2.5,
        lastReviewedAt: lastSec == null ? null : fromUnix(lastSec),
        now: now,
      );
      inserts.add((
        sql: insertState,
        args: <Object?>[
          r['id'],
          c.state.value,
          c.step,
          c.stability,
          c.difficulty,
          toUnix(c.due),
          c.lastReview == null ? null : toUnix(c.lastReview!),
          i(r, 'repetitions'),
          i(r, 'lapses'),
        ],
      ));
    }
    await db.executeAll(inserts);
  }
}

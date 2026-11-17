import 'package:lexiora/modules/flashcards/data/backup_codec.dart';
import 'package:lexiora/modules/flashcards/data/flashcard_store.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/cloze.dart';
import 'package:lexiora/modules/flashcards/domain/logic/csv_codec.dart';
import 'package:lexiora/modules/flashcards/domain/logic/fc_time.dart';
import 'package:lexiora/modules/flashcards/domain/logic/stats_calc.dart';
import 'package:lexiora/modules/flashcards/domain/logic/study_session.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_query.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_stats_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/fc_repository.dart';
import 'package:uuid/uuid.dart';

class FcRepositoryImpl implements FcRepository {
  FcRepositoryImpl(
    this._store, {
    DateTime Function()? clock,
    Uuid uuid = const Uuid(),
  })  : _now = clock ?? DateTime.now,
        _uuid = uuid;

  final FlashcardStore _store;
  final DateTime Function() _now;
  final Uuid _uuid;

  int _revision = 0;

  @override
  Stream<int> watchRevision() => _store.watch(
        () async => ++_revision,
        refreshEvery: const Duration(days: 1),
      );

  // ── decks ──────────────────────────────────────────────────────────────────

  @override
  Stream<List<FcDeckSummary>> watchDecks({bool includeArchived = false}) =>
      _store.watch(() => _store.deckSummaries(_now(), includeArchived: includeArchived));

  @override
  Stream<FcDeckSummary?> watchDeck(String id) => _store.watch(() async {
        final List<FcDeckSummary> all =
            await _store.deckSummaries(_now(), includeArchived: true);
        for (final FcDeckSummary s in all) {
          if (s.deck.id == id) return s;
        }
        return null;
      });

  @override
  Future<FcDeck?> deck(String id) => _store.deck(id);

  @override
  Future<FcDeck> createDeck({
    required String name,
    String? description,
    String? subject,
    String? topic,
    int? color,
  }) async {
    final DateTime now = _now();
    final FcDeck d = FcDeck(
      id: _uuid.v4(),
      name: name.trim(),
      description: _clean(description),
      subject: _clean(subject),
      topic: _clean(topic),
      color: color,
      createdAt: now,
      updatedAt: now,
    );
    await _store.saveDeck(d);
    return d;
  }

  @override
  Future<void> updateDeck(FcDeck deck) =>
      _store.saveDeck(deck.copyWith(updatedAt: _now()));

  @override
  Future<void> setDeckArchived(String id, bool archived) =>
      _store.setArchived(id, archived);

  @override
  Future<void> deleteDeck(String id) => _store.deleteDeck(id);

  @override
  Future<DeckSettings> deckSettings(String deckId) => _store.settingsFor(deckId);

  @override
  Future<void> saveDeckSettings(String deckId, DeckSettings settings) =>
      _store.saveSettings(
        deckId,
        settings.copyWith(
          newPerDay: settings.newPerDay.clamp(0, 9999),
          reviewsPerDay: settings.reviewsPerDay.clamp(0, 9999),
          desiredRetention: settings.desiredRetention.clamp(0.7, 0.97).toDouble(),
        ),
      );

  static String? _clean(String? s) {
    final String? t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  // ── cards ──────────────────────────────────────────────────────────────────

  @override
  Future<List<FcCard>> browse(FcCardQuery query) => _store.browse(query, _now());

  @override
  Future<FcCard?> card(String id) => _store.card(id);

  @override
  Future<AddCardsResult> addCards(
    String deckId,
    List<CardDraft> drafts, {
    bool reversed = false,
    bool clozePerDeletion = false,
    String? subject,
    String? topic,
  }) async {
    final DateTime now = _now();
    final List<FcCard> out = <FcCard>[];
    int skipped = 0;

    FcCard make(String front, String back, FcCardType type, List<String> tags,
            String? notes, {int? clozeIndex}) =>
        FcCard(
          id: _uuid.v4(),
          deckId: deckId,
          front: front,
          back: back,
          type: type,
          clozeIndex: clozeIndex,
          subject: _clean(subject),
          topic: _clean(topic),
          tags: tags,
          notes: notes,
          fsrs: FsrsCard.fresh(now),
          createdAt: now,
          updatedAt: now,
        );

    for (final CardDraft d in drafts) {
      final String front = d.front.trim();
      final String back = d.back.trim();
      if (front.isEmpty) {
        skipped++;
        continue;
      }
      switch (d.type) {
        case FcCardType.cloze:
          if (!hasCloze(front)) {
            skipped++;
            continue;
          }
          final List<int> idx = clozeIndices(front);
          if (clozePerDeletion && idx.length > 1) {
            for (final int i in idx) {
              out.add(make(front, back, FcCardType.cloze, d.tags, d.notes, clozeIndex: i));
            }
          } else {
            out.add(make(front, back, FcCardType.cloze, d.tags, d.notes));
          }
        case FcCardType.basic:
        case FcCardType.typed:
          if (back.isEmpty) {
            skipped++;
            continue;
          }
          out.add(make(front, back, d.type, d.tags, d.notes));
          if (reversed && d.type == FcCardType.basic) {
            out.add(make(back, front, FcCardType.basic, d.tags, d.notes));
          }
      }
    }
    await _store.insertCards(out);
    return AddCardsResult(created: out.length, skipped: skipped);
  }

  @override
  Future<void> updateCard(FcCard card) =>
      _store.updateCardContent(card.copyWith(updatedAt: _now()));

  @override
  Future<void> setStarred(String id, bool starred) =>
      _store.setFlag(id, bookmarked: starred);

  @override
  Future<void> setSuspended(String id, bool suspended) =>
      _store.setFlag(id, suspended: suspended);

  @override
  Future<void> buryUntilTomorrow(String id) {
    final DateTime next = studyDayStart(_now()).add(const Duration(days: 1));
    return _store.setFlag(id, buriedUntil: next);
  }

  @override
  Future<void> deleteCards(List<String> ids) => _store.deleteCards(ids);

  @override
  Future<void> moveCards(List<String> ids, String deckId) =>
      _store.moveCards(ids, deckId);

  // ── studying ───────────────────────────────────────────────────────────────

  @override
  Future<StudySession> startSession({String? deckId, StudyMode mode = StudyMode.due}) async {
    final DateTime now = _now();
    final Map<String, FsrsScheduler> cache = <String, FsrsScheduler>{};
    if (mode.isPractice) {
      final List<FcCard> cards =
          await _store.practiceCards(deckId: deckId, mode: mode);
      return StudySession(
        schedulerFor: (String _) =>
            cache.putIfAbsent('', FsrsScheduler.new),
        newCards: const <FcCard>[],
        reviewCards: cards,
        now: now,
        practice: true,
      );
    }
    final StudyQueueData q = await _store.queue(deckId: deckId, now: now);
    return StudySession(
      schedulerFor: (String id) => cache.putIfAbsent(
        id,
        () => FsrsScheduler((q.settings[id] ?? DeckSettings.defaults).toFsrsConfig()),
      ),
      newCards: q.newCards,
      reviewCards: q.review,
      learningCards: q.learning,
      now: now,
    );
  }

  @override
  Future<String> recordAnswer(AnswerOutcome outcome, {required int durationMs}) async {
    final String logId = _uuid.v4();
    await _store.recordReview(
      card: outcome.after,
      logId: logId,
      rating: outcome.rating,
      at: _now(),
      durationMs: durationMs,
    );
    return logId;
  }

  @override
  Future<void> undoAnswer(FcCard before, String logId) =>
      _store.undoReview(before: before, logId: logId);

  // ── dashboard & stats ──────────────────────────────────────────────────────

  @override
  Stream<FcDashboard> watchDashboard() => _store.watch(() async {
        final DateTime now = _now();
        final List<FcDeckSummary> decks = await _store.deckSummaries(now);
        int n = 0, l = 0, r = 0, cards = 0;
        for (final FcDeckSummary d in decks) {
          n += d.newCount;
          l += d.learningCount;
          r += d.reviewCount;
          cards += d.total;
        }
        final String today = studyDayKey(now);
        final List<DayCount> todays = await _store.dailyCounts(today);
        final Set<String> days = await _store.studiedDays();
        return FcDashboard(
          counts: StudyCounts(newCount: n, learningCount: l, reviewCount: r),
          streak: currentStreak(days, now.subtract(const Duration(hours: studyDayStartHour))),
          reviewsToday: todays.isEmpty ? 0 : todays.last.total,
          totalCards: cards,
          totalDecks: decks.length,
        );
      });

  @override
  Stream<FcStats> watchStats() => _store.watch(() async {
        final DateTime now = _now();
        final DateTime studyNow = now.subtract(const Duration(hours: studyDayStartHour));
        final String since120 = dayKey(studyNow.subtract(const Duration(days: 140)));
        final String since30 = dayKey(studyNow.subtract(const Duration(days: 29)));
        final List<DayCount> counts = await _store.dailyCounts(since120);
        final Set<String> days = await _store.studiedDays();
        final ({int total, int passed}) ret = await _store.retention(since30);
        final List<DateTime> due = await _store.reviewDueDates(now.add(const Duration(days: 40)));
        final String today = studyDayKey(now);
        return FcStats(
          streak: currentStreak(days, studyNow),
          longestStreak: longestStreak(days),
          heatmap: buildHeatmap(
            <String, int>{for (final DayCount d in counts) d.day: d.total},
            studyNow,
          ),
          breakdown: await _store.stateBreakdown(),
          forecast: buildForecast(due, now),
          retentionPercent: percent(ret.passed, ret.total),
          retentionSample: ret.total,
          last30: counts.where((DayCount d) => d.day.compareTo(since30) >= 0).toList(),
          totals: await _store.totals(),
          reviewsToday: counts.where((DayCount d) => d.day == today).fold(0, (int a, DayCount d) => a + d.total),
        );
      });

  @override
  Stream<List<FcActivity>> watchRecentActivity({int limit = 8}) =>
      _store.watch(() => _store.recentActivity(limit));

  // ── suggestions ────────────────────────────────────────────────────────────

  @override
  Future<List<String>> subjectSuggestions() => _store.subjectSuggestions();

  @override
  Future<List<String>> tagSuggestions() => _store.tagSuggestions();

  @override
  Stream<Map<String, int>> watchSubjectColors() => _store.watch(_store.subjectColors);

  // ── import & backup ────────────────────────────────────────────────────────

  @override
  Future<List<ImportCandidate>> importCandidates(ImportSource source, String query,
          {int limit = 200}) =>
      switch (source) {
        ImportSource.dictionary => _store.importFromDictionary(query, limit),
        ImportSource.vocabulary => _store.importFromVocabulary(query, limit),
        ImportSource.studyHub => _store.importFromStudyHub(query, limit),
      };

  @override
  Future<Map<String, dynamic>> exportBackup() async =>
      encodeBackup(await _store.dumpAll(), _now());

  @override
  Future<void> importBackup(Map<String, dynamic> data) =>
      _store.restoreAll(decodeBackup(data));
}

import 'dart:math' as math;

import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/fc_time.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';

/// What happened when a card was answered; the caller persists it.
class AnswerOutcome {
  const AnswerOutcome({
    required this.before,
    required this.after,
    required this.rating,
    required this.becameLeech,
  });

  final FcCard before;

  /// The card with its new FSRS state (equal to [before] in practice mode).
  final FcCard after;
  final FsrsRating rating;

  /// Crossed [FcCard.leechThreshold] with this answer.
  final bool becameLeech;
}

class _Entry {
  _Entry(this.before, this.after, this.countedAs, this.rating);
  final FcCard before;
  final FcCard after;
  final FsrsState countedAs;
  final FsrsRating rating;
}

/// The in-memory state machine of one study session. Pure: no I/O, no clock;
/// callers pass `now` and persist each [AnswerOutcome].
///
/// Order of play (like Anki):
///  1. learning/relearning cards that are due,
///  2. new and review cards, interleaved so new ones are spread out,
///  3. learning cards due within [learnAhead] (shown early rather than
///     ending the session with cards still in short-term memory).
///
/// In [practice] mode FSRS is never called: "Again" re-queues the card a few
/// positions later, any other answer retires it.
class StudySession {
  StudySession({
    required FsrsScheduler Function(String deckId) schedulerFor,
    required List<FcCard> newCards,
    required List<FcCard> reviewCards,
    List<FcCard> learningCards = const <FcCard>[],
    required DateTime now,
    this.practice = false,
    this.learnAhead = const Duration(minutes: 20),
    math.Random? random,
    this.fuzz = true,
  })  : _schedulerFor = schedulerFor,
        _random = random ?? math.Random(),
        _new = List<FcCard>.of(newCards),
        _review = List<FcCard>.of(reviewCards),
        _learning = List<FcCard>.of(learningCards) {
    _newTotal = _new.length;
    _reviewTotal = _review.length;
    _pick(now);
  }

  final FsrsScheduler Function(String deckId) _schedulerFor;
  final math.Random _random;
  final bool practice;
  final Duration learnAhead;
  final bool fuzz;

  final List<FcCard> _new;
  final List<FcCard> _review;
  final List<FcCard> _learning;
  final List<_Entry> _history = <_Entry>[];

  late final int _newTotal;
  late final int _reviewTotal;
  int _newShown = 0;
  int _reviewShown = 0;
  int _answered = 0;

  FcCard? _current;

  /// The card to show, or null when the session is over.
  FcCard? get current => _current;
  bool get isFinished => _current == null;
  int get answered => _answered;
  bool get canUndo => _history.isNotEmpty;

  /// Remaining cards by colour: new / learning / review (includes [current]).
  StudyCounts get counts {
    int n = _new.length, l = _learning.length, r = _review.length;
    final FcCard? c = _current;
    if (c != null) {
      if (c.isNew) {
        n++;
      } else if (c.isLearning) {
        l++;
      } else {
        r++;
      }
    }
    return StudyCounts(newCount: n, learningCount: l, reviewCount: r);
  }

  /// Share of the planned cards that have been answered, for the progress bar.
  double get progress {
    final int total = _answered + counts.total;
    return total == 0 ? 1 : _answered / total;
  }

  /// Interval each answer would give the current card (button labels).
  Map<FsrsRating, Duration> intervals(DateTime now) {
    final FcCard? c = _current;
    if (c == null || practice) return const <FsrsRating, Duration>{};
    return _schedulerFor(c.deckId).preview(c.fsrs, now);
  }

  /// Applies [rating] to the current card and moves on.
  AnswerOutcome answer(FsrsRating rating, DateTime now) {
    final FcCard card = _current!;
    final FsrsState countedAs = card.state;
    FcCard updated;
    bool leech = false;

    if (practice) {
      updated = card;
      if (rating == FsrsRating.again) {
        final int pos = math.min(_review.length, 4);
        _review.insert(pos, card);
      }
    } else {
      final FsrsCard next = _schedulerFor(card.deckId).review(
        card.fsrs,
        rating,
        now,
        random: fuzz ? _random : null,
      );
      final bool lapsed =
          rating == FsrsRating.again && card.state == FsrsState.review;
      final int lapses = card.lapses + (lapsed ? 1 : 0);
      leech = lapsed && lapses == FcCard.leechThreshold;
      updated = card.copyWith(
        fsrs: _snap(next),
        reps: card.reps + 1,
        lapses: lapses,
        suspended: leech ? true : null,
        updatedAt: now,
      );
      if (updated.isLearning && !leech) _learning.add(updated);
    }

    if (card.isNew) {
      _newShown++;
    } else if (!card.isLearning) {
      _reviewShown++;
    }
    _answered++;
    _history.add(_Entry(card, updated, countedAs, rating));
    final AnswerOutcome out = AnswerOutcome(
      before: card,
      after: updated,
      rating: rating,
      becameLeech: leech,
    );
    _current = null;
    _pick(now);
    return out;
  }

  /// Reverts the last answer. Returns the entry so the caller can restore the
  /// persisted state; null when there is nothing to undo.
  ({FcCard before, FcCard after})? undo(DateTime now) {
    if (_history.isEmpty) return null;
    final _Entry e = _history.removeLast();
    // Put the displayed card back where it came from.
    final FcCard? shown = _current;
    if (shown != null) _requeue(shown);
    _learning.removeWhere((FcCard c) => c.id == e.after.id);
    if (practice && e.rating == FsrsRating.again) {
      _review.removeWhere((FcCard c) => c.id == e.after.id);
    }
    if (e.before.isNew) {
      _newShown--;
    } else if (!e.before.isLearning) {
      _reviewShown--;
    }
    _answered--;
    _current = e.before;
    return (before: e.before, after: e.after);
  }

  /// Drops the current card (suspended, buried or deleted) and moves on.
  void removeCurrent(DateTime now) {
    _current = null;
    _pick(now);
  }

  /// Swaps in an edited version of the current card.
  void replaceCurrent(FcCard edited) {
    if (_current?.id == edited.id) _current = edited;
  }

  // ── internals ──────────────────────────────────────────────────────────────

  FsrsCard _snap(FsrsCard c) => c.state == FsrsState.review
      ? c.copyWith(due: studyDayStart(c.due))
      : c;

  void _requeue(FcCard c) {
    if (c.isNew) {
      _new.insert(0, c);
    } else if (c.isLearning) {
      _learning.insert(0, c);
    } else {
      _review.insert(0, c);
    }
  }

  void _pick(DateTime now) {
    // 1. Learning cards that are due.
    final FcCard? dueLearning = _earliestLearning(now, until: now);
    if (dueLearning != null) return _take(dueLearning, _learning);

    // 2. Interleave new and review cards.
    final bool haveNew = _new.isNotEmpty;
    final bool haveReview = _review.isNotEmpty;
    if (haveNew || haveReview) {
      final bool takeNew = haveNew &&
          (!haveReview || _newShown * _reviewTotal <= _reviewShown * _newTotal);
      return takeNew ? _take(_new.first, _new) : _take(_review.first, _review);
    }

    // 3. Learning cards due soon, rather than ending with them pending.
    final FcCard? early = _earliestLearning(now, until: now.add(learnAhead));
    if (early != null) return _take(early, _learning);
    _current = null;
  }

  FcCard? _earliestLearning(DateTime now, {required DateTime until}) {
    FcCard? best;
    for (final FcCard c in _learning) {
      if (c.fsrs.due.isAfter(until)) continue;
      if (best == null || c.fsrs.due.isBefore(best.fsrs.due)) best = c;
    }
    return best;
  }

  void _take(FcCard c, List<FcCard> from) {
    from.remove(c);
    _current = c;
  }
}

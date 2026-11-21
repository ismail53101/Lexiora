import 'dart:math' as math;

/// FSRS-6 spaced-repetition scheduler — a pure-Dart, dependency-free port.
///
/// The Free Spaced Repetition Scheduler is an open algorithm
/// (https://github.com/open-spaced-repetition). This port follows the
/// published FSRS-6 formulas and is verified against the reference Python
/// implementation (`py-fsrs`, MIT) through golden tests in
/// `test/modules/flashcards/fsrs/`.
///
/// Everything here is pure: no I/O, no clock, no globals. Time and randomness
/// are always passed in, which keeps it trivially unit-testable.

/// The four answer grades.
enum FsrsRating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  const FsrsRating(this.value);

  /// 1..4, as used by the FSRS formulas and stored in the review log.
  final int value;

  static FsrsRating fromValue(int v) => FsrsRating.values
      .firstWhere((FsrsRating r) => r.value == v, orElse: () => good);
}

/// Where a card is in its life-cycle. The integers are persisted.
enum FsrsState {
  /// Never reviewed. Behaves like the first learning step.
  newCard(0),
  learning(1),
  review(2),
  relearning(3);

  const FsrsState(this.value);
  final int value;

  static FsrsState fromValue(int v) => FsrsState.values
      .firstWhere((FsrsState s) => s.value == v, orElse: () => newCard);
}

/// Immutable scheduling state of one card.
class FsrsCard {
  const FsrsCard({
    this.state = FsrsState.newCard,
    this.step = 0,
    this.stability,
    this.difficulty,
    required this.due,
    this.lastReview,
  });

  /// A brand-new card, due immediately.
  factory FsrsCard.fresh(DateTime now) => FsrsCard(due: now);

  final FsrsState state;

  /// Index into the (re)learning steps; null while in [FsrsState.review].
  final int? step;

  /// Days for retrievability to fall to 90 %. Null until first reviewed.
  final double? stability;

  /// 1 (easiest) .. 10 (hardest). Null until first reviewed.
  final double? difficulty;

  final DateTime due;
  final DateTime? lastReview;

  FsrsCard copyWith({
    FsrsState? state,
    int? Function()? step,
    double? stability,
    double? difficulty,
    DateTime? due,
    DateTime? lastReview,
  }) =>
      FsrsCard(
        state: state ?? this.state,
        step: step != null ? step() : this.step,
        stability: stability ?? this.stability,
        difficulty: difficulty ?? this.difficulty,
        due: due ?? this.due,
        lastReview: lastReview ?? this.lastReview,
      );
}

/// Tunable scheduler settings.
class FsrsConfig {
  const FsrsConfig({
    this.parameters = defaultParameters,
    this.desiredRetention = 0.9,
    this.learningSteps = const <Duration>[
      Duration(minutes: 1),
      Duration(minutes: 10),
    ],
    this.relearningSteps = const <Duration>[Duration(minutes: 10)],
    this.maximumInterval = 36500,
    this.enableFuzzing = true,
  });

  /// FSRS-6 default weights (w0..w20).
  static const List<double> defaultParameters = <double>[
    0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, //
    0.1666, 0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425,
    0.0912, 0.0658, 0.1542,
  ];

  final List<double> parameters;

  /// Target probability of recall at review time (0.70 – 0.99).
  final double desiredRetention;
  final List<Duration> learningSteps;
  final List<Duration> relearningSteps;

  /// Upper bound for an interval, in days.
  final int maximumInterval;

  /// Adds a few days of random jitter to long intervals so cards learned
  /// together do not all come due on the same day.
  final bool enableFuzzing;

  FsrsConfig copyWith({
    double? desiredRetention,
    List<Duration>? learningSteps,
    List<Duration>? relearningSteps,
    int? maximumInterval,
    bool? enableFuzzing,
  }) =>
      FsrsConfig(
        parameters: parameters,
        desiredRetention: desiredRetention ?? this.desiredRetention,
        learningSteps: learningSteps ?? this.learningSteps,
        relearningSteps: relearningSteps ?? this.relearningSteps,
        maximumInterval: maximumInterval ?? this.maximumInterval,
        enableFuzzing: enableFuzzing ?? this.enableFuzzing,
      );
}

class FsrsScheduler {
  FsrsScheduler([this.config = const FsrsConfig()])
      : assert(config.parameters.length == 21, 'FSRS-6 needs 21 parameters'),
        _w = config.parameters,
        _decay = -config.parameters[20],
        _factor = math.pow(0.9, 1 / -config.parameters[20]).toDouble() - 1;

  final FsrsConfig config;
  final List<double> _w;
  final double _decay;
  final double _factor;

  static const double _stabilityMin = 0.001;
  static const double _minDifficulty = 1.0;
  static const double _maxDifficulty = 10.0;

  static const List<({double start, double end, double factor})> _fuzzRanges =
      <({double start, double end, double factor})>[
    (start: 2.5, end: 7.0, factor: 0.15),
    (start: 7.0, end: 20.0, factor: 0.1),
    (start: 20.0, end: double.infinity, factor: 0.05),
  ];

  /// Probability (0..1) that [card] is recalled at [now].
  double retrievability(FsrsCard card, DateTime now) {
    final DateTime? last = card.lastReview;
    final double? s = card.stability;
    if (last == null || s == null) return 0;
    final int elapsed = math.max(0, now.difference(last).inDays);
    return math.pow(1 + _factor * elapsed / s, _decay).toDouble();
  }

  /// Applies [rating] to [card] at [now] and returns the new state.
  ///
  /// Pass a [random] to enable fuzzing (only when [FsrsConfig.enableFuzzing]).
  FsrsCard review(
    FsrsCard card,
    FsrsRating rating,
    DateTime now, {
    math.Random? random,
  }) {
    final int? daysSince =
        card.lastReview == null ? null : now.difference(card.lastReview!).inDays;

    FsrsState state = card.state;
    int? step = card.step ?? 0;
    double newStability = 0;
    double newDifficulty = 0;
    Duration next;

    // A never-reviewed card is the first learning step.
    if (state == FsrsState.newCard) state = FsrsState.learning;

    switch (state) {
      case FsrsState.learning:
        final (double, double) mem = _updateMemory(
          stability: card.stability,
          difficulty: card.difficulty,
          rating: rating,
          daysSince: daysSince,
          card: card,
          now: now,
          allowInitial: true,
        );
        newStability = mem.$1;
        newDifficulty = mem.$2;
        (state, step, next) = _stepTransition(
          state: state,
          step: step,
          rating: rating,
          steps: config.learningSteps,
          stability: newStability,
        );
      case FsrsState.review:
        final (double, double) mem = _updateMemory(
          stability: card.stability,
          difficulty: card.difficulty,
          rating: rating,
          daysSince: daysSince,
          card: card,
          now: now,
          allowInitial: false,
        );
        newStability = mem.$1;
        newDifficulty = mem.$2;
        if (rating == FsrsRating.again && config.relearningSteps.isNotEmpty) {
          state = FsrsState.relearning;
          step = 0;
          next = config.relearningSteps[0];
        } else {
          step = null;
          next = Duration(days: _nextInterval(newStability));
        }
      case FsrsState.relearning:
        final (double, double) mem = _updateMemory(
          stability: card.stability,
          difficulty: card.difficulty,
          rating: rating,
          daysSince: daysSince,
          card: card,
          now: now,
          allowInitial: false,
        );
        newStability = mem.$1;
        newDifficulty = mem.$2;
        (state, step, next) = _stepTransition(
          state: state,
          step: step,
          rating: rating,
          steps: config.relearningSteps,
          stability: newStability,
        );
      case FsrsState.newCard:
        throw StateError('unreachable');
    }

    if (config.enableFuzzing && state == FsrsState.review && random != null) {
      next = Duration(days: _fuzzDays(next.inDays, random));
    }

    return FsrsCard(
      state: state,
      step: step,
      stability: newStability,
      difficulty: newDifficulty,
      due: now.add(next),
      lastReview: now,
    );
  }

  /// The interval each answer would produce, for the button labels.
  /// Never fuzzed, so the preview is stable between rebuilds.
  Map<FsrsRating, Duration> preview(FsrsCard card, DateTime now) =>
      <FsrsRating, Duration>{
        for (final FsrsRating r in FsrsRating.values)
          r: review(card, r, now).due.difference(now),
      };

  // ── memory model ───────────────────────────────────────────────────────────

  (double, double) _updateMemory({
    required double? stability,
    required double? difficulty,
    required FsrsRating rating,
    required int? daysSince,
    required FsrsCard card,
    required DateTime now,
    required bool allowInitial,
  }) {
    if (allowInitial && (stability == null || difficulty == null)) {
      return (_initialStability(rating), _initialDifficulty(rating, clamp: true));
    }
    final double s = stability!;
    final double d = difficulty!;
    if (daysSince != null && daysSince < 1) {
      // Same-day review: short-term stability formula.
      return (_shortTermStability(s, rating), _nextDifficulty(d, rating));
    }
    final double r = retrievability(card, now);
    return (_nextStability(d, s, r, rating), _nextDifficulty(d, rating));
  }

  (FsrsState, int?, Duration) _stepTransition({
    required FsrsState state,
    required int? step,
    required FsrsRating rating,
    required List<Duration> steps,
    required double stability,
  }) {
    Duration graduate() => Duration(days: _nextInterval(stability));
    final int s = step ?? 0;

    if (steps.isEmpty ||
        (s >= steps.length && rating != FsrsRating.again)) {
      return (FsrsState.review, null, graduate());
    }
    switch (rating) {
      case FsrsRating.again:
        return (state, 0, steps[0]);
      case FsrsRating.hard:
        if (s == 0 && steps.length == 1) {
          return (state, s, _scale(steps[0], 1.5));
        }
        if (s == 0 && steps.length >= 2) {
          return (state, s, _scale(steps[0] + steps[1], 0.5));
        }
        return (state, s, steps[s]);
      case FsrsRating.good:
        if (s + 1 == steps.length) {
          return (FsrsState.review, null, graduate());
        }
        return (state, s + 1, steps[s + 1]);
      case FsrsRating.easy:
        return (FsrsState.review, null, graduate());
    }
  }

  static Duration _scale(Duration d, double f) =>
      Duration(microseconds: (d.inMicroseconds * f).round());

  double _clampDifficulty(double d) =>
      d.clamp(_minDifficulty, _maxDifficulty).toDouble();

  double _clampStability(double s) => math.max(s, _stabilityMin);

  double _initialStability(FsrsRating r) => _clampStability(_w[r.value - 1]);

  double _initialDifficulty(FsrsRating r, {required bool clamp}) {
    final double d = _w[4] - math.exp(_w[5] * (r.value - 1)) + 1;
    return clamp ? _clampDifficulty(d) : d;
  }

  int _nextInterval(double stability) {
    final double raw = (stability / _factor) *
        (math.pow(config.desiredRetention, 1 / _decay).toDouble() - 1);
    return math.min(math.max(raw.round(), 1), config.maximumInterval);
  }

  double _shortTermStability(double s, FsrsRating r) {
    double inc =
        math.exp(_w[17] * (r.value - 3 + _w[18])) * math.pow(s, -_w[19]);
    if (r != FsrsRating.again) inc = math.max(inc, 1.0);
    return _clampStability(s * inc);
  }

  double _nextDifficulty(double d, FsrsRating r) {
    final double delta = -(_w[6] * (r.value - 3));
    final double damped = d + (10.0 - d) * delta / 9.0;
    final double easy = _initialDifficulty(FsrsRating.easy, clamp: false);
    final double reverted = _w[7] * easy + (1 - _w[7]) * damped;
    return _clampDifficulty(reverted);
  }

  double _nextStability(double d, double s, double r, FsrsRating rating) {
    final double next = rating == FsrsRating.again
        ? _forgetStability(d, s, r)
        : _recallStability(d, s, r, rating);
    return _clampStability(next);
  }

  double _forgetStability(double d, double s, double r) {
    final double longTerm = _w[11] *
        math.pow(d, -_w[12]) *
        (math.pow(s + 1, _w[13]) - 1) *
        math.exp((1 - r) * _w[14]);
    final double shortTerm = s / math.exp(_w[17] * _w[18]);
    return math.min(longTerm, shortTerm);
  }

  double _recallStability(double d, double s, double r, FsrsRating rating) {
    final double hardPenalty = rating == FsrsRating.hard ? _w[15] : 1;
    final double easyBonus = rating == FsrsRating.easy ? _w[16] : 1;
    return s *
        (1 +
            math.exp(_w[8]) *
                (11 - d) *
                math.pow(s, -_w[9]) *
                (math.exp((1 - r) * _w[10]) - 1) *
                hardPenalty *
                easyBonus);
  }

  int _fuzzDays(int days, math.Random random) {
    if (days < 2.5) return days;
    double delta = 1.0;
    for (final ({double start, double end, double factor}) f in _fuzzRanges) {
      delta += f.factor *
          math.max(math.min(days.toDouble(), f.end) - f.start, 0.0);
    }
    int minI = (days - delta).round();
    int maxI = (days + delta).round();
    minI = math.max(2, minI);
    maxI = math.min(maxI, config.maximumInterval);
    minI = math.min(minI, maxI);
    final int fuzzed = (random.nextDouble() * (maxI - minI + 1) + minI).floor();
    return math.min(fuzzed, config.maximumInterval);
  }
}

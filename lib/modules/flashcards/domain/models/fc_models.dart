import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';

/// What kind of card this is. The integers are persisted.
enum FcCardType {
  /// Front → back.
  basic(0, 'Basic'),

  /// Text with `{{c1::hidden}}` deletions.
  cloze(1, 'Cloze'),

  /// Front → you type the answer, then it is checked against the back.
  typed(2, 'Type the answer');

  const FcCardType(this.value, this.label);
  final int value;
  final String label;

  static FcCardType fromValue(int? v) => FcCardType.values.firstWhere(
        (FcCardType t) => t.value == v,
        orElse: () => FcCardType.basic,
      );
}

/// A card: its content plus its FSRS scheduling state.
class FcCard {
  const FcCard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    required this.updatedAt,
    required this.fsrs,
    this.type = FcCardType.basic,
    this.clozeIndex,
    this.subject,
    this.topic,
    this.tags = const <String>[],
    this.notes,
    this.bookmarked = false,
    this.suspended = false,
    this.buriedUntil,
    this.reps = 0,
    this.lapses = 0,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final FcCardType type;

  /// For cloze cards: the single deletion number this card tests; null = all.
  final int? clozeIndex;
  final String? subject;
  final String? topic;
  final List<String> tags;
  final String? notes;
  final bool bookmarked;
  final bool suspended;
  final DateTime? buriedUntil;
  final FsrsCard fsrs;
  final int reps;
  final int lapses;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Cards with this many lapses are auto-suspended as "leeches".
  static const int leechThreshold = 8;

  FsrsState get state => fsrs.state;
  bool get isNew => fsrs.state == FsrsState.newCard;
  bool get isLearning =>
      fsrs.state == FsrsState.learning || fsrs.state == FsrsState.relearning;
  bool get isLeech => lapses >= leechThreshold;

  /// Well-known cards have a stability of three weeks or more.
  bool get isMature => (fsrs.stability ?? 0) >= 21;

  bool isBuried(DateTime now) => buriedUntil != null && buriedUntil!.isAfter(now);

  bool isDue(DateTime now) => isNew || !fsrs.due.isAfter(now);

  FcCard copyWith({
    String? deckId,
    String? front,
    String? back,
    FcCardType? type,
    int? Function()? clozeIndex,
    String? Function()? subject,
    String? Function()? topic,
    List<String>? tags,
    String? Function()? notes,
    bool? bookmarked,
    bool? suspended,
    DateTime? Function()? buriedUntil,
    FsrsCard? fsrs,
    int? reps,
    int? lapses,
    DateTime? updatedAt,
  }) =>
      FcCard(
        id: id,
        deckId: deckId ?? this.deckId,
        front: front ?? this.front,
        back: back ?? this.back,
        type: type ?? this.type,
        clozeIndex: clozeIndex != null ? clozeIndex() : this.clozeIndex,
        subject: subject != null ? subject() : this.subject,
        topic: topic != null ? topic() : this.topic,
        tags: tags ?? this.tags,
        notes: notes != null ? notes() : this.notes,
        bookmarked: bookmarked ?? this.bookmarked,
        suspended: suspended ?? this.suspended,
        buriedUntil: buriedUntil != null ? buriedUntil() : this.buriedUntil,
        fsrs: fsrs ?? this.fsrs,
        reps: reps ?? this.reps,
        lapses: lapses ?? this.lapses,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// A deck of cards.
class FcDeck {
  const FcDeck({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.subject,
    this.topic,
    this.color,
    this.icon,
    this.archived = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? subject;
  final String? topic;
  final int? color;
  final int? icon;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  FcDeck copyWith({
    String? name,
    String? Function()? description,
    String? Function()? subject,
    String? Function()? topic,
    int? Function()? color,
    int? icon,
    bool? archived,
    DateTime? updatedAt,
  }) =>
      FcDeck(
        id: id,
        name: name ?? this.name,
        description: description != null ? description() : this.description,
        subject: subject != null ? subject() : this.subject,
        topic: topic != null ? topic() : this.topic,
        color: color != null ? color() : this.color,
        icon: icon ?? this.icon,
        archived: archived ?? this.archived,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Per-deck study options.
class DeckSettings {
  const DeckSettings({
    this.newPerDay = 20,
    this.reviewsPerDay = 200,
    this.desiredRetention = 0.9,
    this.shuffleNew = false,
  });

  final int newPerDay;
  final int reviewsPerDay;

  /// Target probability of recall (0.70 – 0.97).
  final double desiredRetention;

  /// Introduce new cards in random order instead of the order they were added.
  final bool shuffleNew;

  static const DeckSettings defaults = DeckSettings();

  FsrsConfig toFsrsConfig() => FsrsConfig(desiredRetention: desiredRetention);

  DeckSettings copyWith({
    int? newPerDay,
    int? reviewsPerDay,
    double? desiredRetention,
    bool? shuffleNew,
  }) =>
      DeckSettings(
        newPerDay: newPerDay ?? this.newPerDay,
        reviewsPerDay: reviewsPerDay ?? this.reviewsPerDay,
        desiredRetention: desiredRetention ?? this.desiredRetention,
        shuffleNew: shuffleNew ?? this.shuffleNew,
      );
}

/// A deck with live counts for the deck list.
class FcDeckSummary {
  const FcDeckSummary({
    required this.deck,
    required this.total,
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
    this.suspendedCount = 0,
  });

  final FcDeck deck;
  final int total;

  /// Cards not yet studied (before the daily limit is applied).
  final int newCount;
  final int learningCount;

  /// Review cards due now.
  final int reviewCount;
  final int suspendedCount;

  int get dueTotal => newCount + learningCount + reviewCount;
}

/// How many cards a study session would contain right now.
class StudyCounts {
  const StudyCounts({
    this.newCount = 0,
    this.learningCount = 0,
    this.reviewCount = 0,
  });

  final int newCount;
  final int learningCount;
  final int reviewCount;

  int get total => newCount + learningCount + reviewCount;
  bool get isEmpty => total == 0;

  /// Rough estimate at ~20 seconds per card.
  int get estimatedMinutes => total == 0 ? 0 : (total * 20 / 60).ceil();

  static const StudyCounts zero = StudyCounts();
}

/// Which cards a study session draws from.
enum StudyMode {
  /// Normal spaced-repetition session: only what is due (+ new, within limits).
  due('Study now'),

  /// Practice every card regardless of due date. Does not change scheduling.
  cram('Practice all'),

  /// Practice starred cards. Does not change scheduling.
  starred('Starred cards'),

  /// Practice leeches (cards you keep forgetting). Does not change scheduling.
  leeches('Leeches');

  const StudyMode(this.label);
  final String label;

  /// Modes that never touch FSRS state or the review log.
  bool get isPractice => this != StudyMode.due;
}

/// A card shown in the "recent activity" list.
class FcActivity {
  const FcActivity({
    required this.front,
    required this.deckName,
    required this.rating,
    required this.reviewedAt,
  });

  final String front;
  final String deckName;
  final FsrsRating rating;
  final DateTime reviewedAt;
}

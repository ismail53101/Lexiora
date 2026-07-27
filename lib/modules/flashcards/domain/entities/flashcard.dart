import 'package:equatable/equatable.dart';

/// Scheduling state of a card (SM-2 compatible).
enum ReviewState {
  newCard,
  learning,
  review;

  static ReviewState fromIndex(int? i) =>
      (i == null || i < 0 || i >= ReviewState.values.length)
          ? ReviewState.newCard
          : ReviewState.values[i];

  String get label => switch (this) {
        ReviewState.newCard => 'New',
        ReviewState.learning => 'Learning',
        ReviewState.review => 'Review',
      };
}

/// The four review ratings (SM-2 grade buckets).
enum CardRating {
  again,
  hard,
  good,
  easy;

  String get label => switch (this) {
        CardRating.again => 'Again',
        CardRating.hard => 'Hard',
        CardRating.good => 'Good',
        CardRating.easy => 'Easy',
      };

  bool get isCorrect => this == CardRating.good || this == CardRating.easy;
}

/// User-set difficulty label for a card.
enum CardDifficulty {
  none,
  easy,
  medium,
  hard;

  static CardDifficulty fromIndex(int? i) =>
      (i == null || i < 0 || i >= CardDifficulty.values.length)
          ? CardDifficulty.none
          : CardDifficulty.values[i];

  String get label => switch (this) {
        CardDifficulty.none => 'None',
        CardDifficulty.easy => 'Easy',
        CardDifficulty.medium => 'Medium',
        CardDifficulty.hard => 'Hard',
      };
}

/// A single flashcard. Everything is user-defined; front/back are free text
/// (rich-text/markdown ready). Scheduling fields make it SM-2 compatible.
class Flashcard extends Equatable {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    required this.updatedAt,
    this.subject,
    this.topic,
    this.tags,
    this.notes,
    this.difficulty = CardDifficulty.none,
    this.bookmarked = false,
    this.favorite = false,
    this.reviewState = ReviewState.newCard,
    this.dueAt,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.lapses = 0,
    this.lastReviewedAt,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final String? subject;
  final String? topic;
  final String? tags;
  final String? notes;
  final CardDifficulty difficulty;
  final bool bookmarked;
  final bool favorite;
  final ReviewState reviewState;
  final DateTime? dueAt;
  final int intervalDays;
  final double easeFactor;
  final int repetitions;
  final int lapses;
  final DateTime? lastReviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isNew => reviewState == ReviewState.newCard;
  bool get isDifficult => difficulty == CardDifficulty.hard;

  bool isDue(DateTime now) =>
      isNew || dueAt == null || !dueAt!.isAfter(now);

  List<String> get tagList => (tags ?? '')
      .split(',')
      .map((String t) => t.trim())
      .where((String t) => t.isNotEmpty)
      .toList();

  Flashcard copyWith({
    String? front,
    String? back,
    String? subject,
    String? topic,
    String? tags,
    String? notes,
    CardDifficulty? difficulty,
    bool? bookmarked,
    bool? favorite,
    ReviewState? reviewState,
    DateTime? dueAt,
    int? intervalDays,
    double? easeFactor,
    int? repetitions,
    int? lapses,
    DateTime? lastReviewedAt,
    DateTime? updatedAt,
    bool clearSubject = false,
    bool clearTopic = false,
    bool clearTags = false,
    bool clearNotes = false,
  }) {
    return Flashcard(
      id: id,
      deckId: deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      subject: clearSubject ? null : (subject ?? this.subject),
      topic: clearTopic ? null : (topic ?? this.topic),
      tags: clearTags ? null : (tags ?? this.tags),
      notes: clearNotes ? null : (notes ?? this.notes),
      difficulty: difficulty ?? this.difficulty,
      bookmarked: bookmarked ?? this.bookmarked,
      favorite: favorite ?? this.favorite,
      reviewState: reviewState ?? this.reviewState,
      dueAt: dueAt ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, deckId, front, back, subject, topic, tags, notes, difficulty,
        bookmarked, favorite, reviewState, dueAt, intervalDays, easeFactor,
        repetitions, lapses, lastReviewedAt, createdAt, updatedAt,
      ];
}

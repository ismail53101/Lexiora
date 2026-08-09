import 'package:equatable/equatable.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';

/// Today's review queue, split by scheduling state (the "Review Queue" card).
class ReviewQueue extends Equatable {
  const ReviewQueue({
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
  });

  final int newCount;
  final int learningCount;
  final int reviewCount;

  int get total => newCount + learningCount + reviewCount;

  /// Rough estimate at ~40 seconds per card.
  int get estimatedMinutes => total == 0 ? 0 : ((total * 40) / 60).ceil();

  static const ReviewQueue empty =
      ReviewQueue(newCount: 0, learningCount: 0, reviewCount: 0);

  @override
  List<Object?> get props => <Object?>[newCount, learningCount, reviewCount];
}

/// Aggregate flashcard statistics.
class FlashcardStats extends Equatable {
  const FlashcardStats({
    required this.totalDecks,
    required this.totalCards,
    required this.todayReviews,
    required this.completedReviews,
    required this.difficultCards,
    required this.favoriteCards,
    required this.correctReviews,
    required this.studyMinutes,
    required this.weeklyReviews,
    required this.monthlyReviews,
  });

  final int totalDecks;
  final int totalCards;
  final int todayReviews;
  final int completedReviews;
  final int difficultCards;
  final int favoriteCards;
  final int correctReviews;
  final int studyMinutes;
  final int weeklyReviews;
  final int monthlyReviews;

  int get dailyReviews => todayReviews;

  /// Percentage of reviews graded Good/Easy.
  double get averageAccuracy =>
      completedReviews == 0 ? 0 : (correctReviews / completedReviews) * 100;

  static const FlashcardStats empty = FlashcardStats(
    totalDecks: 0, totalCards: 0, todayReviews: 0, completedReviews: 0,
    difficultCards: 0, favoriteCards: 0, correctReviews: 0, studyMinutes: 0,
    weeklyReviews: 0, monthlyReviews: 0,
  );

  @override
  List<Object?> get props => <Object?>[
        totalDecks, totalCards, todayReviews, completedReviews, difficultCards,
        favoriteCards, correctReviews, studyMinutes, weeklyReviews, monthlyReviews,
      ];
}

enum CardStatusFilter {
  all,
  pending, // new or due
  completed; // reviewed at least once

  String get label => switch (this) {
        CardStatusFilter.all => 'All',
        CardStatusFilter.pending => 'Pending review',
        CardStatusFilter.completed => 'Completed',
      };
}

enum CardSort {
  recent,
  alphabetical;

  String get label => switch (this) {
        CardSort.recent => 'Recently added',
        CardSort.alphabetical => 'Alphabetical',
      };
}

/// A composable filter for browsing/searching cards. All fields combine (AND).
class FlashcardFilter extends Equatable {
  const FlashcardFilter({
    this.query = '',
    this.deckId,
    this.subject,
    this.topic,
    this.tag,
    this.onlyBookmarked = false,
    this.onlyFavorite = false,
    this.difficulty,
    this.status = CardStatusFilter.all,
    this.sort = CardSort.recent,
  });

  final String query;
  final String? deckId;
  final String? subject;
  final String? topic;
  final String? tag;
  final bool onlyBookmarked;
  final bool onlyFavorite;
  final CardDifficulty? difficulty;
  final CardStatusFilter status;
  final CardSort sort;

  FlashcardFilter copyWith({
    String? query,
    String? deckId,
    String? subject,
    String? topic,
    String? tag,
    bool? onlyBookmarked,
    bool? onlyFavorite,
    CardDifficulty? difficulty,
    CardStatusFilter? status,
    CardSort? sort,
    bool clearDeck = false,
    bool clearSubject = false,
    bool clearTopic = false,
    bool clearTag = false,
    bool clearDifficulty = false,
  }) {
    return FlashcardFilter(
      query: query ?? this.query,
      deckId: clearDeck ? null : (deckId ?? this.deckId),
      subject: clearSubject ? null : (subject ?? this.subject),
      topic: clearTopic ? null : (topic ?? this.topic),
      tag: clearTag ? null : (tag ?? this.tag),
      onlyBookmarked: onlyBookmarked ?? this.onlyBookmarked,
      onlyFavorite: onlyFavorite ?? this.onlyFavorite,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      status: status ?? this.status,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        query, deckId, subject, topic, tag, onlyBookmarked, onlyFavorite,
        difficulty, status, sort,
      ];
}

/// A recent review event for the "Recent Activity" card.
class ReviewActivity extends Equatable {
  const ReviewActivity({
    required this.cardFront,
    required this.deckName,
    required this.rating,
    required this.reviewedAt,
  });

  final String cardFront;
  final String deckName;
  final CardRating rating;
  final DateTime reviewedAt;

  @override
  List<Object?> get props => <Object?>[cardFront, deckName, rating, reviewedAt];
}

/// A candidate card sourced from another module during import.
class ImportCandidate extends Equatable {
  const ImportCandidate({
    required this.front,
    required this.back,
    this.subject,
    this.topic,
  });

  final String front;
  final String back;
  final String? subject;
  final String? topic;

  @override
  List<Object?> get props => <Object?>[front, back, subject, topic];
}

/// Modules a user can import cards from (read-only; nothing is modified there).
enum ImportSource {
  dictionary,
  vocabulary,
  studyHub;

  String get label => switch (this) {
        ImportSource.dictionary => 'Dictionary',
        ImportSource.vocabulary => 'Vocabulary',
        ImportSource.studyHub => 'Study Planner subjects & topics',
      };
}

/// Which cards a study session includes.
enum StudyMode {
  due,
  all,
  bookmarked,
  difficult,
  newOnly,
  shuffle;

  String get label => switch (this) {
        StudyMode.due => "Today's reviews",
        StudyMode.all => 'All cards',
        StudyMode.bookmarked => 'Bookmarked only',
        StudyMode.difficult => 'Difficult only',
        StudyMode.newOnly => 'New only',
        StudyMode.shuffle => 'Shuffle',
      };
}

import 'package:lexiora/modules/flashcards/domain/logic/stats_calc.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';

class DayCount {
  const DayCount(this.day, this.total, this.good);
  final String day;
  final int total;
  final int good;
}

class StateBreakdown {
  const StateBreakdown({
    this.newCards = 0,
    this.learning = 0,
    this.young = 0,
    this.mature = 0,
    this.suspended = 0,
  });
  final int newCards;
  final int learning;
  final int young;
  final int mature;
  final int suspended;
  int get total => newCards + learning + young + mature + suspended;
}

class FcTotals {
  const FcTotals({
    this.decks = 0,
    this.cards = 0,
    this.reviews = 0,
    this.studyMs = 0,
  });
  final int decks;
  final int cards;
  final int reviews;
  final int studyMs;
}

class ImportCandidate {
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
}

/// Where an import list comes from (all read-only views of other modules).
enum ImportSource {
  dictionary('Dictionary', 'Words and meanings you looked up'),
  vocabulary('Vocabulary', 'Word lists with English and Urdu meanings'),
  studyHub('Study Planner', 'Subjects and topics from your study sessions');

  const ImportSource(this.label, this.description);
  final String label;
  final String description;
}

/// What the home screen of Flashcards shows.
class FcDashboard {
  const FcDashboard({
    required this.counts,
    required this.streak,
    required this.reviewsToday,
    required this.totalCards,
    required this.totalDecks,
  });

  /// What a session would contain right now, across every active deck.
  final StudyCounts counts;
  final int streak;
  final int reviewsToday;
  final int totalCards;
  final int totalDecks;

  static const FcDashboard empty = FcDashboard(
    counts: StudyCounts.zero,
    streak: 0,
    reviewsToday: 0,
    totalCards: 0,
    totalDecks: 0,
  );
}

/// Everything on the Statistics screen.
class FcStats {
  const FcStats({
    required this.streak,
    required this.longestStreak,
    required this.heatmap,
    required this.breakdown,
    required this.forecast,
    required this.retentionPercent,
    required this.retentionSample,
    required this.last30,
    required this.totals,
    required this.reviewsToday,
  });

  final int streak;
  final int longestStreak;
  final List<List<HeatCell?>> heatmap;
  final StateBreakdown breakdown;

  /// Reviews due on each of the next days (index 0 = today, incl. overdue).
  final List<int> forecast;

  /// Share of reviews of already-seen cards answered Hard/Good/Easy (30 days).
  final double retentionPercent;
  final int retentionSample;
  final List<DayCount> last30;
  final FcTotals totals;
  final int reviewsToday;
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/flashcards/data/datasources/flashcard_local_data_source.dart';
import 'package:lexiora/modules/flashcards/data/repositories/flashcard_repository_impl.dart';
import 'package:lexiora/modules/flashcards/domain/entities/deck.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard.dart';
import 'package:lexiora/modules/flashcards/domain/entities/flashcard_models.dart';

void main() {
  late AppDatabase db;
  late FlashcardRepositoryImpl repo;
  final DateTime now = DateTime.now();
  final DateTime past = now.subtract(const Duration(days: 2));
  final DateTime future = now.add(const Duration(days: 5));

  Deck deck(String id, {String? name, String? subject, bool archived = false}) =>
      Deck(
        id: id,
        name: name ?? 'Deck $id',
        subject: subject,
        archived: archived,
        createdAt: now,
        updatedAt: now,
      );

  Flashcard card(
    String id,
    String deckId, {
    String front = 'Front',
    String back = 'Back',
    String? subject,
    String? topic,
    String? tags,
    CardDifficulty difficulty = CardDifficulty.none,
    bool bookmarked = false,
    bool favorite = false,
    ReviewState state = ReviewState.newCard,
    DateTime? dueAt,
    DateTime? createdAt,
  }) =>
      Flashcard(
        id: id,
        deckId: deckId,
        front: front,
        back: back,
        subject: subject,
        topic: topic,
        tags: tags,
        difficulty: difficulty,
        bookmarked: bookmarked,
        favorite: favorite,
        reviewState: state,
        dueAt: dueAt,
        createdAt: createdAt ?? now,
        updatedAt: createdAt ?? now,
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FlashcardRepositoryImpl(FlashcardLocalDataSource(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('deck CRUD with live card/due counts', () async {
    await repo.saveDeck(deck('d1', name: 'CSS English'));
    await repo.saveCard(card('c1', 'd1'));
    await repo.saveCard(card('c2', 'd1',
        state: ReviewState.review, dueAt: past)); // due
    await repo.saveCard(card('c3', 'd1',
        state: ReviewState.review, dueAt: future)); // not due

    final List<DeckSummary> decks = await repo.watchDecks().first;
    expect(decks.length, 1);
    expect(decks.single.deck.name, 'CSS English');
    expect(decks.single.cardCount, 3);
    // Due = the new card (c1) + the past-due review (c2), not the future one.
    expect(decks.single.dueCount, 2);

    await repo.setDeckArchived('d1', true);
    expect(await repo.watchDecks().first, isEmpty);
    expect((await repo.watchDecks(includeArchived: true).first).length, 1);
  });

  test('card search: text, subject, flags, difficulty, status, sort', () async {
    await repo.saveDeck(deck('d1'));
    await repo.saveCard(card('c1', 'd1',
        front: 'Alpha', subject: 'Physics', tags: 'mechanics', bookmarked: true,
        createdAt: now.subtract(const Duration(minutes: 3))));
    await repo.saveCard(card('c2', 'd1',
        front: 'Beta', subject: 'English', favorite: true,
        difficulty: CardDifficulty.hard,
        createdAt: now.subtract(const Duration(minutes: 2))));
    await repo.saveCard(card('c3', 'd1',
        front: 'Gamma', subject: 'Physics',
        createdAt: now.subtract(const Duration(minutes: 1))));

    Future<List<String>> ids(FlashcardFilter f) async =>
        (await repo.cards(f)).map((Flashcard c) => c.id).toList();

    expect(await ids(const FlashcardFilter(query: 'phys')),
        containsAll(<String>['c1', 'c3']));
    expect((await ids(const FlashcardFilter(query: 'phys'))).contains('c2'),
        isFalse);
    expect(await ids(const FlashcardFilter(subject: 'Physics')),
        containsAll(<String>['c1', 'c3']));
    expect(await ids(const FlashcardFilter(onlyBookmarked: true)), <String>['c1']);
    expect(await ids(const FlashcardFilter(onlyFavorite: true)), <String>['c2']);
    expect(await ids(const FlashcardFilter(difficulty: CardDifficulty.hard)),
        <String>['c2']);

    // Alphabetical sort.
    expect(await ids(const FlashcardFilter(sort: CardSort.alphabetical)),
        <String>['c1', 'c2', 'c3']);

    // Status: all new → all pending; none completed yet.
    expect((await repo.cards(
            const FlashcardFilter(status: CardStatusFilter.pending)))
        .length, 3);
    expect((await repo.cards(
            const FlashcardFilter(status: CardStatusFilter.completed)))
        .length, 0);
  });

  test('pagination returns disjoint pages', () async {
    await repo.saveDeck(deck('d1'));
    for (int i = 0; i < 55; i++) {
      await repo.saveCard(card('c$i', 'd1',
          front: 'Card $i', createdAt: now.subtract(Duration(seconds: i))));
    }
    final List<Flashcard> p1 =
        await repo.cards(const FlashcardFilter(), limit: 40);
    final List<Flashcard> p2 =
        await repo.cards(const FlashcardFilter(), limit: 40, offset: 40);
    expect(p1.length, 40);
    expect(p2.length, 15);
    final Set<String> overlap = p1.map((Flashcard c) => c.id).toSet()
      ..retainAll(p2.map((Flashcard c) => c.id).toSet());
    expect(overlap, isEmpty);
  });

  test('review queue splits new / learning / review and estimates time',
      () async {
    await repo.saveDeck(deck('d1'));
    await repo.saveCard(card('n1', 'd1')); // new
    await repo.saveCard(card('n2', 'd1')); // new
    await repo.saveCard(
        card('l1', 'd1', state: ReviewState.learning, dueAt: past));
    await repo.saveCard(card('r1', 'd1', state: ReviewState.review, dueAt: past));
    await repo.saveCard(
        card('r2', 'd1', state: ReviewState.review, dueAt: future)); // not due

    final ReviewQueue q = await repo.watchReviewQueue().first;
    expect(q.newCount, 2);
    expect(q.learningCount, 1);
    expect(q.reviewCount, 1);
    expect(q.total, 4);
    expect(q.estimatedMinutes, 3); // ceil(4 * 40 / 60)
  });

  test('recordReview reschedules the card and logs stats + activity', () async {
    await repo.saveDeck(deck('d1', name: 'Physics'));
    await repo.saveCard(card('c1', 'd1', front: 'Newton law'));

    await repo.recordReview('c1', CardRating.good, durationMs: 60000);
    final Flashcard c = (await repo.cards(const FlashcardFilter())).single;
    expect(c.reviewState, ReviewState.review);
    expect(c.repetitions, 1);
    expect(c.lastReviewedAt, isNotNull);
    expect(c.dueAt, isNotNull);

    final FlashcardStats s = await repo.watchStats().first;
    expect(s.completedReviews, 1);
    expect(s.correctReviews, 1);
    expect(s.todayReviews, 1);
    expect(s.weeklyReviews, 1);
    expect(s.monthlyReviews, 1);
    expect(s.studyMinutes, 1);
    expect(s.averageAccuracy, 100);

    final List<ReviewActivity> act = await repo.watchRecentActivity().first;
    expect(act.single.cardFront, 'Newton law');
    expect(act.single.deckName, 'Physics');
    expect(act.single.rating, CardRating.good);
  });

  test('stats: accuracy, difficult and favourite counts', () async {
    await repo.saveDeck(deck('d1'));
    await repo.saveCard(card('c1', 'd1', favorite: true));
    await repo.saveCard(card('c2', 'd1', difficulty: CardDifficulty.hard));
    await repo.saveCard(card('c3', 'd1'));

    await repo.recordReview('c3', CardRating.good);
    await repo.recordReview('c1', CardRating.again);

    final FlashcardStats s = await repo.watchStats().first;
    expect(s.totalDecks, 1);
    expect(s.totalCards, 3);
    expect(s.favoriteCards, 1);
    expect(s.difficultCards, 1);
    expect(s.completedReviews, 2);
    expect(s.correctReviews, 1);
    expect(s.averageAccuracy, 50);
  });

  test('study sessions honour their mode', () async {
    await repo.saveDeck(deck('d1'));
    await repo.saveCard(card('due', 'd1', state: ReviewState.review, dueAt: past));
    await repo.saveCard(card('newc', 'd1'));
    await repo.saveCard(card('book', 'd1', bookmarked: true,
        state: ReviewState.review, dueAt: future));
    await repo.saveCard(card('hard', 'd1', difficulty: CardDifficulty.hard,
        state: ReviewState.review, dueAt: future));

    Future<List<String>> session(StudyMode m) async =>
        (await repo.buildStudySession(mode: m))
            .map((Flashcard c) => c.id)
            .toList();

    expect(await session(StudyMode.due), containsAll(<String>['due', 'newc']));
    expect((await session(StudyMode.due)).contains('book'), isFalse);
    expect(await session(StudyMode.bookmarked), <String>['book']);
    expect(await session(StudyMode.difficult), <String>['hard']);
    expect(await session(StudyMode.newOnly), <String>['newc']);
    expect((await session(StudyMode.all)).length, 4);
  });

  test('a deck with zero due cards is still fully studyable (deck vs queue)',
      () async {
    await repo.saveDeck(deck('d1'));
    // Every card is scheduled in the future → nothing is "due".
    await repo.saveCard(card('c1', 'd1',
        state: ReviewState.review,
        dueAt: future,
        createdAt: now.subtract(const Duration(minutes: 2))));
    await repo.saveCard(card('c2', 'd1',
        state: ReviewState.review,
        dueAt: future,
        createdAt: now.subtract(const Duration(minutes: 1))));

    // The deck reports both counts: 2 total, 0 due.
    final DeckSummary s = (await repo.watchDecks().first).single;
    expect(s.cardCount, 2);
    expect(s.dueCount, 0);

    // The spaced-repetition queue is empty …
    expect(await repo.buildStudySession(deckId: 'd1', mode: StudyMode.due),
        isEmpty);
    // … but Study (the whole deck) still returns every card, first to last.
    final List<Flashcard> all =
        await repo.buildStudySession(deckId: 'd1', mode: StudyMode.all);
    expect(all.map((Flashcard c) => c.id).toList(), <String>['c1', 'c2']);
  });

  test('watchDifficultCards returns only hard cards', () async {
    await repo.saveDeck(deck('d1'));
    await repo.saveCard(card('h', 'd1', difficulty: CardDifficulty.hard));
    await repo.saveCard(card('m', 'd1', difficulty: CardDifficulty.medium));
    final List<Flashcard> hard = await repo.watchDifficultCards().first;
    expect(hard.map((Flashcard c) => c.id), <String>['h']);
  });

  test('subject & tag suggestions come from the cards themselves', () async {
    await repo.saveDeck(deck('d1'));
    await repo.saveCard(card('c1', 'd1', subject: 'Physics', tags: 'motion, force'));
    await repo.saveCard(card('c2', 'd1', subject: 'English', tags: 'grammar'));
    expect(await repo.subjectSuggestions(),
        containsAll(<String>['English', 'Physics']));
    expect(await repo.tagSuggestions(),
        containsAll(<String>['force', 'grammar', 'motion']));
  });

  test('subject colours are read (not duplicated) from Study Hub', () async {
    await db.into(db.studySubjects).insert(StudySubjectsCompanion.insert(
          id: 's1',
          name: 'Physics',
          nameLower: 'physics',
          color: 0xFF2196F3,
          createdAt: now,
          updatedAt: now,
        ));
    final Map<String, int> colors = await repo.watchSubjectColors().first;
    expect(colors['physics'], 0xFF2196F3);
  });

  test('import: manual candidates become ordinary editable cards', () async {
    await repo.saveDeck(deck('d1'));
    final int n = await repo.importCards('d1', const <ImportCandidate>[
      ImportCandidate(front: 'Salient', back: 'Prominent', subject: 'Vocab'),
      ImportCandidate(front: 'Ephemeral', back: 'Short-lived'),
    ]);
    expect(n, 2);
    final List<Flashcard> cards = await repo.cards(const FlashcardFilter());
    expect(cards.length, 2);
    expect(cards.map((Flashcard c) => c.front),
        containsAll(<String>['Salient', 'Ephemeral']));
  });

  test('import candidates are sourced read-only from Vocabulary', () async {
    await db.into(db.vocabularyWords).insert(VocabularyWordsCompanion.insert(
          id: 'l1/salient',
          listId: 'l1',
          word: 'salient',
          wordLower: 'salient',
          letter: 'S',
          urduMeaning: 'نمایاں',
          englishMeaning: 'prominent',
        ));
    final List<ImportCandidate> found =
        await repo.importCandidates(ImportSource.vocabulary, query: 'sal');
    expect(found.length, 1);
    expect(found.single.front, 'salient');
    expect(found.single.back, contains('prominent'));
  });

  test('backup round-trips decks, cards and logs', () async {
    await repo.saveDeck(deck('d1', name: 'Backup me'));
    await repo.saveCard(card('c1', 'd1', front: 'Q1'));
    await repo.saveCard(card('c2', 'd1', front: 'Q2'));
    await repo.recordReview('c1', CardRating.good);

    final Map<String, dynamic> backup = await repo.exportBackup();
    expect((backup['decks'] as List<dynamic>).length, 1);
    expect((backup['cards'] as List<dynamic>).length, 2);
    expect((backup['logs'] as List<dynamic>).length, 1);

    // Wipe everything, then restore from the backup.
    await repo.deleteDeck('d1');
    expect(await repo.cards(const FlashcardFilter()), isEmpty);

    await repo.importBackup(backup);
    expect((await repo.watchDecks().first).single.deck.name, 'Backup me');
    expect((await repo.cards(const FlashcardFilter())).length, 2);
    final FlashcardStats s = await repo.watchStats().first;
    expect(s.completedReviews, 1, reason: 'review log restored');
  });

  test('deleting a deck cascades to its cards and logs', () async {
    await repo.saveDeck(deck('d1'));
    await repo.saveCard(card('c1', 'd1'));
    await repo.recordReview('c1', CardRating.good);

    await repo.deleteDeck('d1');
    expect(await repo.cards(const FlashcardFilter()), isEmpty);
    final FlashcardStats s = await repo.watchStats().first;
    expect(s.totalDecks, 0);
    expect(s.completedReviews, 0, reason: 'logs cascade-deleted with the deck');
  });
}

import 'dart:math' as math;

import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';

/// Builds a mixed general-quiz pool from all eligible questions.
///
/// Questions are grouped only for selection, then interleaved so a category is
/// not repeated when another category is still available. Scoped quizzes do
/// not use this selector and retain their existing ordering behavior.
class MixedQuizSelector {
  MixedQuizSelector._();

  static final math.Random _random = math.Random();

  static List<QuizQuestion> select(
    List<QuizQuestion> questions, {
    required int limit,
    bool shuffle = true,
    math.Random? random,
  }) {
    if (questions.isEmpty || limit <= 0) return <QuizQuestion>[];
    if (!shuffle) return questions.take(limit).toList(growable: false);

    final math.Random rng = random ?? _random;
    final Map<String, List<QuizQuestion>> buckets = <String, List<QuizQuestion>>{};
    for (final QuizQuestion question in questions) {
      final String category = _categoryOf(question);
      (buckets[category] ??= <QuizQuestion>[]).add(question);
    }
    for (final List<QuizQuestion> bucket in buckets.values) {
      bucket.shuffle(rng);
    }

    final List<String> categories = buckets.keys.toList()..shuffle(rng);
    final List<QuizQuestion> mixed = <QuizQuestion>[];
    String? previousCategory;
    while (mixed.length < limit && categories.isNotEmpty) {
      final List<String> eligible = categories
          .where((String category) =>
              buckets[category]!.isNotEmpty && category != previousCategory)
          .toList();
      final List<String> candidates = eligible.isEmpty
          ? categories
              .where((String category) => buckets[category]!.isNotEmpty)
              .toList()
          : eligible;
      if (candidates.isEmpty) break;

      final String category = candidates[rng.nextInt(candidates.length)];
      mixed.add(buckets[category]!.removeLast());
      previousCategory = category;
    }
    return mixed;
  }

  static String _categoryOf(QuizQuestion question) {
    final String subject = question.subject?.trim() ?? '';
    if (subject.isNotEmpty) return subject.toLowerCase();
    final String topic = question.topic?.trim() ?? '';
    if (topic.isNotEmpty) return topic.toLowerCase();
    return question.type.name;
  }
}

/// Returns the category key used by the mixed-pool tests and diagnostics.
String mixedQuizCategory(QuizQuestion question) {
  final String subject = question.subject?.trim() ?? '';
  if (subject.isNotEmpty) return subject.toLowerCase();
  final String topic = question.topic?.trim() ?? '';
  if (topic.isNotEmpty) return topic.toLowerCase();
  return question.type.name;
}

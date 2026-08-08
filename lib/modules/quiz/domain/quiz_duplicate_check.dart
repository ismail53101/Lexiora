import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';

/// Why a candidate question collided with existing content.
///
/// The five cases required by the duplicate-prevention contract:
///   - [exact]: identical prompt, options and answer.
///   - [reorderedOptions]: identical stem and option *set* (same correct
///     answer), only the option order changed.
///   - [differentOptions]: identical stem but a different option set — the
///     same knowledge point re-asked with new distractors.
///   - [reworded]: the same fact/concept re-worded (high prompt-token overlap)
///     with the same correct answer.
///   - [sameConcept]: one prompt's significant tokens are largely contained in
///     the other's and the answer is identical (a paraphrase with filler).
enum DuplicateKind { none, exact, reorderedOptions, differentOptions, reworded, sameConcept }

/// The result of checking one candidate against an existing question.
class DuplicateVerdict {
  const DuplicateVerdict.unique()
      : kind = DuplicateKind.none,
        match = null,
        similarity = 0;

  const DuplicateVerdict.duplicate(this.kind, this.match, {required this.similarity})
      : assert(kind != DuplicateKind.none);

  final DuplicateKind kind;

  /// The existing question the candidate collided with (null when unique).
  final QuizQuestion? match;

  /// Prompt similarity in [0,1] (Jaccard over significant tokens).
  final double similarity;

  bool get isDuplicate => kind != DuplicateKind.none;

  /// Human-readable reason, safe to surface to a generator or admin tool.
  String get reason {
    switch (kind) {
      case DuplicateKind.none:
        return 'Unique — no collision in the question bank.';
      case DuplicateKind.exact:
        return 'Exact duplicate of an existing question.';
      case DuplicateKind.reorderedOptions:
        return 'Same question already exists (options reordered).';
      case DuplicateKind.differentOptions:
        return 'Same question already exists (different options).';
      case DuplicateKind.reworded:
        return 'Reworded duplicate — the same fact/concept already exists.';
      case DuplicateKind.sameConcept:
        return 'Same knowledge point — a paraphrased version already exists.';
    }
  }
}

/// A generated question that was rejected by [QuizDuplicateChecker], with the
/// reason and the id of the existing question it collided with.
class QuizDedupRejection {
  const QuizDedupRejection({
    required this.candidate,
    required this.kind,
    this.matchedQuestionId,
    required this.reason,
  });

  final QuizQuestion candidate;
  final DuplicateKind kind;
  final String? matchedQuestionId;
  final String reason;
}

/// The outcome of attempting to save generated questions: only questions that
/// pass the duplicate check are saved; the rest are reported as [rejected].
/// Existing rows are never modified.
class QuizDedupReport {
  const QuizDedupReport({
    required this.requested,
    required this.saved,
    required this.rejected,
  });

  final int requested;
  final List<QuizQuestion> saved;
  final List<QuizDedupRejection> rejected;

  int get savedCount => saved.length;
  int get rejectedCount => rejected.length;

  /// Uniqueness wins over quantity: the caller asked for [requested] questions
  /// but only [savedCount] were unique enough to persist.
  bool get allSaved => rejected.isEmpty;
}

/// Pure, deterministic duplicate-prevention for generated MCQs. No I/O, no
/// randomness — fully unit-testable and safe to run before every save.
///
/// A candidate is rejected when any existing question matches it as an
/// [DuplicateKind.exact], [DuplicateKind.reorderedOptions],
/// [DuplicateKind.differentOptions], [DuplicateKind.reworded] or
/// [DuplicateKind.sameConcept] duplicate. Existing content is never touched:
/// the checker only reads the corpus handed to it.
class QuizDuplicateChecker {
  const QuizDuplicateChecker();

  /// Minimum Jaccard similarity (over significant tokens) for a reworded match.
  static const double rewordedJaccard = 0.55;

  /// Minimum containment (fraction of the smaller prompt's significant tokens
  /// present in the larger) for a same-concept match.
  static const double conceptContainment = 0.7;

  static final RegExp _nonAlphaNum = RegExp(r'[^a-z0-9\s]');
  static final RegExp _spaces = RegExp(r'\s+');

  static const Set<String> _stopWords = <String>{
    'a', 'an', 'the', 'and', 'or', 'but', 'of', 'to', 'in', 'on', 'at',
    'for', 'with', 'by', 'from', 'is', 'are', 'was', 'were', 'be', 'been',
    'being', 'do', 'does', 'did', 'have', 'has', 'had', 'will', 'would',
    'can', 'could', 'should', 'may', 'might', 'shall', 'which', 'what',
    'who', 'whom', 'whose', 'when', 'where', 'why', 'how', 'that', 'this',
    'these', 'those', 'there', 'here', 'it', 'its', 'as', 'not', 'no',
    'yes', 'etc', 'one', 'two', 'islam', 'islamic',
  };

  /// Lowercases, strips punctuation and collapses whitespace for comparison.
  static String normalizePrompt(String prompt) => prompt
      .toLowerCase()
      .replaceAll(_nonAlphaNum, ' ')
      .replaceAll(_spaces, ' ')
      .trim();

  /// The meaningful words of a prompt (stop words removed) — the tokens used
  /// for reworded / same-concept similarity.
  static List<String> significantTokens(String prompt) => normalizePrompt(prompt)
      .split(' ')
      .where((String w) => w.isNotEmpty && !_stopWords.contains(w))
      .toList(growable: false);

  /// Jaccard similarity of two token lists (order-insensitive).
  static double jaccard(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final Set<String> sa = a.toSet();
    final Set<String> sb = b.toSet();
    final int inter = sa.intersection(sb).length;
    final int union = sa.union(sb).length;
    return union == 0 ? 0 : inter / union;
  }

  /// Fraction of the smaller token list that appears in the larger one.
  static double containment(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final Set<String> smaller = a.length <= b.length ? a.toSet() : b.toSet();
    final Set<String> larger = a.length <= b.length ? b.toSet() : a.toSet();
    if (smaller.isEmpty) return 0;
    final int shared = smaller.intersection(larger).length;
    return shared / smaller.length;
  }

  /// Checks [candidate] against every question in [corpus]. Returns the
  /// strongest collision found, or a [DuplicateVerdict.unique] if none.
  DuplicateVerdict check(QuizQuestion candidate, Iterable<QuizQuestion> corpus) {
    final String candPrompt = normalizePrompt(candidate.prompt);
    final List<String> candTokens = significantTokens(candidate.prompt);

    DuplicateVerdict? best;
    for (final QuizQuestion existing in corpus) {
      final DuplicateVerdict v = _compare(candidate, candPrompt, candTokens, existing);
      if (!v.isDuplicate) continue;
      if (best == null || v.similarity > best.similarity) best = v;
    }
    return best ?? const DuplicateVerdict.unique();
  }

  DuplicateVerdict _compare(
    QuizQuestion candidate,
    String candPrompt,
    List<String> candTokens,
    QuizQuestion existing,
  ) {
    final String exPrompt = normalizePrompt(existing.prompt);
    final List<String> exTokens = significantTokens(existing.prompt);

    // 1) Identical stem.
    if (exPrompt == candPrompt) {
      final List<String> candOpts = candidate.options.map(normalizePrompt).toList(growable: false);
      final List<String> exOpts = existing.options.map(normalizePrompt).toList(growable: false);
      final bool sameOrder = _listEquals(candOpts, exOpts);
      final bool sameSet = _setEquals(candOpts, exOpts);
      final bool sameAnswer = _answersMatch(candidate, existing);

      if (sameOrder && sameSet && sameAnswer) {
        return DuplicateVerdict.duplicate(DuplicateKind.exact, existing, similarity: 1);
      }
      if (sameSet && sameAnswer) {
        return DuplicateVerdict.duplicate(DuplicateKind.reorderedOptions, existing, similarity: 1);
      }
      if (sameSet || sameAnswer) {
        // Same option pool (answer re-keyed) or same correct answer (new
        // distractors): the same fact is being re-asked. Reject.
        return DuplicateVerdict.duplicate(DuplicateKind.differentOptions, existing, similarity: 1);
      }
      // Same stem but different options AND different answers. For a
      // content-bearing stem (e.g. "The Iqamah is?") the stem itself IS the
      // question — a re-ask with different answers is a contradictory
      // duplicate. For a generic instruction stem (e.g. 'Choose the correct
      // sentence:') the real content lives in the options, so questions are
      // only duplicates when their correct answers are the same/similar.
      final bool instructionStem = _isGenericInstruction(candPrompt);
      if (!instructionStem) {
        return DuplicateVerdict.duplicate(DuplicateKind.differentOptions, existing, similarity: 1);
      }
      final List<String> candAns = significantTokens(_answerText(candidate));
      final List<String> exAns = significantTokens(_answerText(existing));
      final double ansJaccard = jaccard(candAns, exAns);
      final double ansContainment = containment(candAns, exAns);
      if (ansJaccard >= rewordedJaccard || ansContainment >= conceptContainment) {
        return DuplicateVerdict.duplicate(DuplicateKind.differentOptions, existing, similarity: ansJaccard);
      }
      return const DuplicateVerdict.unique();
    }

    // 2) Different stems: reworded / same-concept matches require the same
    //    correct answer (a shared answer alone is never enough — e.g. two
    //    different landmarks can both be "in Lahore").
    if (!_answersMatch(candidate, existing)) return const DuplicateVerdict.unique();

    final double jac = jaccard(candTokens, exTokens);
    if (jac >= rewordedJaccard) {
      return DuplicateVerdict.duplicate(DuplicateKind.reworded, existing, similarity: jac);
    }
    final double cont = containment(candTokens, exTokens);
    if (cont >= conceptContainment) {
      return DuplicateVerdict.duplicate(DuplicateKind.sameConcept, existing, similarity: cont);
    }
    return const DuplicateVerdict.unique();
  }

  /// Whether two questions have the same correct answer (by value, not index).
  static bool _answersMatch(QuizQuestion a, QuizQuestion b) {
    if (a.type != b.type) return false;
    switch (a.type) {
      case QuestionType.mcqSingle:
        final int? ia = a.answerIndex;
        final int? ib = b.answerIndex;
        if (ia == null || ib == null || ia < 0 || ib < 0) return false;
        if (ia >= a.options.length || ib >= b.options.length) return false;
        return normalizePrompt(a.options[ia]) == normalizePrompt(b.options[ib]);
      case QuestionType.trueFalse:
        return a.answerBool != null && a.answerBool == b.answerBool;
      case QuestionType.fillBlank:
        final List<String> aa = a.answerTexts.map(normalizePrompt).toSet().toList();
        final List<String> ba = b.answerTexts.map(normalizePrompt).toSet().toList();
        return _setEquals(aa, ba);
      case QuestionType.matching:
      case QuestionType.multiCorrect:
        return false; // reserved types are not graded/checked yet
    }
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _setEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final Set<String> sa = a.toSet();
    final Set<String> sb = b.toSet();
    if (sa.length != sb.length) return false;
    return sa.containsAll(sb);
  }

  /// Whether a normalized stem is a generic instruction (e.g. 'Choose the
  /// correct sentence:') whose real content is carried by the options, rather
  /// than a content-bearing question in its own right.
  static bool _isGenericInstruction(String normalizedPrompt) {
    for (final String prefix in _genericInstructionStems) {
      if (normalizedPrompt.startsWith(prefix)) return true;
    }
    return false;
  }

  static const List<String> _genericInstructionStems = <String>[
    'choose the correct sentence',
    'choose the correctly punctuated sentence',
    'select the correct sentence',
    'find the correct sentence',
    'which sentence is correct',
    'which of the following sentences is correct',
    'which of the following statements is correct',
    'choose the correct form',
    'choose the correct option',
    'choose the correct answer',
    'identify the error',
    'find the error',
    'spot the error',
    'the correctly punctuated sentence is',
  ];

  /// The correct answer of a question as a plain string (normalized by callers
  /// via [significantTokens]). Used to compare generic-instruction questions
  /// by their actual content.
  static String _answerText(QuizQuestion q) {
    switch (q.type) {
      case QuestionType.mcqSingle:
        final int? i = q.answerIndex;
        if (i == null || i < 0 || i >= q.options.length) return '';
        return q.options[i];
      case QuestionType.trueFalse:
        return q.answerBool == null ? '' : (q.answerBool! ? 'true' : 'false');
      case QuestionType.fillBlank:
        return q.answerTexts.join(' ');
      case QuestionType.matching:
      case QuestionType.multiCorrect:
        return '';
    }
  }
}

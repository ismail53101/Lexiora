import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';

/// Resolves a subject's colour from the shared Study Hub colour map (read-only).
Color? subjectColorOf(String? subject, Map<String, int> colors) {
  if (subject == null || subject.trim().isEmpty) return null;
  final int? argb = colors[subject.trim().toLowerCase()];
  return argb == null ? null : Color(argb);
}

/// A titled dashboard card, consistent with the rest of Sapiora.
class QuizSectionCard extends StatelessWidget {
  const QuizSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// A small pill showing a question's type.
class QuestionTypeChip extends StatelessWidget {
  const QuestionTypeChip({super.key, required this.type});
  final QuestionType type;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(type.shortLabel,
          style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700)),
    );
  }
}

/// Semantic colour for the correct answer. Mirrors the reference app's
/// green-correct / red-wrong feedback language, inside the dark theme, so a
/// correct highlight is unmistakable on every MCQ surface.
const Color quizCorrectColor = Color(0xFF2E7D32);

/// Visual state of a single answer option card.
enum QuizOptionState {
  /// Idle — dark surface card with an empty radio button.
  normal,

  /// Picked but not yet revealed (exam/stage selection).
  selected,

  /// Revealed as the correct answer — solid green, bold white text, check.
  correct,

  /// Revealed as a picked-but-wrong answer — solid error red, bold white text.
  wrong,
}

/// The option-card state once the user has answered: the correct option turns
/// green, a picked-wrong option turns red, everything else stays neutral.
/// Pure and position-independent — the answer comes from the question data.
QuizOptionState quizOptionStateAfterAnswer({
  required bool isAnswer,
  required bool isSelected,
}) {
  if (isAnswer) return QuizOptionState.correct;
  if (isSelected) return QuizOptionState.wrong;
  return QuizOptionState.normal;
}

/// A shared answer-option card used by every MCQ surface (practice player,
/// stage player, review) so the two quiz screens stay pixel-consistent.
/// The correct/wrong states are deliberately high-contrast and unmistakable.
class QuizOptionCard extends StatelessWidget {
  const QuizOptionCard({
    super.key,
    required this.text,
    this.state = QuizOptionState.normal,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  });

  final String text;
  final QuizOptionState state;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool correct = state == QuizOptionState.correct;
    final bool wrong = state == QuizOptionState.wrong;
    final bool selected = state == QuizOptionState.selected;

    final Color bg;
    if (correct) {
      bg = quizCorrectColor;
    } else if (wrong) {
      bg = theme.colorScheme.error;
    } else if (selected) {
      bg = theme.colorScheme.secondaryContainer;
    } else {
      bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    }

    final Color iconColor = (correct || wrong)
        ? Colors.white
        : selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;
    final Color textColor =
        (correct || wrong) ? Colors.white : theme.colorScheme.onSurface;
    final bool emphasized = correct || wrong;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: Row(
              children: <Widget>[
                Icon(
                  correct
                      ? Icons.check_circle_rounded
                      : wrong
                          ? Icons.cancel_rounded
                          : selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                  size: 20,
                  color: iconColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight:
                          emphasized ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
                if (emphasized)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      correct ? 'Correct' : 'Wrong',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A shuffled MCQ option layout: the options in display order, the display
/// index of the correct answer, and the display→original index mapping so
/// grading can recover the original answer reference.
class ShuffledOptions {
  const ShuffledOptions({
    required this.options,
    required this.correctDisplayIndex,
    required this.order,
  });

  /// Options in their shuffled display order.
  final List<String> options;

  /// Display position (0-based) of the correct answer, or -1 if unknown.
  final int correctDisplayIndex;

  /// display position → original option index.
  final List<int> order;

  /// The original option index shown at [displayIndex].
  int originalIndexOf(int displayIndex) => order[displayIndex];
}

/// Shuffle a question's options together with the correct-answer reference, so
/// the correct answer lands on A/B/C/D at random (never assumed to be A) while
/// grading still works against the original index. Pure and deterministic for
/// a given [rng] — call once per question load, never per rebuild.
ShuffledOptions shuffleOptions(
    List<String> options, int? correctIndex, Random rng) {
  final List<int> order =
      List<int>.generate(options.length, (int i) => i)..shuffle(rng);
  final int displayCorrect =
      correctIndex == null ? -1 : order.indexOf(correctIndex);
  return ShuffledOptions(
    options:
        List<String>.generate(options.length, (int i) => options[order[i]]),
    correctDisplayIndex: displayCorrect,
    order: order,
  );
}

/// A prominent question container (rounded, bordered, comfortable padding,
/// centered bold text). Long questions wrap naturally — no fixed heights.
class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({super.key, required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        prompt,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';

/// An interactive multiple-choice practice question.
///
/// Self-contained (no providers) so it is trivial to reuse and to unit-test:
/// tapping an option reveals whether it was correct, highlights the right
/// answer, and shows the explanation. "Try again" resets the selection.
class PracticeQuestionCard extends StatefulWidget {
  const PracticeQuestionCard({
    super.key,
    required this.question,
    this.index,
  });

  final GrammarQuestion question;

  /// Optional 1-based number shown as "Question N".
  final int? index;

  @override
  State<PracticeQuestionCard> createState() => _PracticeQuestionCardState();
}

class _PracticeQuestionCardState extends State<PracticeQuestionCard> {
  int? _selected;

  bool get _answered => _selected != null;
  bool get _isCorrect => _selected == widget.question.answerIndex;

  void _select(int i) {
    if (_answered) return;
    setState(() => _selected = i);
  }

  void _reset() => setState(() => _selected = null);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GrammarQuestion q = widget.question;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.index != null)
            Text(
              'Question ${widget.index}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            q.question,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < q.options.length; i++)
            _OptionTile(
              label: q.options[i],
              state: _optionStateFor(i),
              onTap: () => _select(i),
            ),
          if (_answered) ...<Widget>[
            const SizedBox(height: 6),
            _ResultBanner(isCorrect: _isCorrect, explanation: q.explanation),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _OptionState _optionStateFor(int i) {
    if (!_answered) return _OptionState.idle;
    if (i == widget.question.answerIndex) return _OptionState.correct;
    if (i == _selected) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    const Color correct = Color(0xFF2E7D32); // green 800
    final Color border;
    final Color? fill;
    final IconData icon;
    final Color iconColor;
    switch (state) {
      case _OptionState.idle:
        border = scheme.outlineVariant;
        fill = null;
        icon = Icons.radio_button_unchecked;
        iconColor = scheme.onSurfaceVariant;
      case _OptionState.correct:
        border = correct;
        fill = correct.withValues(alpha: 0.12);
        icon = Icons.check_circle;
        iconColor = correct;
      case _OptionState.wrong:
        border = scheme.error;
        fill = scheme.error.withValues(alpha: 0.10);
        icon = Icons.cancel;
        iconColor = scheme.error;
      case _OptionState.dimmed:
        border = scheme.outlineVariant;
        fill = null;
        icon = Icons.radio_button_unchecked;
        iconColor = scheme.onSurfaceVariant.withValues(alpha: 0.5);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: fill ?? Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: state == _OptionState.dimmed
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
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

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.isCorrect, this.explanation});

  final bool isCorrect;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const Color correct = Color(0xFF2E7D32);
    final Color color = isCorrect ? correct : theme.colorScheme.error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                isCorrect ? Icons.check_circle : Icons.info_outline,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct' : 'Not quite',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (explanation != null && explanation!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              explanation!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

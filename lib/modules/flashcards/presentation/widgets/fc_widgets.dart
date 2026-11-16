import 'package:flutter/material.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/cloze.dart';
import 'package:lexiora/modules/flashcards/domain/logic/fc_time.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';

/// The three colours of the study counters (like Anki: new / learning /
/// review), taken from the current theme.
extension FcColors on ColorScheme {
  Color get fcNew => primary;
  Color get fcLearning => tertiary;
  Color get fcReview => secondary;
}

/// Preset deck colours (ARGB).
const List<int> kDeckPalette = <int>[
  0xFF1E88E5, 0xFF00897B, 0xFF43A047, 0xFFF9A825, 0xFFEF6C00, 0xFFE53935,
  0xFFD81B60, 0xFF8E24AA, 0xFF5E35B1, 0xFF546E7A,
];

/// Deck colour: its own, else its subject's Study Planner colour, else primary.
Color fcDeckColor(FcDeck deck, Map<String, int> subjectColors, ColorScheme cs) {
  if (deck.color != null) return Color(deck.color!);
  final int? s = subjectColors[(deck.subject ?? '').toLowerCase()];
  return s != null ? Color(s) : cs.primary;
}

/// Right-to-left for Arabic-script text (Urdu, Arabic, Persian), else null.
TextDirection? detectTextDirection(String text) {
  for (final int r in text.runes) {
    if ((r >= 0x0600 && r <= 0x06FF) || (r >= 0x0750 && r <= 0x077F) ||
        (r >= 0xFB50 && r <= 0xFDFF) || (r >= 0xFE70 && r <= 0xFEFF)) {
      return TextDirection.rtl;
    }
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) {
      return TextDirection.ltr;
    }
  }
  return null;
}

/// A rounded card with an optional title row.
class FcSectionCard extends StatelessWidget {
  const FcSectionCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.trailing,
    this.margin = const EdgeInsets.fromLTRB(16, 6, 16, 6),
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: margin,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (title != null) ...<Widget>[
              Row(
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(title!,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// "12 New" style counter pill.
class FcCountChip extends StatelessWidget {
  const FcCountChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.dense = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: dense ? 3 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: value == 0 ? 0.08 : 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('$value',
              style: (dense ? theme.textTheme.labelMedium : theme.textTheme.titleSmall)
                  ?.copyWith(
                      color: value == 0 ? color.withValues(alpha: 0.5) : color,
                      fontWeight: FontWeight.w800)),
          const SizedBox(width: 5),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// A coloured dot (and optional label) for a card's learning state.
class FcStateBadge extends StatelessWidget {
  const FcStateBadge({super.key, required this.card});
  final FcCard card;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final (Color color, String label) = card.suspended
        ? (cs.outline, 'Suspended')
        : switch (card.state) {
            FsrsState.newCard => (cs.fcNew, 'New'),
            FsrsState.learning || FsrsState.relearning => (cs.fcLearning, 'Learning'),
            FsrsState.review => (cs.fcReview, card.isMature ? 'Mature' : 'Young'),
          };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

/// Which face of a card to draw.
enum FcFace { question, answer }

/// Draws one face of a card: plain text, or a cloze with blanks / highlights.
class FcCardFaceText extends StatelessWidget {
  const FcCardFaceText({
    super.key,
    required this.card,
    required this.face,
    this.fontSize = 24,
    this.textAlign = TextAlign.center,
  });

  final FcCard card;
  final FcFace face;
  final double fontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base = theme.textTheme.headlineSmall!.copyWith(
      fontSize: fontSize,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface,
    );

    if (card.type == FcCardType.cloze) {
      final bool revealed = face == FcFace.answer;
      final List<ClozeSegment> segs =
          renderCloze(card.front, activeIndex: card.clozeIndex, revealed: revealed);
      final Widget rich = Text.rich(
        TextSpan(
          style: base,
          children: <InlineSpan>[
            for (final ClozeSegment s in segs)
              TextSpan(
                text: s.text,
                style: (s.isBlank || s.isAnswer)
                    ? TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                      )
                    : null,
              ),
          ],
        ),
        textAlign: textAlign,
        textDirection: detectTextDirection(clozePlainText(card.front)),
      );
      final String extra = card.back.trim();
      if (!revealed || extra.isEmpty) return rich;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          rich,
          const SizedBox(height: 16),
          Text(extra,
              textAlign: textAlign,
              style: base.copyWith(
                  fontSize: fontSize * 0.7,
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      );
    }

    final String text = face == FcFace.question ? card.front : card.back;
    return Text(
      text,
      textAlign: textAlign,
      textDirection: detectTextDirection(text),
      style: base,
    );
  }
}

/// A list row for a card: front text, back preview, state and tags.
class FcCardTile extends StatelessWidget {
  const FcCardTile({
    super.key,
    required this.card,
    this.deckName,
    this.selected = false,
    this.selectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onToggleStar,
  });

  final FcCard card;
  final String? deckName;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleStar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String front = card.type == FcCardType.cloze
        ? clozeQuestionText(card.front, activeIndex: card.clozeIndex).replaceAll('blank', '[…]')
        : card.front;
    final String back =
        card.type == FcCardType.cloze ? clozePlainText(card.front) : card.back;
    final String due = card.isNew
        ? ''
        : card.suspended
            ? ''
            : 'Due ${formatDueIn(card.fsrs.due)}';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      elevation: 0,
      color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: <Widget>[
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: selected ? cs.primary : cs.outline),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(front,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: detectTextDirection(front),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(back,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: detectTextDirection(back),
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        FcStateBadge(card: card),
                        if (card.type != FcCardType.basic)
                          Text(card.type.label,
                              style: theme.textTheme.labelSmall?.copyWith(color: cs.primary)),
                        if (due.isNotEmpty)
                          Text(due, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        if (card.isLeech)
                          Text('Leech',
                              style: theme.textTheme.labelSmall?.copyWith(color: cs.error, fontWeight: FontWeight.w700)),
                        if (deckName != null)
                          Text(deckName!, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        for (final String t in card.tags.take(3))
                          Text('#$t', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              if (onToggleStar != null)
                IconButton(
                  tooltip: card.bookmarked ? 'Remove star' : 'Star',
                  icon: Icon(card.bookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: card.bookmarked ? Colors.amber.shade700 : cs.outline),
                  onPressed: onToggleStar,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "today", "tomorrow", "in 5 d", or "3 d ago" for a due date.
String formatDueIn(DateTime due) {
  final DateTime now = DateTime.now();
  final int d = daysBetween(studyDayStart(now), studyDayStart(due));
  if (d == 0) return 'today';
  if (d == 1) return 'tomorrow';
  if (d == -1) return 'yesterday';
  if (d < 0) return '${-d}d overdue';
  if (d < 30) return 'in ${d}d';
  if (d < 365) return 'in ${(d / 30).round()}mo';
  return 'in ${(d / 365).toStringAsFixed(1)}y';
}

/// Small snackbar helper.
void fcToast(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

/// Confirmation dialog; returns true when confirmed.
Future<bool> fcConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(confirmLabel)),
      ],
    ),
  );
  return ok ?? false;
}

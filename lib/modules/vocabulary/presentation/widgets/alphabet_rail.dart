import 'package:flutter/material.dart';

/// A slim A–Z quick-jump rail shown on the right of the browse list. Present
/// letters are tappable; absent letters are dimmed. Tapping calls [onLetter].
class AlphabetRail extends StatelessWidget {
  const AlphabetRail({
    super.key,
    required this.presentLetters,
    required this.onLetter,
  });

  final Set<String> presentLetters;
  final ValueChanged<String> onLetter;

  static const List<String> _all = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final String letter in _all)
            Expanded(
              child: _RailLetter(
                letter: letter,
                enabled: presentLetters.contains(letter),
                onTap: () => onLetter(letter),
                color: scheme.primary,
                disabledColor: scheme.onSurfaceVariant.withValues(alpha: 0.35),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailLetter extends StatelessWidget {
  const _RailLetter({
    required this.letter,
    required this.enabled,
    required this.onTap,
    required this.color,
    required this.disabledColor,
  });

  final String letter;
  final bool enabled;
  final VoidCallback onTap;
  final Color color;
  final Color disabledColor;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      letter,
      style: TextStyle(
        fontSize: 11,
        height: 1,
        fontWeight: enabled ? FontWeight.w700 : FontWeight.w400,
        color: enabled ? color : disabledColor,
      ),
    );
    if (!enabled) {
      return Center(child: label);
    }
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Center(child: label),
    );
  }
}

import 'package:flutter/material.dart';

/// Floating toolbar shown while text is selected in the reader. Offers
/// multi-color highlighting, underline, note, bookmark and copy actions.
class ReaderSelectionToolbar extends StatelessWidget {
  const ReaderSelectionToolbar({
    super.key,
    required this.colors,
    required this.onHighlight,
    required this.onUnderline,
    required this.onNote,
    required this.onBookmark,
    required this.onCopy,
    required this.onDismiss,
  });

  final List<int> colors;
  final ValueChanged<int> onHighlight;
  final ValueChanged<int> onUnderline;
  final VoidCallback onNote;
  final VoidCallback onBookmark;
  final VoidCallback onCopy;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int primaryColor = colors.isNotEmpty ? colors.first : 0xFFFFF176;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(18),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final int c in colors)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => onHighlight(c),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Action(
                  icon: Icons.format_underlined,
                  label: 'Underline',
                  onTap: () => onUnderline(primaryColor),
                ),
                _Action(icon: Icons.note_add_outlined, label: 'Note', onTap: onNote),
                _Action(
                  icon: Icons.bookmark_add_outlined,
                  label: 'Bookmark',
                  onTap: onBookmark,
                ),
                _Action(icon: Icons.copy_outlined, label: 'Copy', onTap: onCopy),
                _Action(icon: Icons.close, label: 'Dismiss', onTap: onDismiss),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(icon: Icon(icon), onPressed: onTap),
    );
  }
}

import 'package:flutter/material.dart';

/// A curated palette users pick from when colour-labelling a subject. Users
/// choose freely — nothing is tied to a specific subject.
const List<int> kSubjectPalette = <int>[
  0xFF1E88E5, 0xFF43A047, 0xFFFB8C00, 0xFF8E24AA, 0xFFE53935,
  0xFF00ACC1, 0xFF3949AB, 0xFF7CB342, 0xFFF4511E, 0xFFD81B60,
  0xFF00897B, 0xFF6D4C41, 0xFF546E7A, 0xFFC0CA33, 0xFF5E35B1,
  0xFFFDD835, 0xFFEC407A, 0xFF26A69A,
];

/// Shows a palette dialog; returns the chosen ARGB colour, or null if cancelled.
Future<int?> showSubjectColorPicker(BuildContext context, {int? current}) {
  return showDialog<int>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Choose a colour'),
      content: SizedBox(
        width: 320,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            for (final int c in kSubjectPalette)
              InkWell(
                onTap: () => Navigator.of(context).pop(c),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: current == c
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3)
                        : null,
                  ),
                  child: current == c
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
      ],
    ),
  );
}

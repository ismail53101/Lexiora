import 'package:flutter/material.dart';

/// Shows the dictionary data attribution required by its CC BY-SA 4.0 license.
Future<void> showDictionaryAttribution(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('About this dictionary'),
      content: const Text(
        'Offline dictionary data is provided by the Wordset Dictionary '
        '(wordset.org), with portions derived from Princeton WordNet 3.0.\n\n'
        'The data is licensed under the Creative Commons '
        'Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0). '
        'Sapiora redistributes it unmodified in structure under the same '
        'license. The application code itself is MIT-licensed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

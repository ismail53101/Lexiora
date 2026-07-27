import 'package:flutter/material.dart';

/// A curated registry of subject/topic icons.
///
/// Subjects & topics store an integer *index* into this list (not a raw code
/// point), so the app renders only these const [IconData]s — release icon
/// tree-shaking stays intact (no dynamic `IconData(codePoint)` construction).
/// The Admin CMS icon picker offers exactly these choices.
const List<IconData> kQuizIcons = <IconData>[
  Icons.quiz_outlined, // 0 — default
  Icons.flag_outlined, // 1
  Icons.menu_book_outlined, // 2
  Icons.mosque_outlined, // 3
  Icons.science_outlined, // 4
  Icons.public, // 5
  Icons.account_balance_outlined, // 6
  Icons.gavel, // 7
  Icons.calculate_outlined, // 8
  Icons.history_edu_outlined, // 9
  Icons.language, // 10
  Icons.groups_outlined, // 11
  Icons.psychology_outlined, // 12
  Icons.biotech_outlined, // 13
  Icons.local_police_outlined, // 14
  Icons.travel_explore, // 15
  Icons.lightbulb_outline, // 16
  Icons.map_outlined, // 17
];

/// Resolves a stored icon index to a const [IconData], with a safe fallback.
IconData quizIcon(int? index) =>
    (index != null && index >= 0 && index < kQuizIcons.length)
        ? kQuizIcons[index]
        : Icons.quiz_outlined;

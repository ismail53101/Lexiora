import 'package:lexiora/features/home/domain/entities/latest_update.dart';

/// Temporary local content for the Home dashboard.
/// Replace this list with a repository later without changing the card UI.
const List<LatestUpdate> mockLatestUpdates = <LatestUpdate>[
  LatestUpdate(
    headline: 'New learning tools are ready for your next study session',
    source: 'Sapiora Editorial',
    category: 'Education',
    relativeTime: '2h ago',
  ),
  LatestUpdate(
    headline: 'Build a stronger vocabulary with short daily revision',
    source: 'Sapiora Editorial',
    category: 'Vocabulary',
    relativeTime: '5h ago',
  ),
  LatestUpdate(
    headline: 'Make current affairs practice part of your daily routine',
    source: 'Sapiora Editorial',
    category: 'Current Affairs',
    relativeTime: 'Yesterday',
  ),
];

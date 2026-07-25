import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lexiora/app/di/module_registry.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';

/// Enforces the navigation rule (v0.6.3): every feature appears exactly once.
///
/// Home hosts all modules — Dictionary, Grammar, Vocabulary, Library (active)
/// plus Flashcards, Quiz, AI Assistant and Cloud Sync (marked "Coming Soon").
/// The Vocabulary module hosts none of the coming-soon tiles (its Coming Soon
/// widget was removed), so nothing is duplicated between Home and Vocabulary.
void main() {
  test('Home hosts all modules once; Vocabulary hosts no coming-soon tiles', () {
    final GetIt gi = GetIt.asNewInstance();
    final List<HomeDestination> tiles = <HomeDestination>[];
    for (final FeatureModule m in appModules) {
      tiles.addAll(m.homeDestinations(gi));
    }
    final Map<String, HomeDestination> byId = <String, HomeDestination>{
      for (final HomeDestination d in tiles) d.id: d,
    };

    // Active modules present on Home and NOT coming-soon.
    for (final String id in <String>[
      'dictionary',
      'grammar',
      'vocabulary',
      'library',
    ]) {
      expect(byId.containsKey(id), isTrue, reason: '"$id" must be a Home tile');
      expect(byId[id]!.comingSoon, isFalse, reason: '"$id" is active');
    }

    // Cross-cutting future features live on Home, marked coming-soon.
    for (final String id in <String>[
      'flashcards',
      'quiz',
      'ai_assistant',
      'cloud_sync',
    ]) {
      expect(byId.containsKey(id), isTrue, reason: '"$id" must be a Home tile');
      expect(byId[id]!.comingSoon, isTrue,
          reason: '"$id" must be marked Coming Soon');
    }

    // No id appears more than once across all modules' Home destinations.
    expect(byId.length, tiles.length, reason: 'no duplicate Home tiles');

    // The Vocabulary Coming Soon widget was removed — those tiles no longer
    // appear inside Vocabulary, so navigation is not duplicated.
    expect(
      File('lib/modules/vocabulary/presentation/widgets/coming_soon_tile.dart')
          .existsSync(),
      isFalse,
      reason: 'Coming Soon tiles must be removed from the Vocabulary module',
    );
  });
}

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';

/// PLACEHOLDER MODULE — Phase 1 scaffold only; no behavior is implemented.
/// See docs/FUTURE_INTEGRATION_GUIDE.md.
class FlashcardsModule extends FeatureModule {
  @override
  String get id => 'flashcards';

  @override
  String get name => 'Flashcards';

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'flashcards',
          label: 'Flashcards',
          subtitle: 'Spaced repetition',
          icon: Icons.view_carousel_outlined,
          routePath: '',
          comingSoon: true,
          order: 14,
        ),
      ];
}

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';

/// PLACEHOLDER MODULE — Phase 1 scaffold only; no behavior is implemented.
/// See docs/FUTURE_INTEGRATION_GUIDE.md.
class VocabularyModule extends FeatureModule {
  @override
  String get id => 'vocabulary';

  @override
  String get name => 'Vocabulary Builder';

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'vocabulary',
          label: 'Vocabulary',
          subtitle: 'Build word lists',
          icon: Icons.style_outlined,
          routePath: '',
          comingSoon: true,
          order: 13,
        ),
      ];
}

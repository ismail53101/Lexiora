import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';

/// PLACEHOLDER MODULE — Phase 1 scaffold only; no behavior is implemented.
/// See docs/FUTURE_INTEGRATION_GUIDE.md.
class GrammarModule extends FeatureModule {
  @override
  String get id => 'grammar';

  @override
  String get name => 'Grammar';

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'grammar',
          label: 'Grammar',
          subtitle: 'Rules & checks',
          icon: Icons.spellcheck,
          routePath: '',
          comingSoon: true,
          order: 12,
        ),
      ];
}

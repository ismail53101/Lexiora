import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';

/// PLACEHOLDER MODULE — Phase 1 scaffold only; no behavior is implemented.
///
/// This proves the modular architecture: the module already plugs into DI,
/// routing and the Home dashboard through [FeatureModule]. A future phase will
/// fill in [registerDependencies]/[routes] (and wire a [WordAction]) without
/// touching any existing code. See docs/FUTURE_INTEGRATION_GUIDE.md.
class DictionaryModule extends FeatureModule {
  @override
  String get id => 'dictionary';

  @override
  String get name => 'Dictionary';

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'dictionary',
          label: 'Dictionary',
          subtitle: 'Look up words',
          icon: Icons.menu_book_outlined,
          routePath: '',
          comingSoon: true,
          order: 10,
        ),
      ];
}

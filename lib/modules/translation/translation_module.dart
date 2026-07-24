import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';

/// PLACEHOLDER MODULE — Phase 1 scaffold only; no behavior is implemented.
/// See docs/FUTURE_INTEGRATION_GUIDE.md.
class TranslationModule extends FeatureModule {
  @override
  String get id => 'translation';

  @override
  String get name => 'Translation';

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'translation',
          label: 'Translation',
          subtitle: 'Multi-language',
          icon: Icons.translate,
          routePath: '',
          comingSoon: true,
          order: 11,
        ),
      ];
}

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';

/// PLACEHOLDER MODULE — Phase 1 scaffold only; no behavior is implemented.
/// See docs/FUTURE_INTEGRATION_GUIDE.md.
class QuizModule extends FeatureModule {
  @override
  String get id => 'quiz';

  @override
  String get name => 'Quiz System';

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'quiz',
          label: 'Quiz',
          subtitle: 'Test yourself',
          icon: Icons.quiz_outlined,
          routePath: '',
          comingSoon: true,
          order: 15,
        ),
      ];
}

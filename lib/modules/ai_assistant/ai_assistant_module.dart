import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';

/// PLACEHOLDER MODULE — Phase 1 scaffold only; no behavior is implemented.
/// See docs/FUTURE_INTEGRATION_GUIDE.md.
class AiAssistantModule extends FeatureModule {
  @override
  String get id => 'ai_assistant';

  @override
  String get name => 'AI Assistant';

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'ai_assistant',
          label: 'AI Assistant',
          subtitle: 'Ask about your text',
          icon: Icons.smart_toy_outlined,
          routePath: '',
          comingSoon: true,
          order: 16,
        ),
      ];
}

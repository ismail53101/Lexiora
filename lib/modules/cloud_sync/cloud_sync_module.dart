import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';

/// PLACEHOLDER MODULE — Phase 1 scaffold only; no behavior is implemented.
///
/// Lexiora is offline-first; Cloud Sync will be an *optional* future module.
/// See docs/FUTURE_INTEGRATION_GUIDE.md.
class CloudSyncModule extends FeatureModule {
  @override
  String get id => 'cloud_sync';

  @override
  String get name => 'Cloud Sync';

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'cloud_sync',
          label: 'Cloud Sync',
          subtitle: 'Optional backup',
          icon: Icons.cloud_sync_outlined,
          routePath: '',
          comingSoon: true,
          order: 18,
        ),
      ];
}

import 'package:flutter/widgets.dart';

/// A tile a feature/module contributes to the Home dashboard's "Explore"
/// section.
///
/// This is what lets future modules (Dictionary, Flashcards, Quiz, ...) appear
/// on the Home screen *without Home importing them*: each module returns its
/// [HomeDestination]s from [FeatureModule.homeDestinations], and Home simply
/// renders whatever the registry collected.
@immutable
class HomeDestination {
  const HomeDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.routePath,
    this.subtitle,
    this.imageAsset,
    this.enabled = true,
    this.comingSoon = false,
    this.order = 100,
  });

  /// Stable id, e.g. `library`, `dictionary`.
  final String id;
  final String label;
  final String? subtitle;

  /// Optional page-specific artwork shown inside the Home Explore tile.
  final String? imageAsset;

  final IconData icon;

  /// Route this tile navigates to when tapped.
  final String routePath;

  /// When false the tile is hidden entirely.
  final bool enabled;

  /// When true the tile is shown but marked as an upcoming feature and does not
  /// navigate. Future modules use this to advertise themselves pre-launch.
  final bool comingSoon;

  /// Sort order within the section; lower comes first.
  final int order;
}

/// Immutable collection of the [HomeDestination]s contributed by all modules.
///
/// Built once during bootstrap (by aggregating [FeatureModule.homeDestinations])
/// and registered as a singleton, so the Home screen renders module entries
/// without importing any module.
class HomeDestinationRegistry {
  const HomeDestinationRegistry(this.destinations);

  final List<HomeDestination> destinations;
}

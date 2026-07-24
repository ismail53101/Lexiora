import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/core/navigation/home_destination.dart';

/// The single extension point that makes Lexiora modular.
///
/// Every feature — and every *future* module (Dictionary, Translation, Grammar,
/// Vocabulary, Flashcards, Quiz, Admin, AI Assistant, Cloud Sync) — implements
/// [FeatureModule]. At startup the bootstrap:
///
///   1. calls [registerDependencies] so the module wires its own services into
///      GetIt;
///   2. collects [routes] into the app's single GoRouter; and
///   3. collects [homeDestinations] so the module can surface an entry on Home.
///
/// All three steps are *purely additive*. Adding a module never requires
/// editing existing modules, the router, or the injector — you implement this
/// interface and append the module to the registry list. That is the
/// Open/Closed Principle expressed structurally.
abstract class FeatureModule {
  /// Stable identifier, e.g. `reader`, `dictionary`.
  String get id;

  /// Human-readable module name (used in diagnostics / admin tooling).
  String get name;

  /// Register the module's dependencies into [getIt].
  ///
  /// Called once during bootstrap. Implementations must be idempotent and must
  /// not eagerly resolve *other* modules' dependencies, so registration order
  /// never matters.
  void registerDependencies(GetIt getIt);

  /// Routes contributed by this module, merged into the root router.
  List<RouteBase> routes(GetIt getIt) => const <RouteBase>[];

  /// Optional Home dashboard entries contributed by this module.
  List<HomeDestination> homeDestinations(GetIt getIt) =>
      const <HomeDestination>[];
}

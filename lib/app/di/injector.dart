import 'package:get_it/get_it.dart';

/// The global service locator instance.
///
/// Registration is performed in `configureDependencies` (see
/// `injector_config.dart`), which wires core singletons and then delegates to
/// each [FeatureModule] so features register their own dependencies. Everything
/// resolves through this single instance.
final GetIt sl = GetIt.instance;

import 'package:get_it/get_it.dart';
import 'package:lexiora/core/module/feature_module.dart';

/// PLACEHOLDER MODULE — Phase 1 scaffold only; no behavior is implemented.
///
/// The Admin Panel is an internal/back-office module, so it contributes no
/// Home tile. It still plugs into the same [FeatureModule] contract and will
/// gain DI + routes in a future phase. See docs/FUTURE_INTEGRATION_GUIDE.md.
class AdminModule extends FeatureModule {
  @override
  String get id => 'admin';

  @override
  String get name => 'Admin Panel';

  @override
  void registerDependencies(GetIt getIt) {}
}

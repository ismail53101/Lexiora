import 'package:go_router/go_router.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/app/di/module_registry.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/module/feature_module.dart';

/// Builds the app's single [GoRouter] by aggregating the routes every module
/// contributes. Adding a screen is additive: a module returns another
/// [GoRoute]; this function never changes.
GoRouter createAppRouter() {
  final List<RouteBase> routes = <RouteBase>[];
  for (final FeatureModule module in appModules) {
    routes.addAll(module.routes(sl));
  }
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: routes,
  );
}

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/features/home/presentation/pages/home_page.dart';

/// Wires the Home dashboard and owns the root `/` route.
class HomeModule extends FeatureModule {
  @override
  String get id => 'home';

  @override
  String get name => 'Home';

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const HomePage(),
        ),
      ];
}

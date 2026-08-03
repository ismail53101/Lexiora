import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/features/profile/presentation/pages/profile_page.dart';

/// Wires the Profile tab — a personal snapshot over local library stats,
/// plus quick links to Settings. No account system, so no DI needed here.
class ProfileModule extends FeatureModule {
  @override
  String get id => 'profile';

  @override
  String get name => 'Profile';

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const ProfilePage(),
        ),
      ];
}

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/modules/admin/presentation/pages/admin_panel_page.dart';

/// The Admin Panel is an internal/back-office module, so it contributes no
/// Home tile — it's reached from Settings instead. PDFs added through it are
/// filed under the "Admin" library category (reusing the existing document
/// pipeline); links and notes are stored via [AdminContentService].
class AdminModule extends FeatureModule {
  @override
  String get id => 'admin';

  @override
  String get name => 'Admin Panel';

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.admin,
          builder: (_, _) => const AdminPanelPage(),
        ),
      ];
}

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/modules/kids/presentation/pages/kids_home_page.dart';

/// Phase v0.11.0 — Kids Zone: a self-contained "English for Kids" learning
/// experience (ABC, numbers, colors, animals, stories, quizzes, progress),
/// aimed at young children rather than the competitive/exam-focused audience
/// the rest of Sapiora serves.
///
/// As a [FeatureModule] it registers its own dependencies, contributes its own
/// `/kids/*` routes, and adds a single, visually distinct Home tile — nothing
/// in any other module is touched to add it. This file is deliberately just
/// the skeleton (routing + DI wiring + landing page): ABC Learning, Numbers,
/// Stories, Quiz and Progress each arrive as their own follow-up files, wired
/// in here as they're built, the same way [FlashcardsModule] and
/// [QuizModule] grew over several phases.
class KidsModule extends FeatureModule {
  @override
  String get id => 'kids';

  @override
  String get name => 'Kids Zone';

  @override
  void registerDependencies(GetIt getIt) {
    // No services yet — the landing page is static. Data sources (JSON
    // lesson repositories), the progress store and the TTS service are
    // registered here as each is built in a follow-up file.
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.kids,
          builder: (_, _) => const KidsHomePage(),
        ),
      ];

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const <HomeDestination>[
        HomeDestination(
          id: 'kids',
          label: 'Kids Zone',
          subtitle: 'Fun English for young learners',
          icon: Icons.auto_awesome_outlined,
          routePath: AppRoutes.kids,
          order: 5,
        ),
      ];
}

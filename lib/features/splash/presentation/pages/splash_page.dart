import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/constants/app_constants.dart';

/// The first screen shown on launch: a short, branded entrance animation for
/// the Sapiora logo, then an automatic hand-off to Home.
///
/// By the time this screen appears, [main]'s `await configureDependencies()`
/// etc. have already completed — there's no async work happening here, this
/// is purely a timed brand moment. It navigates with [GoRouter.go] (not
/// `push`), so it's replaced in the stack rather than sitting behind Home —
/// the back button never returns to it.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const Duration _holdDuration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(_holdDuration, () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120E3D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/branding/app_icon.png',
                width: 128,
                height: 128,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                  duration: 600.ms,
                )
                .fadeIn(duration: 400.ms)
                // A soft glow pulse behind the icon — the "premium" touch —
                // implemented as a shimmering shadow rather than a second
                // asset, so nothing new needs to be shipped.
                .then(delay: 100.ms)
                .shimmer(duration: 900.ms, color: Colors.white24),
            const SizedBox(height: 24),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
            const SizedBox(height: 6),
            Text(
              AppConstants.appTagline,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 550.ms, duration: 500.ms),
            const SizedBox(height: 28),
            const Text(
              'Developed by Ismail Lashari & co.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 750.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

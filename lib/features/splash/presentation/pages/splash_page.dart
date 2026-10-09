import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/constants/app_constants.dart';

/// Animated DarsNexa brand entrance. The Android system splash is necessarily
/// static; this Flutter screen provides the animated branded experience.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const Duration _holdDuration = Duration(milliseconds: 3200);

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
      backgroundColor: const Color(0xFF030A31),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double logoSize = math.min(
            224,
            math.max(148, constraints.maxWidth * 0.48),
          );
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.18),
                    radius: 1.15,
                    colors: <Color>[
                      Color(0xFF102B91),
                      Color(0xFF071653),
                      Color(0xFF030824),
                    ],
                    stops: <double>[0, 0.55, 1],
                  ),
                ),
              ),
              const CustomPaint(painter: _StarFieldPainter()),
              Positioned(
                top: constraints.maxHeight * 0.16,
                left: -constraints.maxWidth * 0.18,
                right: -constraints.maxWidth * 0.18,
                child: IgnorePointer(
                  child: Container(
                    height: constraints.maxWidth * 1.12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF279BFF).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                  ).animate().fadeIn(duration: 900.ms),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: constraints.maxHeight * 0.25,
                child: const IgnorePointer(
                  child: CustomPaint(painter: _BookRaysPainter()),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 42),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(0, constraints.maxHeight - 100),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: logoSize,
                            height: logoSize,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(logoSize * 0.23),
                              border: Border.all(
                                color: const Color(0xFF3DCBFF),
                                width: 1.5,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0xFF087BFF)
                                      .withValues(alpha: 0.58),
                                  blurRadius: 42,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF7A35FF)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 70,
                                  spreadRadius: 12,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(logoSize * 0.21),
                              child: Image.asset(
                                'assets/branding/darsnexa_icon.webp',
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                              .animate(
                                onPlay: (AnimationController controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .scale(
                                begin: const Offset(0.985, 0.985),
                                end: const Offset(1.025, 1.025),
                                duration: 1500.ms,
                                curve: Curves.easeInOut,
                              )
                              .fadeIn(duration: 500.ms),
                          const SizedBox(height: 30),
                          Text(
                            AppConstants.appName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              height: 1.08,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 250.ms, duration: 650.ms)
                              .slideY(
                                begin: 0.24,
                                end: 0,
                                delay: 250.ms,
                                duration: 650.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 12),
                          Text(
                            AppConstants.appTagline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB9D5FF),
                              fontSize: 18,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w400,
                            ),
                          ).animate().fadeIn(delay: 500.ms, duration: 700.ms),
                          const SizedBox(height: 42),
                          const Text(
                            'Developed by Ismail Lashari & Co.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFA6B4E5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.25,
                            ),
                          ).animate().fadeIn(delay: 750.ms, duration: 650.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    const List<Offset> stars = <Offset>[
      Offset(0.08, 0.22),
      Offset(0.17, 0.36),
      Offset(0.25, 0.16),
      Offset(0.36, 0.27),
      Offset(0.47, 0.12),
      Offset(0.58, 0.31),
      Offset(0.73, 0.19),
      Offset(0.84, 0.35),
      Offset(0.93, 0.24),
      Offset(0.12, 0.54),
      Offset(0.24, 0.68),
      Offset(0.39, 0.58),
      Offset(0.64, 0.62),
      Offset(0.79, 0.72),
      Offset(0.9, 0.57),
      Offset(0.18, 0.83),
      Offset(0.72, 0.86),
      Offset(0.52, 0.44),
    ];
    for (int i = 0; i < stars.length; i++) {
      final Offset point = Offset(
        stars[i].dx * size.width,
        stars[i].dy * size.height,
      );
      starPaint.color = (i % 3 == 0
              ? const Color(0xFF8D75FF)
              : const Color(0xFF62D8FF))
          .withValues(alpha: i % 4 == 0 ? 0.9 : 0.55);
      canvas.drawCircle(point, i % 4 == 0 ? 1.8 : 1.1, starPaint);
    }

    final Offset flare = Offset(size.width * 0.5, size.height * 0.205);
    final Paint flarePaint = Paint()
      ..color = const Color(0xFF8DDFFF).withValues(alpha: 0.85)
      ..strokeWidth = 1.1;
    canvas.drawLine(
      Offset(flare.dx - 9, flare.dy),
      Offset(flare.dx + 9, flare.dy),
      flarePaint,
    );
    canvas.drawLine(
      Offset(flare.dx, flare.dy - 9),
      Offset(flare.dx, flare.dy + 9),
      flarePaint,
    );
    canvas.drawCircle(
      flare,
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BookRaysPainter extends CustomPainter {
  const _BookRaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset origin = Offset(size.width * 0.5, size.height * 0.92);
    final List<List<Offset>> rays = <List<Offset>>[
      <Offset>[Offset(0, size.height * 0.05), Offset(-size.width * 0.5, 0)],
      <Offset>[Offset(0, size.height * 0.05), Offset(size.width * 0.5, 0)],
      <Offset>[Offset(0, size.height * 0.05), Offset(-size.width * 0.5, -size.height * 0.36)],
      <Offset>[Offset(0, size.height * 0.05), Offset(size.width * 0.5, -size.height * 0.36)],
      <Offset>[Offset(0, size.height * 0.05), Offset(-size.width * 0.5, -size.height * 0.62)],
      <Offset>[Offset(0, size.height * 0.05), Offset(size.width * 0.5, -size.height * 0.62)],
    ];
    for (int i = 0; i < rays.length; i++) {
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i < 2 ? 2.2 : 1.2
        ..shader = LinearGradient(
          colors: <Color>[
            const Color(0xFF167DFF).withValues(alpha: 0.05),
            i.isEven ? const Color(0xFF28D7FF) : const Color(0xFF9D62FF),
            const Color(0xFF167DFF).withValues(alpha: 0.05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      final Path path = Path()
        ..moveTo(origin.dx + rays[i][0].dx, origin.dy + rays[i][0].dy)
        ..quadraticBezierTo(
          origin.dx + rays[i][1].dx * 0.3,
          origin.dy + rays[i][1].dy * 0.2,
          origin.dx + rays[i][1].dx,
          origin.dy + rays[i][1].dy,
        );
      canvas.drawPath(path, paint);
    }
    final Paint glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF4D8FFF).withValues(alpha: 0.45),
          const Color(0xFF163DAD).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: origin, radius: size.width * 0.52),
      );
    canvas.drawCircle(origin, size.width * 0.52, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

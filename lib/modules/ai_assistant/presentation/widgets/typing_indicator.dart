import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gemini-inspired loading state shown while the assistant prepares its first
/// tokens. The animation is intentionally lightweight and uses only Flutter's
/// canvas APIs, so it works offline and does not add an asset dependency.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AI Assistant is thinking',
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          final double phase = _controller.value * math.pi * 2;
          final double pulse = Curves.easeInOut.transform(
            (math.sin(phase) + 1) / 2,
          );
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 30,
                height: 30,
                child: CustomPaint(
                  painter: _SparklePainter(
                    pulse: pulse,
                    rotation: math.sin(phase) * 0.10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 124,
                height: 24,
                child: CustomPaint(
                  painter: _WavePainter(phase: phase),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.pulse, required this.rotation});

  final double pulse;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double scale = 0.88 + pulse * 0.14;
    final double radius = size.shortestSide * 0.39 * scale;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final Paint glow = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF9B72CB),
          Color(0xFF4285F4),
          Color(0xFFFF7C7C),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + pulse * 3)
      ..color = Colors.white.withValues(alpha: 0.48);
    canvas.drawPath(_sparklePath(radius), glow);

    final Paint fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF9B72CB),
          Color(0xFF4285F4),
          Color(0xFFFF7C7C),
        ],
      ).createShader(Rect.fromLTWH(-radius, -radius, radius * 2, radius * 2));
    canvas.drawPath(_sparklePath(radius), fill);

    final Paint inner = Paint()
      ..color = Colors.white.withValues(alpha: 0.62 + pulse * 0.20);
    canvas.drawPath(_sparklePath(radius * 0.38), inner);
    canvas.restore();
  }

  Path _sparklePath(double radius) {
    final Path path = Path();
    for (int i = 0; i < 8; i++) {
      final double angle = -math.pi / 2 + i * math.pi / 4;
      final double distance = i.isEven ? radius : radius * 0.23;
      final Offset point = Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.rotation != rotation;
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint base = Paint()
      ..color = const Color(0x149B72CB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final Path path = Path()..moveTo(2, size.height * 0.52);
    for (int i = 0; i <= 30; i++) {
      final double x = 2 + (size.width - 4) * i / 30;
      final double y = size.height * 0.52 +
          math.sin(phase + i * 0.42) * (2.8 + math.sin(phase) * 0.8);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, base);

    final Paint shimmer = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const <Color>[
          Color(0x009B72CB),
          Color(0x889B72CB),
          Color(0x994285F4),
          Color(0x88FF7C7C),
          Color(0x00FF7C7C),
        ],
        stops: <double>[
          0.0,
          0.25,
          0.50,
          0.75,
          1.0,
        ],
      ).createShader(
        Rect.fromLTWH(
          -size.width * 0.6 + (phase / (math.pi * 2)) * size.width * 1.2,
          0,
          size.width * 1.6,
          size.height,
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, shimmer);

    final Paint highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, highlight);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => oldDelegate.phase != phase;
}

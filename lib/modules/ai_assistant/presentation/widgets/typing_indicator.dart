import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gemini-inspired thinking visual: a colorful sparkle beside a softly
/// animated wave while the assistant prepares its first answer tokens.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ShaderMask(
            shaderCallback: (Rect bounds) => const LinearGradient(
              colors: <Color>[
                Color(0xFF35B9F5),
                Color(0xFF7865F7),
                Color(0xFFEF8ACB),
                Color(0xFFFFC46B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            height: 26,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) => CustomPaint(
                painter: _ThinkingWavePainter(_controller.value),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingWavePainter extends CustomPainter {
  const _ThinkingWavePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF5CC8F5),
          Color(0xFF9A8CF8),
          Color(0xFFE8A9D8),
        ],
      ).createShader(Offset.zero & size);

    final Path path = Path();
    for (int i = 0; i <= 90; i++) {
      final double x = size.width * i / 90;
      final double envelope = 0.55 + 0.45 * math.sin(math.pi * i / 90);
      final double y = size.height / 2 +
          math.sin((i / 90 * math.pi * 3) + progress * math.pi * 2) *
              size.height *
              0.22 *
              envelope;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ThinkingWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

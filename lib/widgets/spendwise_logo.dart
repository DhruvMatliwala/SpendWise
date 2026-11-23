import 'package:flutter/material.dart';

/// Branded SpendWise fintech wallet-and-analytics vector badge.
class SpendWiseLogo extends StatelessWidget {
  const SpendWiseLogo({
    super.key,
    this.size = 32,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(
        painter: _SpendWiseLogoPainter(),
      ),
    );
  }
}

class _SpendWiseLogoPainter extends CustomPainter {
  const _SpendWiseLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 108.0;
    canvas.scale(scale, scale);

    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 108, 108),
      const Radius.circular(26),
    );
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F172A),
          Color(0xFF312E81),
          Color(0xFF4F46E5),
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 108, 108));
    canvas.drawRRect(bgRect, bgPaint);

    final flapPaint = Paint()..color = const Color(0xFFC7D2FE);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(26, 22, 52, 22),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      ),
      flapPaint,
    );

    final cardPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 30, 72, 56),
        const Radius.circular(11),
      ),
      cardPaint,
    );

    final bar1Paint = Paint()..color = const Color(0xFF818CF8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(31, 57, 10, 17),
        const Radius.circular(3.5),
      ),
      bar1Paint,
    );

    final bar2Paint = Paint()..color = const Color(0xFF4F46E5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(49, 47, 10, 27),
        const Radius.circular(3.5),
      ),
      bar2Paint,
    );

    final bar3Paint = Paint()..color = const Color(0xFF10B981);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(67, 38, 10, 36),
        const Radius.circular(3.5),
      ),
      bar3Paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
